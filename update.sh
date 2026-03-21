#!/usr/bin/env bash
# update.sh - Install dotfiles, shell snippets, and tools from this repository.
#
# - Symlinks dotfiles into TARGET_DIR (default: $HOME)
# - Injects shell snippets from snippets/ into the appropriate shell profile
# - Downloads powerline-go binary for the current OS/arch into ~/.local/bin
#
# The repository must already be checked out manually. Only powerline-go is
# downloaded from the internet; everything else is sourced from the repo.
#
# Usage:
#   ./update.sh [-b] [-d DIR] [-n] [-V VERSION] [-h] [-v]

set -euo pipefail

readonly VERSION="2.0.0"
readonly SCRIPT_NAME="$(basename "$0")"
# Absolute path to the directory that contains this script (the repo root).
readonly REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ─── Configurable dotfile map ─────────────────────────────────────────────────
#
# Each entry is "REPO_RELATIVE_PATH:TARGET_RELATIVE_PATH".
# Glob patterns in REPO_RELATIVE_PATH are expanded against the repository.
# TARGET_RELATIVE_PATH is relative to TARGET_DIR (default: $HOME).
#
# Rules:
#   - Only files are linked; directories are never linked directly.
#   - Glob '*' in the target is replaced with the matched filename from source.
#   - Missing parent directories in TARGET_DIR are created automatically.

DOTFILES=(
	".vimrc:.vimrc"
	".config/kitty/*:.config/kitty/*"
	".tmux.conf:.tmux.conf"
)

# ─── Shell profile map ────────────────────────────────────────────────────────
#
# Maps snippet file extension → profile file (relative to TARGET_DIR).
# Snippets in snippets/ are named <anything>.<shell-ext> and are sourced into
# the matching profile via a guarded include block.

declare -A SHELL_PROFILES=(
	[bash]=".bashrc"
	[zsh]=".zshrc"
)

# ─── powerline-go install path ────────────────────────────────────────────────
#
# Relative to TARGET_DIR. The binary is placed here and made executable.

readonly POWERLINE_GO_INSTALL_DIR=".local/bin"
readonly POWERLINE_GO_BINARY="powerline-go"
readonly POWERLINE_GO_REPO="justjanne/powerline-go"
readonly GITHUB_API="https://api.github.com/repos/${POWERLINE_GO_REPO}"
readonly GITHUB_RELEASES="https://github.com/${POWERLINE_GO_REPO}/releases/download"

# ─── Helpers ──────────────────────────────────────────────────────────────────

usage() {
	cat <<EOF
Usage: ${SCRIPT_NAME} [OPTIONS]

Install dotfiles, shell snippets, and powerline-go from this repository.

Options:
  -b            Back up existing regular files as <file>.bak before replacing
  -d DIR        Target directory (default: \$HOME)
  -n            Dry-run: show what would be done without making changes
  -V VERSION    powerline-go version to install (default: latest, e.g. v1.26)
  -h, --help    Show this help message and exit
  -v, --version Show script version and exit

Dotfiles managed:
EOF
	for entry in "${DOTFILES[@]}"; do
		echo "  ${entry%%:*}  →  ${entry##*:}"
	done
	echo ""
	echo "Snippets injected:"
	local f ext profile
	for f in "${REPO_DIR}/snippets/"*.*; do
		[[ -f "$f" ]] || continue
		ext="${f##*.}"
		profile="${SHELL_PROFILES[$ext]:-}"
		[[ -n "$profile" ]] && echo "  $(basename "$f")  →  ${profile}"
	done
}

version() {
	echo "${SCRIPT_NAME} ${VERSION}"
}

die() {
	echo "error: $*" >&2
	exit 1
}

# Print a status line: LABEL  message
status() {
	local label="$1"
	local msg="$2"
	printf "  %-10s %s\n" "${label}" "${msg}"
}

# Detect OS slug as used in powerline-go release asset names (linux/darwin/…)
detect_os() {
	local raw
	raw="$(uname -s | tr '[:upper:]' '[:lower:]')"
	echo "$raw"
}

# Detect arch slug as used in powerline-go release asset names
detect_arch() {
	local raw
	raw="$(uname -m)"
	case "$raw" in
	x86_64) echo "amd64" ;;
	aarch64 | arm64) echo "arm64" ;;
	armv7l | armv6l) echo "arm" ;;
	i386 | i686) echo "386" ;;
	*) echo "$raw" ;;
	esac
}

