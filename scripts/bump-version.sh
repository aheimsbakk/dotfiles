#!/usr/bin/env bash
# bump-version.sh - Bump the project version (patch | minor | major)
#
# Updates .version and the VERSION constant in update.sh.
#
# Usage: scripts/bump-version.sh [patch|minor|major]

set -euo pipefail

readonly REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly VERSION_FILE="${REPO_ROOT}/.version"
readonly UPDATE_SH="${REPO_ROOT}/update.sh"
readonly BUMP="${1:-patch}"

if [[ ! -f "$VERSION_FILE" ]]; then
	echo "0.0.0" >"$VERSION_FILE"
fi

current="$(cat "$VERSION_FILE")"
major="${current%%.*}"
rest="${current#*.}"
minor="${rest%%.*}"
patch="${rest#*.}"

case "$BUMP" in
major)
	major=$((major + 1))
	minor=0
	patch=0
	;;
minor)
	minor=$((minor + 1))
	patch=0
	;;
patch) patch=$((patch + 1)) ;;
*)
	echo "error: unknown bump type '$BUMP' (use patch|minor|major)" >&2
	exit 1
	;;
esac

new="${major}.${minor}.${patch}"
echo "$new" >"$VERSION_FILE"

# Keep update.sh VERSION constant in sync
if [[ -f "$UPDATE_SH" ]]; then
	sed -i "s/^readonly VERSION=\"[^\"]*\"/readonly VERSION=\"${new}\"/" "$UPDATE_SH"
fi

echo "$new"
