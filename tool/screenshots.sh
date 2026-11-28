#!/usr/bin/env bash
# Captures MediaVore's key screenshots offline using FakeTmdb and the real app
# test harness, writing PNGs to DOCS/screenshots/ by default.
#
# Usage: tool/screenshots.sh [-l en|fr] [-t light|dark] [-o DIR]
set -euo pipefail

cd "$(dirname "$0")/.."

locale=en
theme=light
out=DOCS/screenshots

while getopts "l:t:o:h" opt; do
  case "$opt" in
    l) locale=$OPTARG ;;
    t) theme=$OPTARG ;;
    o) out=$OPTARG ;;
    *) sed -n '2,5p' "$0"; exit 0 ;;
  esac
done

# Ensure the bundled .env asset exists (gitignored, required by pubspec.yaml).
[[ -f .env ]] || touch .env

# Isar needs its native library next to the tests (see AGENTS.md).
if ! ls libisar.* >/dev/null 2>&1; then
  lib=$(ls -d "${PUB_CACHE:-$HOME/.pub-cache}"/hosted/pub.dev/isar_community_flutter_libs-* 2>/dev/null | sort -V | tail -1 || true)
  if [[ -n "$lib" ]]; then
    case "$(uname -s)" in
      Darwin) src="$lib/macos/libisar.dylib" ;;
      *) src="$lib/linux/libisar.so" ;;
    esac
    [[ -f "$src" ]] && cp "$src" .
  fi
fi

mkdir -p "$out"
echo "==> Generating screenshots ($locale, $theme) -> $out"
SCREENSHOTS_LOCALE="$locale" SCREENSHOTS_THEME="$theme" SCREENSHOTS_DIR="$out" \
  flutter test test/screenshots/capture_screens.dart
echo "Done: $out"
