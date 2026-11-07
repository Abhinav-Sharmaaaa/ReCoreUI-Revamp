LOG_BEGIN "- Raising minimum brightness in product overlay"

RRO_APK="$WORKSPACE/product/overlay/product_overlay.apk"
[[ -f "$RRO_APK" ]] || ERROR_EXIT "product_overlay.apk not found"

RRO_RELATIVE="${RRO_APK#$WORKSPACE/}"
RRO_WORK="$WORKSPACE/product/overlay/product_overlay.apk_decompiled"

DECOMPILE "$RRO_RELATIVE" || ERROR_EXIT "Failed to decompile product_overlay.apk"
[[ -d "$RRO_WORK" ]] || ERROR_EXIT "Decompiled overlay not found"

xmlstarlet ed -L -u '//integer[@name="config_screenBrightnessSettingMinimum"]' -v 1 \
    "$RRO_WORK/res/values/integers.xml" || ERROR_EXIT "Failed to patch integers.xml"
xmlstarlet ed -L -u '//dimen[@name="config_screenBrightnessSettingMinimumFloat"]' -v 0.003921569 \
    "$RRO_WORK/res/values/dimens.xml" || ERROR_EXIT "Failed to patch dimens.xml"

BUILD "$RRO_RELATIVE" || ERROR_EXIT "Failed to rebuild product_overlay.apk"

LOG_END "Minimum brightness raised"
