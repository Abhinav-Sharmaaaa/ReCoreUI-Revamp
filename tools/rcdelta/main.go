// rcdelta: content-defined-chunking delta tool for the ReCore OTA.
//
//   rcdelta index <image> <out.idx>              chunk an image, write its index, print its sha256
//   rcdelta diff  <old.idx> <new.img> <out.patch> write a patch that rebuilds new.img from the old image
//   rcdelta apply <old file or block device> <patch> <out file>
//   rcdelta hash  <file or block device> <size>  sha256 of the first <size> bytes
//
// Only the standard library is used, so it builds to one static binary for linux/arm64.
package main

import (
	"bufio"
	"bytes"
	"crypto/sha256"
	"encoding/binary"
	"encoding/hex"
	"errors"
	"fmt"
	"io"
	"os"
)

const (
	minSize = 32 << 10
	avgMask = (1 << 17) - 1 // about 128 KiB average chunk
	maxSize = 512 << 10
	bufSize = 16 << 20
)

var gear [256]uint64

func init() {
	x := uint64(0x9E3779B97F4A7C15)
	for i := range gear {
		x += 0x9E3779B97F4A7C15
		z := x
		z = (z ^ (z >> 30)) * 0xBF58476D1CE4E5B9
		z = (z ^ (z >> 27)) * 0x94D049BB133111EB
		gear[i] = z ^ (z >> 31)
	}
}

type chunker struct {
	r        io.Reader
	buf      []byte
	pos, end int
	eof      bool
}

func newChunker(r io.Reader) *chunker { return &chunker{r: r, buf: make([]byte, bufSize)} }

func (c *chunker) fill() error {
	if c.pos > 0 {
		copy(c.buf, c.buf[c.pos:c.end])
		c.end -= c.pos
		c.pos = 0
	}
	n, err := io.ReadFull(c.r, c.buf[c.end:])
	c.end += n
	if err == io.EOF || err == io.ErrUnexpectedEOF {
		c.eof = true
		return nil
	}
	return err
}

// next returns the next chunk; the slice is only valid until the following call.
func (c *chunker) next() ([]byte, error) {
	if c.end-c.pos < maxSize && !c.eof {
		if err := c.fill(); err != nil {
			return nil, err
		}
	}
	if c.end-c.pos == 0 {
		return nil, io.EOF
	}
	data := c.buf[c.pos:c.end]
	n := cut(data)
	c.pos += n
	return data[:n], nil
}

func cut(data []byte) int {
	n := len(data)
	if n > maxSize {
		n = maxSize
	}
	if n <= minSize {
		return n
	}
	var h uint64
	for i := minSize; i < n; i++ {
		h = (h << 1) + gear[data[i]]
		if h&avgMask == 0 {
			return i + 1
		}
	}
	return n
}

var zeros = make([]byte, maxSize)

func allZero(b []byte) bool { return bytes.Equal(b, zeros[:len(b)]) }

type entry struct {
	off uint64
	n   uint32
}

func fail(err error) {
	fmt.Fprintln(os.Stderr, "error:", err)
	os.Exit(1)
}

// ---- index ----

func cmdIndex(imgPath, outPath string) error {
	f, err := os.Open(imgPath)
	if err != nil {
		return err
	}
	defer f.Close()
	out, err := os.Create(outPath)
	if err != nil {
		return err
	}
	defer out.Close()
	w := bufio.NewWriterSize(out, 1<<20)
	var tmp [8]byte
	w.WriteString("RCI1")
	w.Write(make([]byte, 8+32+4)) // size, sha256, count: filled in below

	whole := sha256.New()
	ch := newChunker(io.TeeReader(f, whole))
	var size uint64
	var count uint32
	for {
		data, err := ch.next()
		if err == io.EOF {
			break
		}
		if err != nil {
			return err
		}
		sum := sha256.Sum256(data)
		binary.LittleEndian.PutUint32(tmp[:4], uint32(len(data)))
		w.Write(tmp[:4])
		w.Write(sum[:])
		size += uint64(len(data))
		count++
	}
	if err := w.Flush(); err != nil {
		return err
	}
	hdr := make([]byte, 8+32+4)
	binary.LittleEndian.PutUint64(hdr[0:8], size)
	copy(hdr[8:40], whole.Sum(nil))
	binary.LittleEndian.PutUint32(hdr[40:44], count)
	if _, err := out.WriteAt(hdr, 4); err != nil {
		return err
	}
	fmt.Printf("size=%d sha256=%s chunks=%d\n", size, hex.EncodeToString(whole.Sum(nil)), count)
	return nil
}

