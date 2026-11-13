# MOD_NAME="LockStar diagnostics (test, read-only, stops the build)"

LOG_BEGIN "LockStar diagnostics"

_LD_OUT=/tmp/lockstar_diag
mkdir -p "$_LD_OUT"
: > "$_LD_OUT/versions.txt"
_LD_P() { echo "[LSDIAG] $*" | tee -a "$_LD_OUT/versions.txt"; }

cat > "$_LD_OUT/ver.py" <<'PY'
import re, sys, zipfile
try:
    data = zipfile.ZipFile(sys.argv[1]).read("AndroidManifest.xml")
except Exception as e:
    print("manifest-read-failed:", e)
    sys.exit(0)
found = set()
for m in re.finditer(rb"[0-9]+(?:\.[0-9]+){2,}", data):
    found.add(m.group().decode())
for m in re.finditer(rb"(?:[0-9]\x00)+(?:\.\x00(?:[0-9]\x00)+){2,}", data):
    found.add(m.group().decode("utf-16le"))
print(" ".join(sorted(found)))
PY

_LD_SRCS=(
    "main(S23FE):$(GET_FW_DIR main)"
    "stock(A14):$(GET_FW_DIR stock)"
    "extra(S26U):$(GET_FW_DIR extra)"
    "blobs-a17:$BLOBS_DIR/a17"
)

for _LD_E in "${_LD_SRCS[@]}"; do
    _LD_N="${_LD_E%%:*}"
    _LD_D="${_LD_E#*:}"
    _LD_P "===== $_LD_N : $_LD_D"
    while IFS= read -r _LD_A; do
        _LD_P "${_LD_A#$_LD_D/}  size=$(stat -c %s "$_LD_A")  versions: $(python3 "$_LD_OUT/ver.py" "$_LD_A")"
    done < <(find "$_LD_D" -type f \( -iname 'DressRoom*.apk' -o -iname 'ClockPack*.apk' -o -iname '*aod*.apk' -o -iname 'LockStar*.apk' \) 2>/dev/null | sort)
done

LOG_END "LockStar diagnostics done (search the log for LSDIAG)"
ERROR_EXIT "Stopping on purpose after LockStar diagnostics."