# MOD_NAME="TEST: Bluetooth disable enhanced SCO connection"
# MOD_AUTHOR="test"

LOG_INFO "TEST: setting bluetooth.sco.disable_enhanced_connection=true"
BPROP "system" "bluetooth.sco.disable_enhanced_connection" "true"
LOG_INFO "TEST: value now: $(GET_PROP "system" "bluetooth.sco.disable_enhanced_connection")"
