# MOD_NAME="Bluetooth HFP software datapath (test)"
SYS="$(GET_PARTITION_PATH system main)"
BP=""
for p in "$SYS/system/build.prop" "$SYS/build.prop"; do
    [ -f "$p" ] && BP="$p" && break
done
[ -z "$BP" ] && ERROR_EXIT "build.prop not found under $SYS"

KEY="bluetooth.hfp.software_datapath.enabled"
sed -i "/^$KEY=/d" "$BP"
printf '\n%s=true\n' "$KEY" >> "$BP"
LOG_INFO "Set $KEY=true in $BP"
LOG_END
