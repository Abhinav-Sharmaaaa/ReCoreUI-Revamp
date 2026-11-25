#!/bin/bash
# Builds the OTA files for one device and channel from a finished ROM zip.
#   make-delta.sh <rom.zip> <device> <channel> <build> <ota_repo> <changelog> <outdir>
# Writes into <outdir>: super.idx, feed.json and, when a previous build exists and the patch is small enough,
# the delta zip. Test hooks: OTA_PREV_FEED_FILE and OTA_PREV_IDX_FILE replace the downloads.
set -euo pipefail

ROM_ZIP=$(realpath "$1") DEVICE=$2 CHANNEL=$3 BUILD=$4 OTA_REPO=$5 CHANGELOG=$6
mkdir -p "$7"
OUT=$(cd "$7" && pwd)
HERE=$(cd "$(dirname "$0")" && pwd)
RCDIR="$HERE/../rcdelta"
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
LIMIT=2147483648

if [ -n "${RCDELTA_BIN:-}" ]; then
    RC="$RCDELTA_BIN"; RC_ARM="${RCDELTA_ARM_BIN:-$RCDELTA_BIN}"
else
    (cd "$RCDIR" && go build -o "$WORK/rcdelta" . && CGO_ENABLED=0 GOOS=linux GOARCH=arm64 go build -ldflags='-s -w' -o "$WORK/rcdelta-arm64" .)
    RC="$WORK/rcdelta"; RC_ARM="$WORK/rcdelta-arm64"
fi

echo "Extracting the images from $(basename "$ROM_ZIP")"
mkdir "$WORK/new"
unzip -q "$ROM_ZIP" '*.img' -d "$WORK/new"
[ -f "$WORK/new/super.img" ] || { echo "super.img is not in the ROM zip"; exit 1; }

INFO=$("$RC" index "$WORK/new/super.img" "$OUT/super.idx")
echo "$INFO"
NEW_SHA=$(sed -n 's/.*sha256=\([0-9a-f]*\).*/\1/p' <<< "$INFO")
NEW_SIZE=$(sed -n 's/^size=\([0-9]*\).*/\1/p' <<< "$INFO")

