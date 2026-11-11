# ==============================================================================
#
# MOD_NAME="Add Camera features"
# MOD_AUTHOR="Sameer Al Sahab"
# MOD_DESC="Add some camera features."
#
# ==============================================================================


LOG_BEGIN "Adding camera assistant features.."

# Disabled: Camera Assistant app is not installed on this ROM
# CF "SUPPORT_CAMERA_ASSISTANT" "value=true"

LOG_BEGIN "Adding extra camera features.."
# Disabled: the stock A146B/M146B/E146B config has SUPPORT_ADVANCED_RECORDING_OPTIONS=false.
# SUPPORT_VIDEO_MODE_ZOOM_ROCKER=true crashed Video mode in camera app 16.5.02.31.
# CF "SUPPORT_VIDEO_MODE_ZOOM_ROCKER" "value=true"
# CF "SUPPORT_LOG_VIDEO" "value=true"
# CF "SUPPORT_DEFAULT_HEVC" "value=true"
# CF "SUPPORT_VIDEO_HIGH_BITRATE" "value=true"
# CF "SUPPORT_VIDEO_AUTO_FPS_OPTION" "value=true"
# CF "SUPPORT_ADVANCED_ZERO_SHUTTER_LAG" "value=true"

# FF "CAMERA_CONFIG_LOG_VIDEO" "V1.0"
# FF "GALLERY_SUPPORT_LOG_CORRECT_COLOR" "TRUE"

# The camera app (16.5) only accepts image_codec.samsung.v2, while the stock
# firmware lists image_codec.samsung.v1. Keep each device's own list and only
# swap that one entry, so this works for every objective.
VLI_FILE="$WORKSPACE/system/system/etc/floating_feature.xml"
VLI_CUR=$(xmlstarlet sel -t -v "//SEC_FLOATING_FEATURE_CAMERA_CONFIG_VENDOR_LIB_INFO" "$VLI_FILE" 2>/dev/null || true)
VLI_NEW="${VLI_CUR//image_codec.samsung.v1/image_codec.samsung.v2}"
if [[ -n "$VLI_CUR" && "$VLI_NEW" != "$VLI_CUR" ]]; then
    FF "CAMERA_CONFIG_VENDOR_LIB_INFO" "$VLI_NEW"
fi

# Gallery
FF "MMFW_SUPPORT_AI_UPSCALER" "TRUE"

LOG_END "Camera features added."