# Resolve the latest powerline-go tag from the GitHub API
resolve_latest_version() {
	local response
	response="$(curl -fsSL "${GITHUB_API}/releases/latest" 2>/dev/null)" ||
		die "failed to fetch latest powerline-go release from GitHub"
	printf '%s' "${response}" | python3 -c "import sys,json; print(json.load(sys.stdin)['tag_name'])"
}

# ─── Argument parsing ─────────────────────────────────────────────────────────

TARGET_DIR="${HOME}"
DRY_RUN=0
BACKUP=0
POWERLINE_VERSION="" # empty = resolve latest at runtime

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
	-b)
		BACKUP=1
		shift
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
	-V)
		[[ $# -gt 1 ]] || die "option -V requires an argument"
		POWERLINE_VERSION="$2"
		shift 2
		;;
	-V*)
		POWERLINE_VERSION="${1#-V}"
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

# ─── Core: dotfile symlinking ─────────────────────────────────────────────────

# link_file SRC DEST
#   Creates a symlink at DEST pointing to SRC.
#   - Creates missing parent directories.
#   - Skips existing regular files unless -b is given (backs up as <file>.bak).
#   - Replaces stale or wrong symlinks.
#   - No-op if the correct symlink already exists.
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

	# Existing regular file → back up or skip
	if [[ -f "$dest" && ! -L "$dest" ]]; then
		if [[ "$BACKUP" == "1" ]]; then
			if [[ "$DRY_RUN" == "1" ]]; then
				status "BACKUP" "${dest}  →  ${dest}.bak"
			else
				mv "$dest" "${dest}.bak"
				status "BACKUP" "${dest}  →  ${dest}.bak"
			fi
		else
			status "SKIP" "${dest}  (regular file exists; use -b to back up)"
			return
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

# ─── Core: snippet injection ──────────────────────────────────────────────────

# inject_snippet SNIPPET_FILE PROFILE_FILE
#   Appends a guarded source block to PROFILE_FILE if not already present.
#   Guard tag is based on the snippet filename so it is unique and idempotent.
#   Creates PROFILE_FILE if it does not exist.
inject_snippet() {
	local snippet="$1" # absolute path to snippet file in repo
	local profile="$2" # absolute path to target profile file
	local name
	name="$(basename "$snippet")"
	local guard="# >>> dotfiles:${name} >>>"
	local guard_end="# <<< dotfiles:${name} <<<"
	local profile_parent
	profile_parent="$(dirname "$profile")"

	# Create parent directory if needed
	if [[ ! -d "$profile_parent" ]]; then
		if [[ "$DRY_RUN" == "1" ]]; then
			status "MKDIR" "${profile_parent}"
		else
			mkdir -p "$profile_parent"
			status "MKDIR" "${profile_parent}"
		fi
	fi

	# Create profile file if it does not exist
	if [[ ! -f "$profile" ]]; then
		if [[ "$DRY_RUN" == "1" ]]; then
			status "CREATE" "${profile}  (new profile file)"
		else
			touch "$profile"
			status "CREATE" "${profile}  (new profile file)"
		fi
	fi

	# Already injected → idempotent skip
	if grep -qF "$guard" "$profile" 2>/dev/null; then
		status "OK" "${profile}  (${name} already present)"
		return
	fi

	if [[ "$DRY_RUN" == "1" ]]; then
		status "INJECT" "${profile}  ←  ${name}"
	else
		{
			printf '\n%s\n' "$guard"
			printf 'source "%s"\n' "$snippet"
			printf '%s\n' "$guard_end"
		} >>"$profile"
		status "INJECT" "${profile}  ←  ${name}"
	fi
}

# ─── Core: powerline-go download ─────────────────────────────────────────────

install_powerline_go() {
	local plgo_version="$1"
	local os arch asset_name url dest_dir dest tmp

	os="$(detect_os)"
	arch="$(detect_arch)"
	asset_name="powerline-go-${os}-${arch}"
	url="${GITHUB_RELEASES}/${plgo_version}/${asset_name}"
	dest_dir="${TARGET_DIR}/${POWERLINE_GO_INSTALL_DIR}"
	dest="${dest_dir}/${POWERLINE_GO_BINARY}"

	echo ""
	echo "── powerline-go ──────────────────────────────────────────────────────────────"
	echo "  Version    : ${plgo_version}"
	echo "  Asset      : ${asset_name}"
	echo "  Destination: ${dest}"
	echo ""

	# Check if already up to date by reading a version stamp file
	local stamp="${dest_dir}/.powerline-go-version"
	if [[ -f "$stamp" && "$(cat "$stamp")" == "$plgo_version" && -x "$dest" ]]; then
		status "OK" "${dest}  (${plgo_version} already installed)"
		return
	fi

	if [[ "$DRY_RUN" == "1" ]]; then
		status "DOWNLOAD" "${url}"
		status "INSTALL" "${dest}"
		return
	fi

	# Create install dir
	if [[ ! -d "$dest_dir" ]]; then
		mkdir -p "$dest_dir"
		status "MKDIR" "${dest_dir}"
	fi

	tmp="$(mktemp)"
	# shellcheck disable=SC2064
	trap "rm -f '${tmp}'" RETURN

	if ! curl -fsSL -o "$tmp" "$url" 2>/dev/null; then
		die "failed to download ${url} — check OS/arch or version tag"
	fi

	cp "$tmp" "$dest"
	chmod +x "$dest"
	echo "$plgo_version" >"$stamp"
	status "INSTALLED" "${dest}  (${plgo_version})"
}

# ─── Main ─────────────────────────────────────────────────────────────────────

echo "Repo       : ${REPO_DIR}"
echo "Target dir : ${TARGET_DIR}"
[[ "$DRY_RUN" == "1" ]] && echo "Mode       : dry-run (no changes will be made)"
[[ "$BACKUP" == "1" ]] && echo "Backup     : enabled (existing files saved as .bak)"
echo ""

# ── 1. Dotfiles ───────────────────────────────────────────────────────────────

echo "── dotfiles ──────────────────────────────────────────────────────────────────"
echo ""

linked=0
skipped=0

for entry in "${DOTFILES[@]}"; do
	repo_pattern="${entry%%:*}"
	dest_pattern="${entry##*:}"

	# Expand glob against the repository.
	shopt -s nullglob
	mapfile -t matches < <(cd "$REPO_DIR" && printf '%s\n' ${repo_pattern})
	shopt -u nullglob
	matches=("${matches[@]/#/"${REPO_DIR}/"}")

	if [[ ${#matches[@]} -eq 0 ]]; then
		status "MISSING" "${repo_pattern}  (no files matched in repo)"
		((skipped++)) || true
		continue
	fi

	for src in "${matches[@]}"; do
		[[ -f "$src" ]] || continue

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
echo "  ${linked} file(s) linked, ${skipped} pattern(s) skipped."

# ── 2. Shell snippets ─────────────────────────────────────────────────────────

echo ""
echo "── snippets ──────────────────────────────────────────────────────────────────"
echo ""

shopt -s nullglob
snippet_files=("${REPO_DIR}/snippets/"*.*)
shopt -u nullglob

injected=0
snippet_skipped=0

for snippet in "${snippet_files[@]}"; do
	[[ -f "$snippet" ]] || continue
	ext="${snippet##*.}"
	profile_rel="${SHELL_PROFILES[$ext]:-}"

	if [[ -z "$profile_rel" ]]; then
		status "SKIP" "$(basename "$snippet")  (no profile mapping for .${ext})"
		((snippet_skipped++)) || true
		continue
	fi

	profile="${TARGET_DIR}/${profile_rel}"
	inject_snippet "$snippet" "$profile"
	((injected++)) || true
done

echo ""
echo "  ${injected} snippet(s) processed, ${snippet_skipped} skipped."

# ── 3. powerline-go ───────────────────────────────────────────────────────────

if [[ -z "$POWERLINE_VERSION" ]]; then
	echo ""
	echo "── resolving latest powerline-go version ─────────────────────────────────────"
	POWERLINE_VERSION="$(resolve_latest_version)"
	echo "  Latest: ${POWERLINE_VERSION}"
fi

install_powerline_go "$POWERLINE_VERSION"

echo ""
echo "Done."
