#!/usr/bin/env bash
# validate-changelog.sh - Verify the structure of CHANGELOG.md
#
# Checks that every "## [x.y.z]" version entry has a date and at least one
# category heading (### Added/Changed/...), and that the topmost version
# matches the version in .version. Does not modify anything.
#
# Usage: scripts/validate-changelog.sh
# Exit 0 = changelog structure is valid.
# Exit 1 = a structural problem was found.

set -euo pipefail

readonly REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly CHANGELOG="${REPO_ROOT}/CHANGELOG.md"

if [[ ! -f "$CHANGELOG" ]]; then
	echo "FATAL: ${CHANGELOG} not found." >&2
	exit 1
fi

errors=0

# Track per-version block state.
version=""
has_date=0
has_category=0

finish_block() {
	if [[ -n "$version" ]]; then
		if [[ "$has_date" -eq 0 ]]; then
			echo "error: entry [${version}] has no date line" >&2
			errors=$((errors + 1))
		fi
		if [[ "$has_category" -eq 0 ]]; then
			echo "error: entry [${version}] has no category heading (### Fixed/Added/...)" >&2
			errors=$((errors + 1))
		fi
	fi
	version=""
	has_date=0
	has_category=0
}

# Read line by line.
while IFS= read -r line; do
	# A separator closes the current version block.
	if [[ "$line" == "---" ]]; then
		finish_block
		continue
	fi

	# A new version heading closes the previous block (if any).
	# The date may be inline on the heading line ("## [1.2.3] - 2026-01-01")
	# or on a following line, so capture it here for the inline case.
	if [[ "$line" =~ ^##\ \[([0-9]+\.[0-9]+\.[0-9]+)\] ]]; then
		finish_block
		version="${BASH_REMATCH[1]}"
		if [[ "$line" =~ ([0-9]{4}-[0-9]{2}-[0-9]{2}) ]]; then
			has_date=1
		fi
		continue
	fi

	if [[ -z "$version" ]]; then
		continue
	fi

	# Metadata bullet (e.g. "- **reason:** ..." or "- **why:** ...").
	if [[ "$line" =~ ^-\ \*\*[a-z]+:\*\* ]]; then
		continue
	fi

	# Date line (- YYYY-MM-DD).
	if [[ "$line" =~ ^-?\ *([0-9]{4}-[0-9]{2}-[0-9]{2}) ]]; then
		has_date=1
		continue
	fi

	# Any category heading under the version block.
	if [[ "$line" == "### "* ]]; then
		has_category=1
	fi
done <"$CHANGELOG"

# Close the trailing block.
finish_block

# Verify the topmost version heading matches .version.
current="$(cat "${REPO_ROOT}/.version")"
top_version="$(grep -m1 '^## \[' "$CHANGELOG" | sed -E 's/^## \[([0-9.]+)\].*/\1/')"

if [[ "$top_version" != "$current" ]]; then
	echo "error: top changelog entry [${top_version}] differs from .version (${current})" >&2
	errors=$((errors + 1))
fi

if [[ "$errors" -gt 0 ]]; then
	echo "" >&2
	echo "Changelog validation failed with ${errors} problem(s)." >&2
	exit 1
fi

echo "Changelog OK (latest ${current})."
exit 0
