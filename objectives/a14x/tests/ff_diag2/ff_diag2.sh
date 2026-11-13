# MOD_NAME="TEST ff_diag2: dex for finger gesture handler + gate, AOD flag users"

LOG_BEGIN "TEST ff_diag2"

_F2_OUT=/tmp/test_artifacts
mkdir -p "$_F2_OUT/extra"

_F2_STOCK=$(GET_PARTITION_PATH "system" "stock") || ERROR_EXIT "ff_diag2: stock system not found"
_F2_EXTRA=$(GET_PARTITION_PATH "system" "extra") || ERROR_EXIT "ff_diag2: extra system not found"
_F2_WS=$(GET_PARTITION_PATH "system")            || ERROR_EXIT "ff_diag2: workspace system not found"

# copy each classesN.dex of $1 that contains string $3, xz-compressed, as <label>_classesN.dex.xz
_F2_PICK() {
    local _jar="$1" _label="$2" _needle="$3" _tmp _dex
    if [[ ! -f "$_jar" ]]; then
        LOG_INFO "ff_diag2: missing $_jar"
        return 0
    fi
    _tmp=$(mktemp -d)
    unzip -q -o "$_jar" 'classes*.dex' -d "$_tmp" 2>/dev/null || true
    for _dex in "$_tmp"/classes*.dex; do
        [[ -f "$_dex" ]] || continue
        if grep -a -q "$_needle" "$_dex"; then
            xz -9 -T0 -c "$_dex" > "$_F2_OUT/${_label}_$(basename "$_dex").xz"
            LOG_INFO "ff_diag2: $_label <- $(basename "$_dex") ($_needle)"
        fi
    done
    rm -rf "$_tmp"
}

# 1) stock handler for the sensor swipe, and the Settings gate
_F2_PICK "$_F2_STOCK/framework/services.jar" stock_services "fingerprint_gesture_quick"
_F2_PICK "$_F2_WS/priv-app/SecSettings/SecSettings.apk" ws_secsettings "FingerSensorGesturePreferenceController"

# 2) AOD flag: what does a newer firmware (S26 Ultra) declare, and who reads aodversion
if [[ -f "$_F2_EXTRA/etc/floating_feature.xml" ]]; then
    cp "$_F2_EXTRA/etc/floating_feature.xml" "$_F2_OUT/extra/floating_feature.xml"
    grep -o '<SEC_FLOATING_FEATURE[A-Za-z0-9_]*>[^<]*' "$_F2_EXTRA/etc/floating_feature.xml" \
        | sort > "$_F2_OUT/extra/ff_keys.txt" || true
fi

: > "$_F2_OUT/aodversion_users.txt"
while IFS= read -r _F2_A; do
    _F2_N=$(unzip -p "$_F2_A" 'classes*.dex' 2>/dev/null | grep -a -c 'aodversion' || true)
    if [[ "${_F2_N:-0}" -gt 0 ]]; then
        echo "${_F2_A#$_F2_WS/}" >> "$_F2_OUT/aodversion_users.txt"
    fi
done < <(find "$_F2_WS" -type f \( -name '*.apk' -o -name '*.jar' \) 2>/dev/null | sort)

ls -l "$_F2_OUT" > "$_F2_OUT/ls.txt" 2>&1 || true

LOG_END "ff_diag2 done"
ERROR_EXIT "ff_diag2: diagnostics only, stopping on purpose (run with upload_cloud OFF)"