# MOD_NAME="TEST ff_diag: finger sensor gesture gating (stock A14 vs S23 FE base)"

LOG_BEGIN "TEST ff_diag"

_FD_OUT=/tmp/test_artifacts
mkdir -p "$_FD_OUT"

_FD_STOCK=$(GET_PARTITION_PATH "system" "stock") || ERROR_EXIT "ff_diag: stock system not found"
_FD_MAIN=$(GET_PARTITION_PATH "system" "main")   || ERROR_EXIT "ff_diag: main system not found"
_FD_WS=$(GET_PARTITION_PATH "system")            || ERROR_EXIT "ff_diag: workspace system not found"

for _FD_PAIR in "stock:$_FD_STOCK" "main:$_FD_MAIN" "ws:$_FD_WS"; do
    _FD_TAG="${_FD_PAIR%%:*}"
    _FD_ROOT="${_FD_PAIR#*:}"
    _FD_D="$_FD_OUT/$_FD_TAG"
    mkdir -p "$_FD_D"
    LOG_INFO "ff_diag: scanning $_FD_TAG ($_FD_ROOT)"

    if [[ -f "$_FD_ROOT/etc/floating_feature.xml" ]]; then
        cp "$_FD_ROOT/etc/floating_feature.xml" "$_FD_D/floating_feature.xml"
        grep -o '<SEC_FLOATING_FEATURE[A-Za-z0-9_]*>[^<]*' "$_FD_ROOT/etc/floating_feature.xml" \
            | sort > "$_FD_D/ff_keys.txt" || true
    else
        echo "floating_feature.xml missing" > "$_FD_D/floating_feature.MISSING.txt"
    fi

    : > "$_FD_D/strings.txt"
    while IFS= read -r _FD_F; do
        _FD_REL="${_FD_F#$_FD_ROOT/}"
        echo "=== $_FD_REL" >> "$_FD_D/strings.txt"
        unzip -p "$_FD_F" 'classes*.dex' 2>/dev/null \
            | grep -a -o -E '[A-Za-z0-9_./$]*([Ff]inger_?[Ss]ensor|FINGER_SENSOR|[Ss]wipe_?[Ff]inger|FINGERPRINT_SWIPE|[Ff]ingerprint_?[Gg]esture|FINGER_GESTURE|[Ff]p_?[Ss]wipe)[A-Za-z0-9_./$]*' \
            | sort -u >> "$_FD_D/strings.txt" || true
    done < <(find "$_FD_ROOT" -type f \( -iname 'SecSettings.apk' -o -iname 'Settings.apk' -o -iname 'SystemUI.apk' -o -iname 'services.jar' -o -iname 'framework.jar' \) 2>/dev/null | sort)
done

diff "$_FD_OUT/stock/ff_keys.txt" "$_FD_OUT/main/ff_keys.txt" > "$_FD_OUT/ff_stock_vs_main.diff" 2>&1 || true
diff "$_FD_OUT/stock/ff_keys.txt" "$_FD_OUT/ws/ff_keys.txt"   > "$_FD_OUT/ff_stock_vs_ws.diff" 2>&1 || true

LOG_INFO "ff_diag: files written to $_FD_OUT"
LOG_END "ff_diag done"
ERROR_EXIT "ff_diag: diagnostics only, stopping on purpose (run with upload_cloud OFF)"