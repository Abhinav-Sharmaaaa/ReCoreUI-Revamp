# MOD_NAME="TEST settings_diag: where Settings opens Software update"
# Read-only diagnostic. Save as objectives/a14x/tests/settings_diag/settings_diag.sh and run it like the other
# diagnostics (test_build on, test_variant settings_diag, upload_cloud OFF). It collects the Settings screens and
# strings that mention software update, so the updater can be hooked into the Settings row.

LOG_BEGIN "TEST settings_diag"

_SD_OUT=/tmp/test_artifacts
mkdir -p "$_SD_OUT/xml"
_SD_SYS=$(GET_PARTITION_PATH "system") || ERROR_EXIT "settings_diag: system partition not found"
_SD_APK="$_SD_SYS/priv-app/SecSettings/SecSettings.apk"
[[ -f "$_SD_APK" ]] || ERROR_EXIT "settings_diag: SecSettings.apk not found at $_SD_APK"
_SD_TMP=$(mktemp -d)

# 1) Settings screens (binary xml) that mention software update or the stock update apps
unzip -q -o "$_SD_APK" 'res/xml/*' -d "$_SD_TMP" 2> /dev/null || true
for f in "$_SD_TMP"/res/xml/*.xml; do
    [[ -f "$f" ]] || continue
    if grep -a -q -i -E 'software_update|SYSTEM_UPDATE|wssyncmldm|soagent|fota' "$f"; then
        cp "$f" "$_SD_OUT/xml/"
    fi
done

# 2) code strings
: > "$_SD_OUT/strings.txt"
unzip -p "$_SD_APK" 'classes*.dex' 2> /dev/null \
    | grep -a -o -E '[A-Za-z0-9_./$:-]*(software_update|SYSTEM_UPDATE_SETTINGS|wssyncmldm|soagent|SoftwareUpdate|sw_update)[A-Za-z0-9_./$:-]*' \
    | sort -u >> "$_SD_OUT/strings.txt" || true

# 3) which update related apps are in the ROM
{
    echo "== priv-app"; ls "$_SD_SYS/priv-app" 2> /dev/null | grep -i -E 'wssyncmldm|soagent|fota|update|ota' || true
    echo "== app"; ls "$_SD_SYS/app" 2> /dev/null | grep -i -E 'wssyncmldm|soagent|fota|update|ota' || true
} > "$_SD_OUT/packages.txt"

rm -rf "$_SD_TMP"
ls -l "$_SD_OUT/xml" > "$_SD_OUT/ls.txt" 2>&1 || true
LOG_END "settings_diag done"
ERROR_EXIT "settings_diag: diagnostics only, stopping on purpose (run with upload_cloud OFF)"