IMAGES_JSON='{}'
for f in "$WORK"/new/*.img; do
    n=$(basename "$f")
    [ "$n" = "super.img" ] && continue
    IMAGES_JSON=$(jq -c --arg n "$n" --arg s "$(sha256sum "$f" | cut -d' ' -f1)" '. + {($n): $s}' <<< "$IMAGES_JSON")
done

TAG="${DEVICE}-${CHANNEL}-${BUILD}"
BASE="https://github.com/${OTA_REPO}/releases/download/${TAG}"
DATE=$(date -u +%Y-%m-%dT%H:%M:%SZ)

# previous build of this device and channel
PREV=''
if [ -n "${OTA_PREV_FEED_FILE:-}" ]; then
    PREV=$(cat "$OTA_PREV_FEED_FILE" 2> /dev/null || true)
else
    PREV=$(curl -fsSL "https://github.com/${OTA_REPO}/releases/download/feed/${DEVICE}-${CHANNEL}.json" 2> /dev/null || true)
fi
TYPE=none; FROM=null; FILENAME=''; URL=''; SIZE=0; SHA=''
PREV_UPDATES=$(jq -c '.updates // []' <<< "$PREV" 2> /dev/null || echo '[]')
[ -n "$PREV_UPDATES" ] || PREV_UPDATES='[]'
PREV_BUILD=$(jq -r '.build // empty' <<< "$PREV" 2> /dev/null || true)
PREV_IDX_URL=$(jq -r '.idx_url // empty' <<< "$PREV" 2> /dev/null || true)

if [ -n "$PREV_BUILD" ] && [ -n "$PREV_IDX_URL" ]; then
    if [ -n "${OTA_PREV_IDX_FILE:-}" ]; then cp "$OTA_PREV_IDX_FILE" "$WORK/prev.idx"; else curl -fsSL -o "$WORK/prev.idx" "$PREV_IDX_URL"; fi
    echo "Making the patch from build $PREV_BUILD"
    "$RC" diff "$WORK/prev.idx" "$WORK/new/super.img" "$WORK/super.patch"

    PKG="$WORK/pkg"
    mkdir -p "$PKG/META-INF/com/google/android"
    cp "$HERE/update-binary" "$PKG/META-INF/com/google/android/update-binary"
    echo '# ReCore delta OTA: the work is done by update-binary' > "$PKG/META-INF/com/google/android/updater-script"
    cp "$RC_ARM" "$PKG/rcdelta"
    cp "$WORK/super.patch" "$PKG/super.patch"

    CHANGED=''
    for n in $(jq -r 'keys[]' <<< "$IMAGES_JSON"); do
        have=$(jq -r --arg n "$n" '.images[$n] // empty' <<< "$PREV")
        want=$(jq -r --arg n "$n" '.[$n]' <<< "$IMAGES_JSON")
        if [ "$have" != "$want" ]; then
            cp "$WORK/new/$n" "$PKG/$n"
            CHANGED="$CHANGED $n"
        fi
    done
    {
        echo "DEVICE=$DEVICE"
        echo "CHANNEL=$CHANNEL"
        echo "FROM_BUILD=$PREV_BUILD"
        echo "TO_BUILD=$BUILD"
        echo "NEW_SIZE=$NEW_SIZE"
        echo "NEW_SHA=$NEW_SHA"
        echo "IMAGES=\"${CHANGED# }\""
    } > "$PKG/manifest.sh"

    FILENAME="ReCore-OTA_${DEVICE}_${CHANNEL}_${PREV_BUILD}-to-${BUILD}.zip"
    (cd "$PKG" && zip -q -r -9 -X "$OUT/$FILENAME" .)
    SIZE=$(stat -c %s "$OUT/$FILENAME")
    if [ "$SIZE" -ge "$LIMIT" ]; then
        echo "::warning::The update zip is $SIZE bytes, over the 2 GiB GitHub limit. No OTA for this build, users flash the full zip."
        rm -f "$OUT/$FILENAME"; FILENAME=''; SIZE=0
    else
        TYPE=delta; FROM=$PREV_BUILD; URL="$BASE/$FILENAME"
        SHA=$(sha256sum "$OUT/$FILENAME" | cut -d' ' -f1)
        echo "Delta zip: $FILENAME ($SIZE bytes), images:${CHANGED:- none}"
    fi
else
    echo "No previous build for ${DEVICE}-${CHANNEL}: publishing the baseline (index only)."
fi

jq -n \
    --arg device "$DEVICE" --arg channel "$CHANNEL" --argjson build "$BUILD" --arg date "$DATE" \
    --arg type "$TYPE" --argjson from_build "$FROM" --arg filename "$FILENAME" --arg url "$URL" \
    --argjson size "$SIZE" --arg sha256 "$SHA" \
    --argjson requires_free "$((NEW_SIZE + 1073741824))" \
    --arg idx_url "$BASE/super.idx" --arg super_sha256 "$NEW_SHA" --argjson super_size "$NEW_SIZE" \
    --argjson images "$IMAGES_JSON" --arg changelog "$CHANGELOG" --argjson prev "$PREV_UPDATES" \
    '{build:$build, from_build:$from_build, type:$type, filename:$filename, url:$url, size:$size,
      sha256:$sha256, requires_free:$requires_free, changelog:$changelog, date:$date} as $step
     | {device:$device, channel:$channel, build:$build, date:$date, type:$type, from_build:$from_build,
        filename:$filename, url:$url, size:$size, sha256:$sha256, requires_free:$requires_free,
        idx_url:$idx_url, super_sha256:$super_sha256, super_size:$super_size, images:$images, changelog:$changelog,
        updates: (($prev + [$step]) | .[-20:])}' \
    > "$OUT/feed.json"
cat "$OUT/feed.json"
