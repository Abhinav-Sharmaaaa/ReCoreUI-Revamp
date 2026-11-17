# Diag-AOD.sh (v2) - TEMPORARY, READ-ONLY. Delete after the log has been read.
# Does not rely on cwd: finds *.jar_decompiled dirs under $WORKSPACE itself.
# Search the CI log for "DIAG-AOD".

_DIAG_PAT='aodversion|FRAMEWORK_CONFIG_AOD_ITEM|CLOCKPACK_ITEM|clockpackversion'

echo "DIAG-AOD cwd=$PWD WORKSPACE=${WORKSPACE:-<unset>} script=${BASH_SOURCE[0]:-$0}"

_DIAG_DIRS="$(find "${WORKSPACE:-.}" -type d \( -name 'services.jar_decompiled' -o -name 'framework.jar_decompiled' \) 2>/dev/null | sort || true)"
echo "DIAG-AOD all *_decompiled dirs:"
find "${WORKSPACE:-.}" -type d -name '*_decompiled' 2>/dev/null | sort || true
echo "DIAG-AOD target dirs:"
echo "${_DIAG_DIRS:-<none>}"

for _d in $_DIAG_DIRS; do
    echo "DIAG-AOD ===== START $_d ====="
    echo "DIAG-AOD smali dirs: $(ls -d "$_d"/smali* 2>/dev/null | tr '\n' ' ')"
    _DIAG_FILES="$(grep -rlE "$_DIAG_PAT" --include='*.smali' "$_d" 2>/dev/null | sort || true)"
    echo "DIAG-AOD files with matches:"
    echo "${_DIAG_FILES:-<none>}"
    for _f in $(echo "$_DIAG_FILES" | head -40); do
        echo "DIAG-AOD ----- $_f"
        awk -v pat="$_DIAG_PAT" '
            /^\.method/ { inm=1; n=0; hit=0 }
            inm { n++; L[n]=$0; if ($0 ~ pat) hit=1 }
            /^\.end method/ {
                if (inm && hit) {
                    for (i=1; i<=n && i<=250; i++) print L[i]
                    if (n>250) print "... truncated (" n " lines total)"
                    print ""
                }
                inm=0
            }
        ' "$_f" || true
    done
    echo "DIAG-AOD ===== END $_d ====="
done
true