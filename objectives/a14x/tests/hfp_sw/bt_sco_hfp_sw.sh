# MOD_NAME="TEST: Bluetooth HFP software datapath"
# MOD_AUTHOR="test"

LOG_INFO "TEST: setting bluetooth.hfp.software_datapath.enabled=true"
BPROP "system" "bluetooth.hfp.software_datapath.enabled" "true"
LOG_INFO "TEST: value now: $(GET_PROP "system" "bluetooth.hfp.software_datapath.enabled")"
