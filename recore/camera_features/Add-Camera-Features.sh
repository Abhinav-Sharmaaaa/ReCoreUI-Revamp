# ==============================================================================
#
# MOD_NAME="Add Camera features"
# MOD_AUTHOR="Sameer Al Sahab"
# MOD_DESC="Add some camera features."
#
# ==============================================================================


LOG_BEGIN "Adding camera assistant features.."

# Disabled for A14 5G test: Camera Assistant app is not installed on this ROM
# CF "SUPPORT_CAMERA_ASSISTANT" "value=true"

LOG_BEGIN "Adding extra camera features.."
# Disabled for A14 5G test: stock A146B config has SUPPORT_ADVANCED_RECORDING_OPTIONS=false
# SUPPORT_VIDEO_MODE_ZOOM_ROCKER=true crashed Video mode in this camera app version
# CF "SUPPORT_VIDEO_MODE_ZOOM_ROCKER" "value=true"
# CF "SUPPORT_LOG_VIDEO" "value=true"
# CF "SUPPORT_DEFAULT_HEVC" "value=true"
# CF "SUPPORT_VIDEO_HIGH_BITRATE" "value=true"
# CF "SUPPORT_VIDEO_AUTO_FPS_OPTION" "value=true"
# CF "SUPPORT_ADVANCED_ZERO_SHUTTER_LAG" "value=true"

# FF "CAMERA_CONFIG_LOG_VIDEO" "V1.0"
# FF "GALLERY_SUPPORT_LOG_CORRECT_COLOR" "TRUE"

# The camera app (16.5) only accepts image_codec.samsung.v2; stock A146B lists v1
FF "CAMERA_CONFIG_VENDOR_LIB_INFO" "face_landmark.arcsoft.v2_1,facial_attribute.samsung.v1,dual_bokeh.samsung.v1,beauty.samsung.v4,food.samsung.v1,mfhdr.arcsoft.v2,llhdr.arcsoft.v1,image_codec.samsung.v2,single_bokeh.samsung.v2,scene_detection.samsung.v1,localtm.samsung.v1_1"

# Gallery
FF "MMFW_SUPPORT_AI_UPSCALER" "TRUE"

LOG_END "Camera features added."
