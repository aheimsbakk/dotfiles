#!/usr/bin/env bash
# bump-version.sh - Bump the project version (patch | minor | major)
#
# Usage: scripts/bump-version.sh [patch|minor|major]

set -euo pipefail

readonly VERSION_FILE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/.version"
readonly BUMP="${1:-patch}"

if [[ ! -f "$VERSION_FILE" ]]; then
  echo "0.0.0" > "$VERSION_FILE"
fi

current="$(cat "$VERSION_FILE")"
major="${current%%.*}"; rest="${current#*.}"
minor="${rest%%.*}"; patch="${rest#*.}"

case "$BUMP" in
  major) major=$((major+1)); minor=0; patch=0 ;;
  minor) minor=$((minor+1)); patch=0 ;;
  patch) patch=$((patch+1)) ;;
  *) echo "error: unknown bump type '$BUMP' (use patch|minor|major)" >&2; exit 1 ;;
esac

new="${major}.${minor}.${patch}"
echo "$new" > "$VERSION_FILE"
echo "$new"
