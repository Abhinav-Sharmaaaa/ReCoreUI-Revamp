# MOD_NAME="TEST ff_diag4: biometrics smali (base+stock) and AOD_ITEM readers"

LOG_BEGIN "TEST ff_diag4"

_F4_OUT=/tmp/test_artifacts
_F4_TMP=$(mktemp -d)
mkdir -p "$_F4_OUT"

_F4_STOCK=$(GET_PARTITION_PATH "system" "stock") || ERROR_EXIT "ff_diag4: stock system not found"
_F4_WS=$(GET_PARTITION_PATH "system")            || ERROR_EXIT "ff_diag4: workspace system not found"
_F4_BAK="$PREBUILTS/smali/baksmali.jar"
[[ -f "$_F4_BAK" ]] || ERROR_EXIT "ff_diag4: baksmali not found at $_F4_BAK"
_F4_JOBS="${USABLE_THREADS:-4}"

# disassemble all dex parts of a jar into <out>/smali, smali_classes2, ...
_F4_SMALI() {
    local _jar="$1" _out="$2" _part=1 _in _o _magic
    mkdir -p "$_out"
    _magic=$(unzip -p "$_jar" classes.dex 2>/dev/null | head -c 8 | xxd -s 4 -l 4 -p) || true
    if [[ "$_magic" == "30343100" ]]; then
        while true; do
            _in="$_jar/classes.dex"; _o="$_out/smali"
            if [[ $_part -gt 1 ]]; then _in="$_jar/classes.dex/$_part"; _o="$_out/smali_classes$_part"; fi
            java -jar "$_F4_BAK" d -a 35 -j "$_F4_JOBS" --ac false --di false -l -o "$_o" "$_in" >/dev/null 2>&1 || { rm -rf "$_o"; break; }
            [[ -d "$_o" ]] || break
            _part=$((_part+1)); [[ $_part -gt 20 ]] && break
        done
    else
        java -jar "$_F4_BAK" d -a 35 -j "$_F4_JOBS" --ac false --di false -l -o "$_out/smali" "$_jar" >/dev/null 2>&1 \
            || LOG_WARN "ff_diag4: baksmali failed for $_jar"
    fi
}

# keep only com/android/server/biometrics from every smali dir, as a tgz
_F4_PICK() {
    local _root="$1" _label="$2" _d _dest="$_F4_TMP/pick_$2"
    mkdir -p "$_dest"
    for _d in "$_root"/smali*; do
        [[ -d "$_d/com/android/server/biometrics" ]] || continue
        mkdir -p "$_dest/$(basename "$_d")/com/android/server"
        cp -a "$_d/com/android/server/biometrics" "$_dest/$(basename "$_d")/com/android/server/"
    done
    tar czf "$_F4_OUT/${_label}_biometrics_smali.tgz" -C "$_dest" .
    LOG_INFO "ff_diag4: wrote ${_label}_biometrics_smali.tgz"
}

# 1) base services.jar: biometrics smali + AOD_ITEM readers
_F4_SMALI "$_F4_WS/framework/services.jar" "$_F4_TMP/ws_services"
_F4_PICK "$_F4_TMP/ws_services" ws_services
grep -rn -B15 -A15 -e 'aodversion' -e 'FRAMEWORK_CONFIG_AOD_ITEM' "$_F4_TMP/ws_services" 2>/dev/null \
    | head -c 600000 > "$_F4_OUT/aod_readers_services.txt" || true
rm -rf "$_F4_TMP/ws_services"

# 2) base framework.jar: AOD_ITEM readers only
_F4_SMALI "$_F4_WS/framework/framework.jar" "$_F4_TMP/ws_framework"
grep -rn -B15 -A15 -e 'aodversion' -e 'FRAMEWORK_CONFIG_AOD_ITEM' "$_F4_TMP/ws_framework" 2>/dev/null \
    | head -c 600000 > "$_F4_OUT/aod_readers_framework.txt" || true
rm -rf "$_F4_TMP/ws_framework"

# 3) stock services.jar: biometrics smali (source of the gesture code)
_F4_SMALI "$_F4_STOCK/framework/services.jar" "$_F4_TMP/stock_services"
_F4_PICK "$_F4_TMP/stock_services" stock_services
rm -rf "$_F4_TMP/stock_services"

ls -l "$_F4_OUT" > "$_F4_OUT/ls.txt" 2>&1 || true
rm -rf "$_F4_TMP"

LOG_END "ff_diag4 done"
ERROR_EXIT "ff_diag4: diagnostics only, stopping on purpose (run with upload_cloud OFF)"