#This script writes the OTA identity of the ROM into system build.prop.
#The updater app reads ro.recore.ota.build and ro.recore.ota.channel and compares them with the feed.
#RECORE_BUILD_NUMBER and RECORE_CHANNEL come from the GitHub workflow (defaults are used for local builds).
LOG_BEGIN "- Setting OTA properties"
_OTA_SYS=$(GET_PARTITION_PATH "system") || ERROR_EXIT "ota: system partition not found"
_OTA_BP="$_OTA_SYS/build.prop"
[[ -f "$_OTA_BP" ]] || ERROR_EXIT "ota: build.prop not found at $_OTA_BP"

_OTA_CHANNEL="${RECORE_CHANNEL:-test}"
_OTA_BUILD="${RECORE_BUILD_NUMBER:-0}"
case "$_OTA_CHANNEL" in
    test|beta|release) ;;
    *) ERROR_EXIT "ota: invalid channel '$_OTA_CHANNEL' (test, beta or release)" ;;
esac
[[ "$_OTA_BUILD" =~ ^[0-9]+$ ]] || ERROR_EXIT "ota: invalid build number '$_OTA_BUILD'"

_ota_set() {
    local key="$1" val="$2"
    if grep -q "^${key}=" "$_OTA_BP"; then
        sed -i "s|^${key}=.*|${key}=${val}|" "$_OTA_BP"
    else
        printf '\n%s=%s\n' "$key" "$val" >> "$_OTA_BP"
    fi
}
_ota_set ro.recore.ota.channel "$_OTA_CHANNEL"
_ota_set ro.recore.ota.build "$_OTA_BUILD"
LOG_INFO "channel=$_OTA_CHANNEL build=$_OTA_BUILD"
LOG_END
