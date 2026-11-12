# MOD_NAME="TEST: Bluetooth diagnostics (read-only, stops the build on purpose)"
# MOD_AUTHOR="test"

# Copies Bluetooth-related files and properties from the STOCK A14 firmware and from the
# main (S23 FE) workspace into /tmp/bt_diag, then stops the build. Nothing is modified.

OUT="/tmp/bt_diag"
rm -rf "$OUT"
mkdir -p "$OUT/stock_vendor" "$OUT/stock_system" "$OUT/main_system"

STOCK_VENDOR="$(GET_PARTITION_PATH vendor stock)"
STOCK_SYSTEM="$(GET_PARTITION_PATH system stock)"
MAIN_SYSTEM="$(GET_PARTITION_PATH system main)"
{
  echo "stock vendor : $STOCK_VENDOR"
  echo "stock system : $STOCK_SYSTEM"
  echo "main  system : $MAIN_SYSTEM"
} > "$OUT/paths.txt"

BT_COPY()
{
    local ROOT="$1" DEST="$2" F
    shift 2
    if [[ ! -d "$ROOT" ]]; then
        echo "missing dir: $ROOT" >> "$OUT/notes.txt"
        return 0
    fi
    ( cd "$ROOT" && find . -type f -size -60M \( "$@" \) ) | while read -r F; do
        mkdir -p "$DEST/$(dirname "$F")"
        cp -p "$ROOT/$F" "$DEST/$F"
    done
}

BT_PROPS()
{
    local ROOT="$1" DEST="$2" P
    [[ -d "$ROOT" ]] || return 0
    find "$ROOT" -type f \( -name "build.prop" -o -name "*.prop" \) 2>/dev/null | while read -r P; do
        echo "### $P" >> "$DEST"
        grep -iE "bluetooth|\.bt\.|sco|hfp|offload|a2dp|audio.*bt|dbfw|rvp" "$P" >> "$DEST" 2>/dev/null
    done
}

# Stock A14 vendor: Bluetooth HAL, vendor lib, init rc, firmware and config files
BT_COPY "$STOCK_VENDOR" "$OUT/stock_vendor" \
    -iname "*bluetooth*" -o -iname "libbt*" -o -iname "bt_*" -o -iname "*s620*" -o -iname "*rice*"

# Stock A14 system: the Bluetooth stack (plain lib or APEX)
BT_COPY "$STOCK_SYSTEM" "$OUT/stock_system" \
    -name "libbluetooth_jni.so" -o -name "libbluetooth*.so" -o -name "com.android.bt*.apex" -o -name "com.android.bt*.capex"

# Main (S23 FE) system: same, for a side-by-side
BT_COPY "$MAIN_SYSTEM" "$OUT/main_system" \
    -name "libbluetooth_jni.so" -o -name "com.android.bt*.apex" -o -name "com.android.bt*.capex"

# File listings (names only) so we can see what exists even if a file was too big
for R in "stock_vendor:$STOCK_VENDOR" "stock_system:$STOCK_SYSTEM" "main_system:$MAIN_SYSTEM"; do
    N="${R%%:*}"; D="${R#*:}"
    [[ -d "$D" ]] && ( cd "$D" && find . \( -iname "*bluetooth*" -o -iname "libbt*" -o -iname "com.android.bt*" \) 2>/dev/null ) > "$OUT/listing_$N.txt"
done

# Bluetooth/SCO related properties
BT_PROPS "$STOCK_VENDOR" "$OUT/props_stock_vendor.txt"
BT_PROPS "$STOCK_SYSTEM" "$OUT/props_stock_system.txt"
BT_PROPS "$MAIN_SYSTEM" "$OUT/props_main_system.txt"

chmod -R a+rX "$OUT" 2>/dev/null
du -sh "$OUT" 2>/dev/null
LOG_INFO "bt_diag: files staged in $OUT"
ERROR_EXIT "bt_diag finished - stopping the build on purpose (no ROM is produced)"
