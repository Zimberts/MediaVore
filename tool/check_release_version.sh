#!/usr/bin/env bash
# Fails if the version in pubspec.yaml does not match a release tag.
#
#   tool/check_release_version.sh v1.2.0 [path/to/pubspec.yaml]
#
# `version: 1.2.0+7` matches `v1.2.0`: the build number (+N) is ignored, CI sets it
# with --build-number (see DOCS/releasing.md).
set -euo pipefail

tag="${1:?usage: $0 <tag vX.Y.Z> [pubspec.yaml]}"
pubspec="${2:-pubspec.yaml}"

if [[ ! $tag =~ ^v([0-9]+\.[0-9]+\.[0-9]+)$ ]]; then
  echo "::error::Tag '$tag' is not of the form vX.Y.Z."
  exit 1
fi
tag_version="${BASH_REMATCH[1]}"

line=$(grep -E '^version:' "$pubspec" || true)
if [[ ! $line =~ ^version:[[:space:]]*([0-9]+\.[0-9]+\.[0-9]+)(\+[0-9]+)?[[:space:]]*$ ]]; then
  echo "::error file=$pubspec::No 'version: X.Y.Z[+N]' line found (got '$line')."
  exit 1
fi
pubspec_version="${BASH_REMATCH[1]}"

if [[ $pubspec_version != "$tag_version" ]]; then
  echo "::error file=$pubspec::pubspec.yaml version $pubspec_version does not match tag $tag."
  exit 1
fi
echo "pubspec.yaml version $pubspec_version matches tag $tag."
