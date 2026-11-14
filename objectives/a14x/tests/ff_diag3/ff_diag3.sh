# MOD_NAME="TEST ff_diag3: base services dex + Settings dex/xml for finger gesture port"

LOG_BEGIN "TEST ff_diag3"

_F3_OUT=/tmp/test_artifacts
mkdir -p "$_F3_OUT/res_stock" "$_F3_OUT/res_ws"

_F3_STOCK=$(GET_PARTITION_PATH "system" "stock") || ERROR_EXIT "ff_diag3: stock system not found"
_F3_WS=$(GET_PARTITION_PATH "system")            || ERROR_EXIT "ff_diag3: workspace system not found"

_F3_PICK() {
    local _jar="$1" _label="$2" _needle="$3" _tmp _dex
    if [[ ! -f "$_jar" ]]; then
        LOG_INFO "ff_diag3: missing $_jar"
        return 0
    fi
    _tmp=$(mktemp -d)
    unzip -q -o "$_jar" 'classes*.dex' -d "$_tmp" 2>/dev/null || true
    for _dex in "$_tmp"/classes*.dex; do
        [[ -f "$_dex" ]] || continue
        if grep -a -q "$_needle" "$_dex"; then
            xz -9 -T0 -c "$_dex" > "$_F3_OUT/${_label}_$(basename "$_dex").xz"
            LOG_INFO "ff_diag3: $_label <- $(basename "$_dex") ($_needle)"
        fi
    done
    rm -rf "$_tmp"
}

# 1) base side of the HAL gesture callback path (does SemFpGestureManager / onGestureEvent exist?)
_F3_PICK "$_F3_WS/framework/services.jar" ws_services "SemFpAidlResponseHandler"

# 2) Settings: dex that defines Rune, plus the Motions/gesture xml in stock and ws
_F3_PICK "$_F3_WS/priv-app/SecSettings/SecSettings.apk" ws_secsettings_rune "supportFingerSensorGestureSpay"
unzip -q -o "$_F3_STOCK/priv-app/SecSettings/SecSettings.apk" 'res/xml/*otion*' 'res/xml/*esture*' -d "$_F3_OUT/res_stock" 2>/dev/null || true
unzip -q -o "$_F3_WS/priv-app/SecSettings/SecSettings.apk"    'res/xml/*otion*' 'res/xml/*esture*' -d "$_F3_OUT/res_ws" 2>/dev/null || true

ls -lR "$_F3_OUT" > "$_F3_OUT/ls.txt" 2>&1 || true

LOG_END "ff_diag3 done"
ERROR_EXIT "ff_diag3: diagnostics only, stopping on purpose (run with upload_cloud OFF)"