type index struct {
	size   uint64
	sha    [32]byte
	chunks map[[32]byte]entry
}

func loadIndex(path string) (*index, error) {
	f, err := os.Open(path)
	if err != nil {
		return nil, err
	}
	defer f.Close()
	r := bufio.NewReaderSize(f, 1<<20)
	hdr := make([]byte, 4+8+32+4)
	if _, err := io.ReadFull(r, hdr); err != nil {
		return nil, err
	}
	if string(hdr[:4]) != "RCI1" {
		return nil, errors.New("not an index file")
	}
	ix := &index{size: binary.LittleEndian.Uint64(hdr[4:12]), chunks: map[[32]byte]entry{}}
	copy(ix.sha[:], hdr[12:44])
	count := binary.LittleEndian.Uint32(hdr[44:48])
	var off uint64
	rec := make([]byte, 36)
	for i := uint32(0); i < count; i++ {
		if _, err := io.ReadFull(r, rec); err != nil {
			return nil, err
		}
		n := binary.LittleEndian.Uint32(rec[:4])
		var h [32]byte
		copy(h[:], rec[4:])
		if _, ok := ix.chunks[h]; !ok {
			ix.chunks[h] = entry{off, n}
		}
		off += uint64(n)
	}
	if off != ix.size {
		return nil, errors.New("index is inconsistent")
	}
	return ix, nil
}

// ---- patch ----
// header: "RCP1" oldSize(8) oldSha(32) newSize(8) newSha(32) opCount(4)
// ops: 'Z' len(4) | 'C' off(8) len(4) sha(32) | 'L' len(4) data

const patchHdr = 4 + 8 + 32 + 8 + 32 + 4

func cmdDiff(oldIdx, newImg, outPath string) error {
	ix, err := loadIndex(oldIdx)
	if err != nil {
		return err
	}
	f, err := os.Open(newImg)
	if err != nil {
		return err
	}
	defer f.Close()
	out, err := os.Create(outPath)
	if err != nil {
		return err
	}
	defer out.Close()
	w := bufio.NewWriterSize(out, 1<<20)
	w.Write(make([]byte, patchHdr))

	whole := sha256.New()
	ch := newChunker(io.TeeReader(f, whole))
	var newSize, copied, literal, zeroed uint64
	var ops uint32
	var b8 [8]byte
	var b4 [4]byte
	for {
		data, err := ch.next()
		if err == io.EOF {
			break
		}
		if err != nil {
			return err
		}
		n := uint32(len(data))
		newSize += uint64(n)
		ops++
		binary.LittleEndian.PutUint32(b4[:], n)
		if allZero(data) {
			w.WriteByte('Z')
			w.Write(b4[:])
			zeroed += uint64(n)
			continue
		}
		sum := sha256.Sum256(data)
		if e, ok := ix.chunks[sum]; ok && e.n == n {
			w.WriteByte('C')
			binary.LittleEndian.PutUint64(b8[:], e.off)
			w.Write(b8[:])
			w.Write(b4[:])
			w.Write(sum[:])
			copied += uint64(n)
			continue
		}
		w.WriteByte('L')
		w.Write(b4[:])
		w.Write(data)
		literal += uint64(n)
	}
	if err := w.Flush(); err != nil {
		return err
	}
	hdr := make([]byte, patchHdr)
	copy(hdr[0:4], "RCP1")
	binary.LittleEndian.PutUint64(hdr[4:12], ix.size)
	copy(hdr[12:44], ix.sha[:])
	binary.LittleEndian.PutUint64(hdr[44:52], newSize)
	copy(hdr[52:84], whole.Sum(nil))
	binary.LittleEndian.PutUint32(hdr[84:88], ops)
	if _, err := out.WriteAt(hdr, 0); err != nil {
		return err
	}
	st, _ := out.Stat()
	fmt.Printf("patch=%d bytes new=%d reused=%d zero=%d literal=%d\n", st.Size(), newSize, copied, zeroed, literal)
	return nil
}

