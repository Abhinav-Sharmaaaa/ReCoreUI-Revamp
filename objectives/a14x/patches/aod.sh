#This Device Has LCD Panel
LOG_BEGIN "- Adding ClockPack_v80 and removing AODService_v80"
ADD_FROM_FW "a17" "system" "priv-app/ClockPack_v80"
ADD_FROM_FW "a17" "system" "etc/permissions/com.samsung.feature.clockpack_v10.xml"
ADD_FROM_FW "a17" "system" "etc/permissions/privapp-permissions-com.samsung.android.app.clockpack.xml"
SILENT REMOVE "system" "priv-app/AODService_v80"
SILENT REMOVE "system" "etc/permissions/com.samsung.feature.aodservice_v10.xml"
SILENT REMOVE "system" "etc/permissions/privapp-permissions-com.samsung.android.app.aodservice.xml"
LOG_END

# LockStar 8.5.00.17 checks that the package com.samsung.android.app.aodservice exists with versionCode >= 882400000
# (the floating feature FRAMEWORK_CONFIG_AOD_ITEM contains "aodversion", so it looks for aodservice instead of clockpack).
# This ROM deliberately has no AODService, so add an EMPTY stub package with that name: no components, no permissions,
# no code, no feature xml and no privapp-permissions entry, versionCode 893292100 (same as ClockPack_v80 8.9.32.92).
LOG_BEGIN "- Adding empty com.samsung.android.app.aodservice stub for LockStar"
_STUB_SYS=$(GET_PARTITION_PATH "system") || ERROR_EXIT "aod stub: system partition not found"
_STUB_DIR="$_STUB_SYS/priv-app/AodServiceStub"
_STUB_TMP=$(mktemp -d)

base64 -d > "$_STUB_TMP/stub-unsigned.apk" <<'EOF_STUB_B64'
UEsDBBQAAAAIAAAAIVzZSUnYfgEAAJQDAAATAAAAQW5kcm9pZE1hbmlmZXN0LnhtbHVTwUrDQBSc
TaxNTYUiHgR7Kp4EW6goVcSLHkUExbOh1Vq1aWhi6Un8Ag/iwe/wK/wGv8O7zntuSRrbXSa7O/N2
3tsHceHhzQUMqvg2wDLScZbZrxB3xBPxTnwQn8QXUeO9XeKCGBOvRBEBQnQwxAA9rsAmbpFwRthH
gzNGm8w1+oyMUc/F16kOqDXIR7jnOmRsrOdpX08dQp5uNCIh52PE/ZCnHuNCHPHbIfNfOeXdviol
tJh1j9hGU3dNyDsiRrRZQYCuxtVsZXV6yN0Yj/TpzniBVB7pKtljzTui1lYfj/dirXiL6DCDdL9P
PcS5ni+nKgUqfFtARupI5sT4NuuD5gkYN1GK7LZ0Ou3Fs/FwgOmx7hhTJXI0yuQiy5fB1VSwZrUf
DllFdMhfZXgZDvernK7lJc61usdnHb8c7gi3QBS0M3ALVl/Uyv+4ovU/yfl71t/J+Jcy/jXLLWW4
Dakh94aJl+Ro5Xjf5jCZHOXUT36PmX7+HF5qNXN6+AtQSwECFAMUAAAACAAAACFc2UlJ2H4BAACU
AwAAEwAAAAAAAAAAAAAAgAEAAAAAQW5kcm9pZE1hbmlmZXN0LnhtbFBLBQYAAAAAAQABAEEAAACv
AQAAAAA=
EOF_STUB_B64
unzip -tq "$_STUB_TMP/stub-unsigned.apk" > /dev/null || ERROR_EXIT "aod stub: embedded apk is corrupt"

# sign with the ROM key when the build has one, otherwise with a throwaway key (the stub has its own uid, so any key works)
_STUB_PEM="$CERT_PEM"; _STUB_PK8="$CERT_PK8"
if [[ ! -f "$_STUB_PEM" || ! -f "$_STUB_PK8" ]]; then
    openssl req -x509 -newkey rsa:2048 -nodes -days 36500 -subj "/CN=aodstub" \
        -keyout "$_STUB_TMP/k.pem" -out "$_STUB_TMP/c.pem" > /dev/null 2>&1 || ERROR_EXIT "aod stub: openssl key generation failed"
    openssl pkcs8 -topk8 -outform DER -in "$_STUB_TMP/k.pem" -out "$_STUB_TMP/k.pk8" -nocrypt > /dev/null 2>&1 || ERROR_EXIT "aod stub: openssl pkcs8 failed"
    _STUB_PEM="$_STUB_TMP/c.pem"; _STUB_PK8="$_STUB_TMP/k.pk8"
fi
java -jar "$PREBUILTS/signapk/signapk.jar" "$_STUB_PEM" "$_STUB_PK8" \
    "$_STUB_TMP/stub-unsigned.apk" "$_STUB_TMP/AodServiceStub.apk" > /dev/null 2>&1 || ERROR_EXIT "aod stub: signapk failed"
if command -v zipalign > /dev/null 2>&1; then
    zipalign -p -f 4 "$_STUB_TMP/AodServiceStub.apk" "$_STUB_TMP/aligned.apk" > /dev/null 2>&1 && mv -f "$_STUB_TMP/aligned.apk" "$_STUB_TMP/AodServiceStub.apk"
fi

mkdir -p "$_STUB_DIR" || ERROR_EXIT "aod stub: cannot create $_STUB_DIR"
cp -f "$_STUB_TMP/AodServiceStub.apk" "$_STUB_DIR/AodServiceStub.apk" || ERROR_EXIT "aod stub: copy failed"
chmod 755 "$_STUB_DIR"
chmod 644 "$_STUB_DIR/AodServiceStub.apk"
rm -rf "$_STUB_TMP"
LOG_END
