# MOD_NAME="Bluetooth: legacy SCO setup (fixes call audio on A14-class vendor)"
# MOD_AUTHOR="ReCoreUI"

# The Exynos 1330 Bluetooth controller rejects the Enhanced Setup Synchronous Connection
# command used by the S23 FE stack (HCI status 0x1F), so calls and mic never reach Bluetooth
# devices. Telling the stack to use the legacy SCO setup command fixes it.
# Verified on SM-A146B only (call audio and mic through earbuds).

LOG_INFO "Setting bluetooth.sco.disable_enhanced_connection=true"
BPROP "system" "bluetooth.sco.disable_enhanced_connection" "true"
LOG_INFO "Value now: $(GET_PROP "system" "bluetooth.sco.disable_enhanced_connection")"