func cmdApply(oldPath, patchPath, outPath string) error {
	old, err := os.Open(oldPath)
	if err != nil {
		return err
	}
	defer old.Close()
	pf, err := os.Open(patchPath)
	if err != nil {
		return err
	}
	defer pf.Close()
	r := bufio.NewReaderSize(pf, 1<<20)
	hdr := make([]byte, patchHdr)
	if _, err := io.ReadFull(r, hdr); err != nil {
		return err
	}
	if string(hdr[:4]) != "RCP1" {
		return errors.New("not a patch file")
	}
	newSize := binary.LittleEndian.Uint64(hdr[44:52])
	var wantSha [32]byte
	copy(wantSha[:], hdr[52:84])
	ops := binary.LittleEndian.Uint32(hdr[84:88])

	out, err := os.Create(outPath)
	if err != nil {
		return err
	}
	defer out.Close()
	w := bufio.NewWriterSize(out, 4<<20)
	h := sha256.New()
	buf := make([]byte, maxSize)
	var written uint64
	lastPct := -1
	var b1 [1]byte
	var b4 [4]byte
	var b8 [8]byte
	for i := uint32(0); i < ops; i++ {
		if _, err := io.ReadFull(r, b1[:]); err != nil {
			return err
		}
		switch b1[0] {
		case 'Z':
			if _, err := io.ReadFull(r, b4[:]); err != nil {
				return err
			}
			n := binary.LittleEndian.Uint32(b4[:])
			w.Write(zeros[:n])
			h.Write(zeros[:n])
			written += uint64(n)
		case 'C':
			if _, err := io.ReadFull(r, b8[:]); err != nil {
				return err
			}
			off := binary.LittleEndian.Uint64(b8[:])
			if _, err := io.ReadFull(r, b4[:]); err != nil {
				return err
			}
			n := binary.LittleEndian.Uint32(b4[:])
			var want [32]byte
			if _, err := io.ReadFull(r, want[:]); err != nil {
				return err
			}
			if n > maxSize {
				return errors.New("bad chunk length")
			}
			if _, err := old.ReadAt(buf[:n], int64(off)); err != nil {
				return fmt.Errorf("read old image at %d: %v", off, err)
			}
			if sha256.Sum256(buf[:n]) != want {
				return fmt.Errorf("installed system does not match the base build of this update (offset %d)", off)
			}
			w.Write(buf[:n])
			h.Write(buf[:n])
			written += uint64(n)
		case 'L':
			if _, err := io.ReadFull(r, b4[:]); err != nil {
				return err
			}
			n := binary.LittleEndian.Uint32(b4[:])
			if n > maxSize {
				return errors.New("bad chunk length")
			}
			if _, err := io.ReadFull(r, buf[:n]); err != nil {
				return err
			}
			w.Write(buf[:n])
			h.Write(buf[:n])
			written += uint64(n)
		default:
			return errors.New("bad patch op")
		}
		if pct := int(written * 100 / (newSize + 1)); pct != lastPct && pct%5 == 0 {
			lastPct = pct
			fmt.Printf("progress %d%%\n", pct)
		}
	}
	if err := w.Flush(); err != nil {
		return err
	}
	if written != newSize {
		return errors.New("size mismatch after applying the patch")
	}
	var got [32]byte
	copy(got[:], h.Sum(nil))
	if got != wantSha {
		return errors.New("checksum mismatch after applying the patch")
	}
	if err := out.Sync(); err != nil {
		return err
	}
	fmt.Println("ok sha256=" + hex.EncodeToString(got[:]))
	return nil
}

func cmdHash(path string, size int64) error {
	f, err := os.Open(path)
	if err != nil {
		return err
	}
	defer f.Close()
	h := sha256.New()
	if _, err := io.CopyN(h, f, size); err != nil {
		return err
	}
	fmt.Println(hex.EncodeToString(h.Sum(nil)))
	return nil
}

func main() {
	a := os.Args
	var err error
	switch {
	case len(a) == 4 && a[1] == "index":
		err = cmdIndex(a[2], a[3])
	case len(a) == 5 && a[1] == "diff":
		err = cmdDiff(a[2], a[3], a[4])
	case len(a) == 5 && a[1] == "apply":
		err = cmdApply(a[2], a[3], a[4])
	case len(a) == 4 && a[1] == "hash":
		var n int64
		_, err = fmt.Sscan(a[3], &n)
		if err == nil {
			err = cmdHash(a[2], n)
		}
	default:
		fmt.Fprintln(os.Stderr, "usage: rcdelta index|diff|apply|hash ...")
		os.Exit(2)
	}
	if err != nil {
		fail(err)
	}
}
