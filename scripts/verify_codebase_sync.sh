#!/usr/bin/env bash
# verify_codebase_sync.sh - Verify all files referenced in CODEBASE.md exist on disk.
#
# Usage: scripts/verify_codebase_sync.sh
# Exit 0 = all declared paths exist (sync complete).
# Exit 1 = one or more declared paths are missing from disk.

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
readonly CODEBASE="${REPO_ROOT}/CODEBASE.md"

if [[ ! -f "$CODEBASE" ]]; then
	echo "FATAL: ${CODEBASE} not found." >&2
	exit 1
fi

paths=()

# ─── Collect paths ────────────────────────────────────────────────────────

# 1. Extract backtick-delimited text from every line of CODEBASE.md,
#    then filter to only accepted directory prefixes.
while IFS= read -r line; do
	rest="$line"
	while [[ "$rest" == *'`'* ]]; do
		rest="${rest#*\`}"  # skip opening backtick
		text="${rest%%\`*}" # extract until closing backtick
		rest="${rest#*\`}"  # skip closing backtick

		clean=$(printf '%s' "$text" | sed 's/[[:space:]].*$//; s/→.*$//')

		case "$clean" in
		dots/* | dots/) paths+=("$clean") ;;
		snippets/* | snippets/) paths+=("$clean") ;;
		scripts/* | scripts/) paths+=("$clean") ;;
		config/kitty/*) paths+=("dots/$clean") ;;
		config/*) paths+=("$clean") ;;
		esac
	done
done <"$CODEBASE"

# 2. Root-level files referenced in the Markdown (hardcoded so they are always checked)
for candidate in AGENTS.md BLUEPRINT.md CODEBASE.md README.md opencode.json .gitignore .version update.sh; do
	paths+=("$candidate")
done

# ─── De-duplicate ────────────────────────────────────────────────────────

declare -A seen=()
uniq_paths=()
for p in "${paths[@]}"; do
	if [[ ! -v "seen[$p]" ]]; then
		seen["$p"]=1
		uniq_paths+=("$p")
	fi
done

# ─── Verify each path ────────────────────────────────────────────────────

MISSING=()
TOTAL=${#uniq_paths[@]}

for path in "${uniq_paths[@]}"; do
	if [[ -e "${REPO_ROOT}/${path}" ]]; then
		echo "  OK      ${path}"
	else
		MISSING+=("$path")
		echo "  MISSING ${path}  (not found on disk)" >&2
	fi
done

echo ""
echo "Checked ${TOTAL} declared path(s)."
if [[ ${#MISSING[@]} -gt 0 ]]; then
	echo "${#MISSING[@]} missing:" >&2
	for p in "${MISSING[@]}"; do
		echo "  - ${p}" >&2
	done
	exit 1
fi

exit 0
