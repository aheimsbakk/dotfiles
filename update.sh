#!/usr/bin/env bash
# update.sh - Symlink dotfiles from this repository into the home directory
#             (or a specified target directory).
#
# The repository must already be checked out manually. This script never
# downloads anything from the internet.
#
# Usage:
#   ./update.sh [-d DIR] [-n] [-h] [-v]

set -euo pipefail

readonly VERSION="1.0.0"
readonly SCRIPT_NAME="$(basename "$0")"
# Absolute path to the directory that contains this script (the repo root).
readonly REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ─── Configurable dotfile map ─────────────────────────────────────────────────
#
# Each entry is "REPO_RELATIVE_PATH:TARGET_RELATIVE_PATH".
# Glob patterns in REPO_RELATIVE_PATH are expanded against the repository.
# TARGET_RELATIVE_PATH is relative to TARGET_DIR (default: $HOME).
#
# Examples:
#   ".vimrc:.vimrc"                        plain file → plain file
#   ".config/kitty/*:.config/kitty/*"     glob → same relative layout
#
# Rules:
#   - Only files are linked; directories are never linked directly.
#   - If the target glob contains a '*', it is replaced with the matched
#     filename component from the source glob.
#   - Missing parent directories in TARGET_DIR are created automatically.

DOTFILES=(
	".vimrc:.vimrc"
	".config/kitty/*:.config/kitty/*"
)

# ─── Helpers ──────────────────────────────────────────────────────────────────

usage() {
	cat <<EOF
Usage: ${SCRIPT_NAME} [OPTIONS]

Symlink dotfiles from this repository into TARGET_DIR.

Options:
  -d DIR        Target directory (default: \$HOME)
  -n            Dry-run: show what would be done without making changes
  -h, --help    Show this help message and exit
  -v, --version Show version and exit

Dotfiles managed:
$(for entry in "${DOTFILES[@]}"; do echo "  ${entry%%:*}  →  ${entry##*:}"; done)
EOF
}

version() {
	echo "${SCRIPT_NAME} ${VERSION}"
}

die() {
	echo "error: $*" >&2
	exit 1
}

# Print a status line: STATUS  path
status() {
	local label="$1"
	local path="$2"
	printf "  %-10s %s\n" "${label}" "${path}"
}

# ─── Argument parsing ─────────────────────────────────────────────────────────

TARGET_DIR="${HOME}"
DRY_RUN=0

while [[ $# -gt 0 ]]; do
	case "$1" in
	-h | --help)
		usage
		exit 0
		;;
	-v | --version)
		version
		exit 0
		;;
	-n)
		DRY_RUN=1
		shift
		;;
	-d)
		[[ $# -gt 1 ]] || die "option -d requires an argument"
		TARGET_DIR="$2"
		shift 2
		;;
	-d*)
		TARGET_DIR="${1#-d}"
		shift
		;;
	-*)
		die "unknown option: $1 (try --help)"
		;;
	*)
		die "unexpected argument: $1 (try --help)"
		;;
	esac
done

# ─── Validation ───────────────────────────────────────────────────────────────

TARGET_DIR="$(realpath -m "$TARGET_DIR")"
[[ -d "$TARGET_DIR" ]] || die "target directory does not exist: ${TARGET_DIR}"

# ─── Core logic ───────────────────────────────────────────────────────────────

# link_file SRC DEST
#   Creates a symlink at DEST pointing to SRC.
#   - Creates missing parent directories.
#   - Backs up existing regular files as <file>.bak.
#   - Replaces stale or wrong symlinks.
#   - Skips if the correct symlink already exists.
link_file() {
	local src="$1"
	local dest="$2"
	local dest_parent
	dest_parent="$(dirname "$dest")"

	# Create parent directory if needed
	if [[ ! -d "$dest_parent" ]]; then
		if [[ "$DRY_RUN" == "1" ]]; then
			status "MKDIR" "${dest_parent}"
		else
			mkdir -p "$dest_parent"
			status "MKDIR" "${dest_parent}"
		fi
	fi

	# Already the correct symlink → nothing to do
	if [[ -L "$dest" && "$(readlink "$dest")" == "$src" ]]; then
		status "OK" "${dest}"
		return
	fi

	# Existing regular file → back it up
	if [[ -f "$dest" && ! -L "$dest" ]]; then
		if [[ "$DRY_RUN" == "1" ]]; then
			status "BACKUP" "${dest}  →  ${dest}.bak"
		else
			mv "$dest" "${dest}.bak"
			status "BACKUP" "${dest}  →  ${dest}.bak"
		fi
	fi

	# Stale or wrong symlink → remove it
	if [[ -L "$dest" ]]; then
		if [[ "$DRY_RUN" == "1" ]]; then
			status "UNLINK" "${dest}"
		else
			rm "$dest"
			status "UNLINK" "${dest}"
		fi
	fi

	# Create the symlink
	if [[ "$DRY_RUN" == "1" ]]; then
		status "LINK" "${dest}  →  ${src}"
	else
		ln -s "$src" "$dest"
		status "LINK" "${dest}  →  ${src}"
	fi
}

# ─── Main ─────────────────────────────────────────────────────────────────────

echo "Repo       : ${REPO_DIR}"
echo "Target dir : ${TARGET_DIR}"
[[ "$DRY_RUN" == "1" ]] && echo "Mode       : dry-run (no changes will be made)"
echo ""

linked=0
skipped=0

for entry in "${DOTFILES[@]}"; do
	repo_pattern="${entry%%:*}"
	dest_pattern="${entry##*:}"

	# Expand glob against the repository.
	# We must cd into REPO_DIR so that the unquoted glob pattern expands
	# correctly against the filesystem (quoting the full path prevents expansion).
	shopt -s nullglob
	mapfile -t matches < <(cd "$REPO_DIR" && printf '%s\n' ${repo_pattern})
	shopt -u nullglob
	# Prepend REPO_DIR to turn relative paths into absolute paths
	matches=("${matches[@]/#/"${REPO_DIR}/"}")

	if [[ ${#matches[@]} -eq 0 ]]; then
		status "MISSING" "${repo_pattern}  (no files matched in repo)"
		((skipped++)) || true
		continue
	fi

	for src in "${matches[@]}"; do
		# Only link files, never directories
		[[ -f "$src" ]] || continue

		# Derive the relative source path (strip repo prefix + slash)
		local_rel="${src#"${REPO_DIR}/"}"

		# Build the destination path:
		# If dest_pattern contains a glob '*', replace it with the filename
		# component of the matched source file.
		if [[ "$dest_pattern" == *"*"* ]]; then
			dest_rel="${dest_pattern/\*/"$(basename "$src")"}"
		else
			dest_rel="$dest_pattern"
		fi

		dest="${TARGET_DIR}/${dest_rel}"
		link_file "$src" "$dest"
		((linked++)) || true
	done
done

echo ""
echo "Done. ${linked} file(s) processed, ${skipped} pattern(s) skipped."
