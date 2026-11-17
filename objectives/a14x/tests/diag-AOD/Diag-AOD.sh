# Diag-AOD.sh - TEMPORARY, READ-ONLY. Delete after the log has been read.
# Sourced by apktool.sh with cwd = <jar>_decompiled, before the jar is rebuilt.
# Prints every smali method that mentions the AOD / clockpack feature keys.
# Search the CI log for "DIAG-AOD".

_DIAG_JAR="$(basename "$PWD")"
_DIAG_PAT='aodversion|FRAMEWORK_CONFIG_AOD_ITEM|CLOCKPACK_ITEM|clockpackversion'

echo "DIAG-AOD ===== START $_DIAG_JAR ====="
echo "DIAG-AOD smali dirs: $(ls -d smali* 2>/dev/null | tr '\n' ' ')"

_DIAG_FILES="$(grep -rlE "$_DIAG_PAT" --include='*.smali' . 2>/dev/null | sort || true)"
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

echo "DIAG-AOD ===== END $_DIAG_JAR ====="
true
