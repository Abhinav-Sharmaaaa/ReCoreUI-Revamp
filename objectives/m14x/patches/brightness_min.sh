LOG_BEGIN "- Raising minimum brightness in product overlay"

RRO_APK="$WORKSPACE/product/overlay/product_overlay.apk"
[[ -f "$RRO_APK" ]] || ERROR_EXIT "product_overlay.apk not found"

RRO_RELATIVE="${RRO_APK#$WORKSPACE/}"
RRO_WORK="$WORKSPACE/product/overlay/product_overlay.apk_decompiled"

DECOMPILE "$RRO_RELATIVE" || ERROR_EXIT "Failed to decompile product_overlay.apk"
[[ -d "$RRO_WORK" ]] || ERROR_EXIT "Decompiled overlay not found"

INTS="$RRO_WORK/res/values/integers.xml"
DIMS="$RRO_WORK/res/values/dimens.xml"

xmlstarlet ed -L -u '//*[@name="config_screenBrightnessSettingMinimum"]' -v 1 "$INTS" \
    || ERROR_EXIT "Failed to patch integers.xml"
xmlstarlet ed -L -u '//*[@name="config_screenBrightnessSettingMinimumFloat"]' -v 0.003921569 "$DIMS" \
    || ERROR_EXIT "Failed to patch dimens.xml"

# Fail the build if the edits did not actually apply
grep -q 'name="config_screenBrightnessSettingMinimum"[^>]*>1<' "$INTS" \
    || ERROR_EXIT "Minimum brightness (integer) was not applied"
grep -q 'name="config_screenBrightnessSettingMinimumFloat"[^>]*>0.003921569<' "$DIMS" \
    || ERROR_EXIT "Minimum brightness (float) was not applied"

BUILD "$RRO_RELATIVE" || ERROR_EXIT "Failed to rebuild product_overlay.apk"

LOG_END "Minimum brightness raised"
