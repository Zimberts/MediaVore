#!/usr/bin/env bash
# Fails if an Android release artifact is not compatible with 16 KB memory pages
# (Android 15+ devices, required by Google Play for new uploads).
#
#   tool/check_16kb_alignment.sh path/to/app-release.apk|app-release.aab
#
# Two independent conditions, as in Android's `check_elf_alignment.sh`:
# 1. ELF: every LOAD segment of each 64-bit native library (arm64-v8a, x86_64) has
#    p_align >= 16384. 32-bit ABIs are skipped: 16 KB pages only exist on 64-bit devices.
# 2. ZIP (APK only): uncompressed native libraries start on a 16 KB boundary in the APK,
#    checked with `zipalign -c -P 16` (build-tools >= 35). An AAB is not installed as is:
#    Play builds the APKs, so only the ELF check applies to it.
#
# zipalign is taken from $ZIPALIGN, else from the newest $ANDROID_HOME/build-tools/*.
set -euo pipefail

artifact="${1:?usage: $0 <app.apk|app.aab>}"
min_align=16384

case "$artifact" in
  *.apk) lib_prefix="lib" ;;
  *.aab) lib_prefix="base/lib" ;;
  *)
    echo "::error::$artifact: expected an .apk or .aab file."
    exit 1
    ;;
esac
[[ -f $artifact ]] || { echo "::error::$artifact: file not found."; exit 1; }

failed=0

# --- 1. ELF segment alignment -------------------------------------------------------------
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
# unzip exits 11 when no entry matches: handled below by the "no library" check.
unzip -qo "$artifact" "$lib_prefix/arm64-v8a/*.so" "$lib_prefix/x86_64/*.so" -d "$tmp" || [[ $? -eq 11 ]]

checked=0
while IFS= read -r -d '' so; do
  rel="${so#"$tmp"/}"
  aligns=$(readelf -lW "$so" | awk '$1 == "LOAD" { print $NF }')
  if [[ -z $aligns ]]; then
    echo "::error::$rel: no LOAD segment found (not an ELF shared library?)."
    failed=1
    continue
  fi
  bad=""
  for a in $aligns; do
    (( a >= min_align )) || bad+=" $a"
  done
  if [[ -n $bad ]]; then
    echo "::error::$rel: LOAD segment alignment$bad < 0x4000 (16 KB)."
    failed=1
  else
    echo "OK   $rel"
  fi
  checked=$((checked + 1))
done < <(find "$tmp" -name '*.so' -print0 | sort -z)

# A Flutter app always ships libflutter.so and libapp.so: finding none means the check ran
# on the wrong layout, not that the artifact is fine.
if (( checked == 0 )); then
  echo "::error::$artifact: no 64-bit native library under $lib_prefix/{arm64-v8a,x86_64}/."
  failed=1
fi

# --- 2. ZIP alignment of uncompressed libraries (APK only) ---------------------------------
if [[ $artifact == *.apk ]]; then
  zipalign="${ZIPALIGN:-}"
  if [[ -z $zipalign ]]; then
    build_tools=$(find "${ANDROID_HOME:?ANDROID_HOME is not set (or set ZIPALIGN)}/build-tools" \
      -mindepth 1 -maxdepth 1 -type d | sort -V | tail -n 1)
    zipalign="$build_tools/zipalign"
  fi
  if [[ ! -x $zipalign ]]; then
    echo "::error::zipalign not found ($zipalign)."
    failed=1
  elif "$zipalign" -c -P 16 -v 4 "$artifact" > "$tmp/zipalign.log" 2>&1; then
    echo "OK   zipalign -c -P 16 ($zipalign)"
  else
    grep -E 'BAD|Verification|Unknown|usage' "$tmp/zipalign.log" || tail -n 20 "$tmp/zipalign.log"
    echo "::error::$artifact: zipalign -c -P 16 failed (needs build-tools >= 35 for -P)."
    failed=1
  fi
fi

if (( failed )); then
  echo "$artifact is NOT 16 KB page-size compatible."
  exit 1
fi
echo "$artifact: $checked 64-bit native libraries, all 16 KB aligned."
