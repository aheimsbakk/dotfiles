# Changelog

All notable changes to this project are documented in this file. Bump rules:

| Bump | When |
|------|------|
| **patch** | Bug fixes, config tweaks, snippet edits |
| **minor** | New dotfile, new snippet, new installer feature |
| **major** | Breaking change to the installer interface or repo layout |

---

## [0.4.1] - 2026-08-27

- **why:** Simplify opencode configuration by removing subagent agents, switch terminal theme, and disable autoupdate
- **tags:** config, cleanup, theme

### Removed

- `.opencode/agents/architect.md` — system architect subagent
- `.opencode/agents/builder.md` — builder subagent
- `.opencode/agents/brainstorm.md` — brainstorm subagent
- `.opencode/agents/pm.md` — project manager subagent
- `.opencode/agents/qa.md` — qa subagent

### Changed

- Added rule 27 (Intent-Based Commenting) to `.opencode/RULES.md`
- Switched Kitty from Gnome Light to Ayu theme (`dots/config/kitty/`)
- Updated `update.sh` repo reference from `agentic-template` to `agentic-opencode`
- Disabled `autoupdate` in `opencode.json`; commented out MCP config

---

## [0.4.0] - 2026-07-16

### Added
- `scripts/verify_codebase_sync.sh` — validates all file paths referenced in CODEBASE.md exist on disk (exit 0 on success). Parses backtick-delimited paths and checks them against the filesystem.
- Reordered all snippets from repo root into `snippets/` directory for proper organisation.

### Changed
- Restructured repository layout: dotfiles moved to `dots/`, Kitty config to `dots/config/kitty/`, tmux config to `dots/tmux.conf`.
- Reduced CODEBASE.md from 167 lines (box-drawing sections) to ~100 lines (single annotated tree).

### Fixed
- VERSION constant in `update.sh` was out of sync with `.version` and bump-version.sh would never update the script. Extended bump-version.sh to patch `readonly VERSION` via `sed -i` on every bump, so the two sources can never drift again.

---

## [0.3.1] — 2026-03-23

### Changed
- Updated README.md: bash requirement bumped from 4.0 to 5.0.
- Added snippet ordering note to README.md explaining numeric filename prefixes and automatic profile reordering.

---

## [0.3.0] — 2026-03-21

### Added
- `check_requirements()` in update.sh: verifies `curl` and `python3` are installed, prints OS-specific install hints (Homebrew, apt, dnf) on failure. New `-c` / `--check` flag for standalone validation.
- Default powerline-go version pinned to `v1.26`.
- Post-injection sweep in update.sh: automatically removes stale guard blocks from .bashrc / .zshrc when snippets have been deleted from the repo.

### Changed
- Default bash compatibility lowered requirement to 4.0 (for earlier compatibility).

---

## [0.2.0] — 2026-03-21

### Added
- Three-phase installer: dotfiles → snippets → powerline-go binary download.
- Shell snippet injection: files in `snippets/*.bash` injected into `~/.bashrc`, `*.zsh` → `~/.zshrc`, wrapped in unique guard blocks for idempotency.
- Phase 3 — powerline-go download: OS/arch detection, GitHub releases fetch, version-stamp file, configurable via `-V VERSION`.
- Added `.tmux.conf` to managed DOTFILES array.
- README.md with quick start, keybinding references for Kitty/Vim/tmux.

### Fixed
- Help text (`-h`) crashed when a directory had subdirectories due to command substitution with redirect inside a heredoc. Replaced `ls --ignore=*/* --ignore=..` with proper `--format=horizontal -p` rendering (fix: `ls --format=horizontal`, not `ls --ignore=*`).
- JSON parsing from GitHub API fixed by piping response via stdin: `curl ... | python3 -c "..."` instead of embedding in a Python string literal.

### Changed
- Bash compatibility requirement bumped to 5.0 (associative arrays).

---

## [0.1.0] — 2026-03-21

### Added
- `update.sh` — dotfile installer: symlinks `.vimrc`, `.config/kitty/*` from repo into `$HOME`. Idempotent, supports `-d DIR`, dry-run (`-n`), backup-as-`.bak`.
- `BLUEPRINT.md` — repository layout, managed files, Vim/Kitty details, update.sh usage.
- `scripts/bump-version.sh` — semver bumping utility.
- `.version` — version source of truth (0.1.0).
