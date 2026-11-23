#This script puts the ReCore Updater app into the ROM as a system app.
#It downloads the latest APK that the "Build updater app" workflow published in the OTA repo.
#Needs RECORE_OTA_REPO (owner/name of the OTA repo); without it, or without network, the step is skipped.
LOG_BEGIN "- Adding ReCore Updater app"
_APP_SYS=$(GET_PARTITION_PATH "system") || ERROR_EXIT "updater app: system partition not found"
if [[ -z "${RECORE_OTA_REPO:-}" ]]; then
    LOG_INFO "RECORE_OTA_REPO is not set, skipping the updater app"
else
    _APP_TMP=$(mktemp -d)
    if curl -fsSL --retry 3 -o "$_APP_TMP/ReCoreOTA.apk" "https://github.com/${RECORE_OTA_REPO}/releases/download/app/ReCoreOTA.apk" \
        && unzip -tq "$_APP_TMP/ReCoreOTA.apk" > /dev/null 2>&1; then
        mkdir -p "$_APP_SYS/app/ReCoreOTA" || ERROR_EXIT "updater app: cannot create the app folder"
        cp -f "$_APP_TMP/ReCoreOTA.apk" "$_APP_SYS/app/ReCoreOTA/ReCoreOTA.apk" || ERROR_EXIT "updater app: copy failed"
        chmod 755 "$_APP_SYS/app/ReCoreOTA"
        chmod 644 "$_APP_SYS/app/ReCoreOTA/ReCoreOTA.apk"
        LOG_INFO "updater app added"
    else
        LOG_INFO "updater app not available yet (run Build updater app in the OTA repo first), skipping"
    fi
    rm -rf "$_APP_TMP"
fi
LOG_END
