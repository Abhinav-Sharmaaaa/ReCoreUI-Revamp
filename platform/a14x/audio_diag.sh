# MOD_NAME="Audio effects diagnostics (read-only, stops the build)"

LOG_BEGIN "Audio effects diagnostics"

_AD_P() { sed 's/^/[AUDIODIAG] /'; }

_AD_STOCK_SYS=$(GET_PARTITION_PATH "system" "stock")
_AD_MAIN_SYS=$(GET_PARTITION_PATH "system" "main")
_AD_STOCK_VND=$(GET_PARTITION_PATH "vendor" "stock")
_AD_MAIN_VND=$(GET_PARTITION_PATH "vendor" "main")

_AD_SHOW_SYSTEM() {
    local LABEL="$1" SYS="$2" F
    echo "===== $LABEL system: $SYS" | _AD_P
    echo "--- files matching booster / saplus / volumemonitor" | _AD_P
    find "$SYS" -type f \( -iname '*booster*' -o -iname '*saplus*' -o -iname '*volumemonitor*' \) \
        -printf '%p  %s bytes\n' 2>/dev/null | sort | _AD_P
    echo "--- SoundBooster engine version strings" | _AD_P
    while IFS= read -r F; do
        echo "$F: $(grep -a -o 'SoundBooster_Arm_v[0-9.]*' "$F" 2>/dev/null | sort -u | tr '\n' ' ')" | _AD_P
    done < <(find "$SYS" -type f -iname 'lib_SoundBooster*.so' 2>/dev/null | sort)
    echo "--- etc/audio_effects_common.conf" | _AD_P
    if [[ -f "$SYS/etc/audio_effects_common.conf" ]]; then
        _AD_P < "$SYS/etc/audio_effects_common.conf"
    else
        echo "(missing)" | _AD_P
    fi
    echo "--- audio / volume files in etc" | _AD_P
    ls -l "$SYS/etc" 2>/dev/null | grep -i 'audio\|volume' | _AD_P
}

_AD_SHOW_VENDOR() {
    local LABEL="$1" VND="$2" F
    echo "===== $LABEL vendor: $VND" | _AD_P
    if [[ -f "$VND/etc/SoundBoosterParam.txt" ]]; then
        ls -l "$VND/etc/SoundBoosterParam.txt" | _AD_P
        md5sum "$VND/etc/SoundBoosterParam.txt" | _AD_P
        echo "lines: $(wc -l < "$VND/etc/SoundBoosterParam.txt")" | _AD_P
        echo "first 300 bytes:" | _AD_P
        head -c 300 "$VND/etc/SoundBoosterParam.txt" | tr -d '\r' | _AD_P
    else
        echo "SoundBoosterParam.txt missing" | _AD_P
    fi
    while IFS= read -r F; do
        echo "$F: $(grep -a -o 'SoundBooster_Arm_v[0-9.]*' "$F" 2>/dev/null | sort -u | tr '\n' ' ')" | _AD_P
    done < <(find "$VND" -type f -iname 'lib_SoundBooster*.so' 2>/dev/null | sort)
}

_AD_SHOW_SYSTEM "STOCK (SM-A146B)" "$_AD_STOCK_SYS"
_AD_SHOW_SYSTEM "MAIN (SM-S711B)" "$_AD_MAIN_SYS"
_AD_SHOW_VENDOR "STOCK (SM-A146B)" "$_AD_STOCK_VND"
_AD_SHOW_VENDOR "MAIN (SM-S711B)" "$_AD_MAIN_VND"

echo "===== diff stock vs main: etc/audio_effects_common.conf" | _AD_P
diff -u "$_AD_STOCK_SYS/etc/audio_effects_common.conf" \
        "$_AD_MAIN_SYS/etc/audio_effects_common.conf" 2>&1 | _AD_P

LOG_END "Audio diagnostics printed above (search the log for AUDIODIAG)"
ERROR_EXIT "Stopping on purpose after audio diagnostics. Delete platform/a14x/audio_diag.sh before a real build."
