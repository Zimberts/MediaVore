#!/usr/bin/env bash
# Screenshots of every MediaVore screen, offline, with sample films, plus an
# HTML gallery. See DOCS/screenshots.md.
#
# Usage: tool/screenshots.sh [-l fr|en] [-t light|dark|both] [-o DIR]
set -euo pipefail

cd "$(dirname "$0")/.."

locale=fr
themes=both
out=build/screenshots

while getopts "l:t:o:h" opt; do
  case "$opt" in
    l) locale=$OPTARG ;;
    t) themes=$OPTARG ;;
    o) out=$OPTARG ;;
    *) sed -n '2,6p' "$0"; exit 0 ;;
  esac
done

[[ $themes == both ]] && themes="light dark"

# Isar needs its native library next to the tests (see AGENTS.md).
if ! ls libisar.* >/dev/null 2>&1; then
  lib=$(ls -d "${PUB_CACHE:-$HOME/.pub-cache}"/hosted/pub.dev/isar_community_flutter_libs-* 2>/dev/null | sort -V | tail -1)
  case "$(uname -s)" in
    Darwin) src="$lib/macos/libisar.dylib" ;;
    *) src="$lib/linux/libisar.so" ;;
  esac
  [[ -f $src ]] && cp "$src" .
fi

for theme in $themes; do
  dir="$out/$locale-$theme"
  rm -rf "$dir"
  echo "==> $dir"
  SCREENSHOTS_LOCALE=$locale SCREENSHOTS_THEME=$theme SCREENSHOTS_DIR=$dir \
    flutter test test/screenshots/capture_screens.dart
done

python3 tool/screenshots/build_gallery.py "$out"
echo "Gallery: $out/index.html"
