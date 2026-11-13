# MOD_NAME="TEST aod_pair: S23 FE AODService_v80 (matches DressRoom) instead of A17 ClockPack_v80"

LOG_BEGIN "TEST aod_pair"

_AP_MAIN=$(GET_PARTITION_PATH "system" "main") || ERROR_EXIT "aod_pair: main system not found"
[[ -d "$_AP_MAIN/priv-app/AODService_v80" ]] || ERROR_EXIT "aod_pair: AODService_v80 missing in main firmware"

REMOVE "system" "priv-app/ClockPack_v80"
REMOVE "system" "etc/permissions/privapp-permissions-com.samsung.android.app.clockpack.xml"
REMOVE "system" "etc/permissions/com.samsung.feature.clockpack_v10.xml"

ADD_FROM_FW "main" "system" "priv-app/AODService_v80"

while IFS= read -r _AP_F; do
    _AP_REL="${_AP_F#$_AP_MAIN/}"
    LOG_INFO "AOD file from main: $_AP_REL"
    ADD_FROM_FW "main" "system" "$_AP_REL"
done < <(find "$_AP_MAIN/etc" -type f -iname '*aod*' 2>/dev/null | sort)

_AP_WS=$(GET_PARTITION_PATH "system")
[[ -d "$_AP_WS/priv-app/AODService_v80" ]] || ERROR_EXIT "aod_pair: AODService_v80 not in workspace"
[[ ! -d "$_AP_WS/priv-app/ClockPack_v80" ]] || ERROR_EXIT "aod_pair: ClockPack_v80 still in workspace"

LOG_END "aod_pair applied"
true