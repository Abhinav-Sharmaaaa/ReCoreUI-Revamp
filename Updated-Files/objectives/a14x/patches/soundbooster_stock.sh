# MOD_NAME="Sound Booster: use A14 stock engine and wrapper (matches vendor tuning file)"

LOG_BEGIN "Sound Booster: stock engine + wrapper"

_SB_STOCK=$(GET_PARTITION_PATH "system" "stock") || ERROR_EXIT "SoundBooster: stock system not found"
_SB_MAIN=$(GET_PARTITION_PATH "system" "main")   || ERROR_EXIT "SoundBooster: main system not found"
_SB_WS=$(GET_PARTITION_PATH "system")            || ERROR_EXIT "SoundBooster: workspace system not found"
_SB_STOCK_CFG="$(GET_FW_DIR stock)/config"
_SB_WS_CFG="$WORKSPACE/config"

echo "[SBFIX] stock wrapper refs (lib64): $(grep -a -o 'lib_SoundBooster[A-Za-z0-9_.]*' "$_SB_STOCK/lib64/libsamsungSoundbooster_plus_legacy.so" | sort -u | tr '\n' ' ')"
echo "[SBFIX] main  wrapper refs (lib64): $(grep -a -o 'lib_SoundBooster[A-Za-z0-9_.]*' "$_SB_MAIN/lib64/libsamsungSoundbooster_plus_legacy.so" | sort -u | tr '\n' ' ')"
if cmp -s "$_SB_STOCK/lib64/libsamsungSoundbooster_plus_legacy.so" "$_SB_MAIN/lib64/libsamsungSoundbooster_plus_legacy.so"; then
    echo "[SBFIX] lib64 wrapper is byte-identical on stock and main"
else
    echo "[SBFIX] lib64 wrapper differs between stock and main"
fi

_SB_FILES=(
    "lib/lib_SoundBooster_ver1100.so"
    "lib64/lib_SoundBooster_ver1100.so"
    "lib/libsamsungSoundbooster_plus_legacy.so"
    "lib64/libsamsungSoundbooster_plus_legacy.so"
)

for _SB_REL in "${_SB_FILES[@]}"; do
    [[ -f "$_SB_STOCK/$_SB_REL" ]] || ERROR_EXIT "SoundBooster: missing in stock: $_SB_REL"

    if [[ -f "$_SB_WS/$_SB_REL" ]] && cmp -s "$_SB_STOCK/$_SB_REL" "$_SB_WS/$_SB_REL"; then
        LOG_INFO "Already stock: $_SB_REL"
    else
        rm -f "$_SB_WS/$_SB_REL"
        cp --preserve=mode,timestamps "$_SB_STOCK/$_SB_REL" "$_SB_WS/$_SB_REL" \
            || ERROR_EXIT "SoundBooster: copy failed: $_SB_REL"
        LOG_INFO "Replaced with stock: $_SB_REL"
    fi

    _SB_CTX="/system/${_SB_REL//./\\.} "
    _SB_FSC="system/$_SB_REL "

    if ! grep -qF -- "$_SB_CTX" "$_SB_WS_CFG/system_file_contexts"; then
        grep -F -- "$_SB_CTX" "$_SB_STOCK_CFG/system_file_contexts" >> "$_SB_WS_CFG/system_file_contexts" \
            || ERROR_EXIT "SoundBooster: no SELinux context found for $_SB_REL"
        LOG_INFO "Added SELinux context: $_SB_REL"
    fi
    if ! grep -qF -- "$_SB_FSC" "$_SB_WS_CFG/system_fs_config"; then
        grep -F -- "$_SB_FSC" "$_SB_STOCK_CFG/system_fs_config" >> "$_SB_WS_CFG/system_fs_config" \
            || ERROR_EXIT "SoundBooster: no fs_config entry found for $_SB_REL"
        LOG_INFO "Added fs_config entry: $_SB_REL"
    fi

    cmp -s "$_SB_STOCK/$_SB_REL" "$_SB_WS/$_SB_REL" \
        || ERROR_EXIT "SoundBooster: verification failed: $_SB_REL"
done

LOG_END "Sound Booster stock engine and wrapper applied"
true
