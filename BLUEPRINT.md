# BLUEPRINT — dotfiles

## Purpose

A personal dotfiles repository. Configuration files are version-controlled inside the `dots/` directory and symlinked into the user's home directory by `update.sh`. No package manager, no framework — just bash and symlinks.

---

## System Goals

1. **Centralised configuration** — all dotfile sources live in a single git repository.
2. **Idempotent installation** — `update.sh` is safe to re-run; it only creates what has changed.
3. **Snippet guard blocks** — shell snippets are injected into user profiles using unique delimiter markers, preventing duplicates and enabling automatic stale-block cleanup.
4. **Cross-platform portability** — dotfiles and scripts work on both Linux (Wayland) and macOS.

---

## Component Hierarchy

```
┌─────────────────────┐   ┌─────────────────┐   ┌──────────────────┐
│  update.sh          │──▶│ Phase 1:        │──▶│ Symlink engine   │
│  (bash ≥ 5.0)       │   │ dotfile linking  │   │ link_file()      │
├─────────────────────┤   ├─────────────────┤   ├──────────────────┤
│  .version           │   │ Phase 2:        │──▶│ Snippet engine    │
│  scripts/           │   │ snippet injection│   │ inject_snippet() │
│  bump-version.sh    │   │                 │   │ purge_snippet()  │
├─────────────────────┤   │ Phase 3:        │──▶│ Binary downloader │
│  opencode.json      │   │ powerline-go    │   │ install_powerline│
│  RULES.md, AGENTS.md│   │ download         │   │ _go()            │
├─────────────────────┤   └─────────────────┘   └──────────────────┘
│  dots/              │                          ┌──────────────────┐
│    vimrc            │──▶ target: ~/.vimrc      │ dotfiles state   │
│    tmux.conf        │──▶ target: ~/.tmux.conf │ tree (symlinked  │
│    config/kitty/*  │──▶ target: ~/.config/... │  files read each │
├─────────────────────┤                          └──────────────────┘
│  snippets/          │
│    *.bash           │──▶ target: ~/.bashrc      ┌──────────────────┐
└─────────────────────┘                           │ profile state    │
                                                  │ (modified by     │
                                                  │  inject_snippet) │
                                                  └──────────────────┘
```

---

## Data Flow

```
User runs: ./update.sh [-b] [-c] [-d DIR] [-n] [-V VERSION] [-h] [-v]
        │
        ▼
  check_requirements()
        │
    ┌───┴───┐
    │  curl  │   python3   (both required)
    └───┬───┘
        │   OK → continue; FAIL → print OS-specific install hints → exit 1
        ▼
  resolve CLI arguments → set TARGET_DIR, DRY_RUN, BACKUP flags
        │
        ▼
  Phase 1 — Dotfile symlinking
    For each DOTFILES entry ("REPO:TARGET"):
      - Expand glob against dots/ directory
      - For every matched file: link_file(src, dest)
          - Create parent dir if missing (MKDIR)
          - Skip or backup existing regular file (SKIP / BACKUP)
          - Remove stale/wrong symlink if present (UNLINK)
          - Create the correct symlink (LINK) or report no-op (OK)
        │
        ▼
  Phase 2 — Shell snippet injection
    Collect all files from snippets/*. sorted lexicographically.
    For each snippet:
      - Determine shell extension (.bash, .zsh)
      - Map to profile file via SHELL_PROFILES associative array
      - inject_snippet(snippet_path, profile_path)
          - If guard block absent → append guarded source line (INJECT)
          - If guard block present but stale path → update in-place (RELOCATE)
          - If guard block present and current → no-op (OK)
    After injection:
      - reorder_snippets() — purge and re-inject all blocks in sorted order if misaligned
      - Clean up orphan guards — remove blocks whose snippet file has been deleted from repo
        │
        ▼
  Phase 3 — powerline-go binary download
    detect_os() + detect_arch() → asset name (e.g. "powerline-go-linux-amd64")
    Check .local/bin/.powerline-go-version stamp against requested version
      - If match and binary is executable → no-op (OK)
      - Otherwise → curl from GitHub releases, place to ~/.local/bin/powerline-go, write stamp
        │
        ▼
  "Done."
```

---

## State Management

### Symlink state (Phase 1)

| Status | Meaning | Action if re-run |
|---|---|---|
| `OK` | Symlink points to exact repo source path | No-op |
| `LINK` | New symlink created | Becomes `OK` next run |
| `SKIP` | Regular file exists at destination, `-b` not given | Remains `SKIP` until backed up and re-run |
| `BACKUP` | Existing file moved to `.bak` | Followed by `LINK` |
| `UNLINK` | Stale symlink removed (followed by new LINK) | Becomes `OK` on next run |

### Snippet state (Phase 2)

Guard block format in profile files:
```bash
# >>> dotfiles:<filename> >>>
source "/absolute/path/to/repo/snippets/<filename>"
# <<< dotfiles:<filename> <<<
```

| State | Meaning | Resolved by |
|---|---|---|
| Present, path current | Guard and source line both match repo location | `OK` — no-op |
| Present, path stale | Guard present but `source` path points to old `REPO_DIR` | `RELOCATE` — rewritten in-place |
| Absent (file exists) | Snippet file is in repo but no guard in profile | `CREATE` + `INJECT` |
| Absent (file deleted) | Guard exists but snippet file no longer in `snippets/` | `PURGED` by stale-cleanup pass |

Snippet order is determined by lexicographic filename sort. Numeric prefixes (`00-`, `10-`, `90-`) define chronological load order. The `reorder_snippets()` function detects out-of-order blocks and purges + re-injects them in the correct sequence.

### powerline-go state (Phase 3)

A version-stamp file `~/.local/bin/.powerline-go-version` stores the last installed version tag. Re-running with the same `-V VERSION` value is a no-op if the binary already exists and matches.

---

## Contracts

### Entry point

`update.sh` at repository root. Must be run from anywhere — it resolves its own location via `BASH_SOURCE[0]`. Defaults to installing into `$HOME`.

### CLI interface

| Flag | Effect |
|---|---|
| `-b` | Back up existing regular files as `<file>.bak` before replacing |
| `-c`, `--check` | Check requirements only; print install hints and exit |
| `-d DIR` | Install into `DIR` instead of `$HOME` |
| `-n` | Dry-run: print actions without making changes |
| `-V VERSION` | powerline-go version to install (default: `v1.26`) |
| `-h`, `--help` | Show help with managed dotfiles and snippets list, then exit |
| `-v`, `--version` | Print script version and exit |

### Error boundaries

- **Missing requirements**: `check_requirements()` exits with code 1 after printing OS-specific install instructions.
- **Unknown flags / unexpected args**: `die()` prints the message to stderr and exits with code 1.
- **Download failure** (powerline-go): `curl` error causes `die()` to report the failed URL, OS/arch mismatch, or version tag issue.
- **Missing target directory**: validated before any writes; exits with code 1 if absent.

### DOTFILES map format

Each array entry follows `"REPO_RELATIVE_PATH:TARGET_RELATIVE_PATH"`. Glob `*` in either position expands at runtime. Target glob `*` is replaced with the matched filename from the source side.

### Snippet extension mapping

Defined by the `SHELL_PROFILES` associative array:

| Extension | Profile file |
|---|---|
| `.bash` | `.bashrc` |
| `.zsh` | `.zshrc` |

To add a new shell, add an entry to this array.

---

## Persistence

### Local filesystem state (symlinked)

| Repository path | Symlink target on disk |
|---|---|
| `dots/vimrc` | `~/.vimrc` |
| `dots/tmux.conf` | `~/.tmux.conf` |
| `dots/config/kitty/*` | `~/.config/kitty/<basename>` |

The list is declared in the `DOTFILES` array at the top of `update.sh`. Only files are linked; directories are never symlinked directly. Missing parent directories are auto-created.

### Profile mutations (injected)

User profile files (`~/.bashrc`, `~/.zshrc`) are modified in-place by snippet injection. Each injected block:
1. Adds a blank line before the opening guard.
2. Appends the source line with the full absolute path to the repo's `snippets/` directory.

### Version stamp files

| Path | Purpose |
|---|---|
| `.version` (repo root) | Human-readable version for git history |
| `~/.local/bin/.powerline-go-version` | Installed powerline-go version tag, used to skip redundant downloads |

Both are plain text files containing a single semver string.

### Dependency bootstrap — vim-plug

Vim plugins are managed by [vim-plug](https://github.com/junegunn/vim-plug). The plugin installer (`plug.vim`) is **not** version-controlled; it must be bootstrapped once manually:
```
curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
```
After bootstrapping, run `:PlugInstall` inside Vim to resolve all plugins listed in `.vimrc`.

---

## External Dependencies

### Binary requirements

| Tool | Purpose | Required by |
|---|---|---|
| `bash` ≥ 5.0 | Script runtime | `update.sh` (feature compatibility) |
| `curl` | HTTP download (powerline-go binary, vim-plug bootstrap) | Phases 2–3 requirements check |
| `python3` | JSON parsing of GitHub API response for auto-version resolution | Powerline-go version lookup |

Installed at runtime as needed; not distributed with the repo.

### Third-party services

| Service | Resource | Purpose |
|---|---|---|
| GitHub releases (`justjanne/powerline-go`) | OS-specific binary assets | powerline-go prompt tool (Phase 3) |
| GitHub raw content (`junegunn/vim-plug`) | `plug.vim` bootstrapper file | Vim plugin manager install URL |

### Optional dependencies (no failure if absent)

| Dependency | Usage | Fallback / note |
|---|---|---|
| powerline-go | 32-bit ELF binary downloaded from GitHub | Prompt degrades to raw `$PS1` if not found |
| ripgrep (`rg`) | `<leader>s` fuzzy-file search (vim) | Command silently fails; user sees empty results |
| fzf | `<leader>p` file finder (vim) | `fzf#install()` bootstraps on demand |

---

## Versioning

Managed by `scripts/bump-version.sh [patch|minor|major]`. The version is stored in two places:

| Location | Content | Synced by |
|---|---|---|
| `.version` | Semver string (e.g. `0.3.1`) | `bump-version.sh` writes here |
| `update.sh` → `readonly VERSION` | Same semver string, compiled into script | `bump-version.sh` updates via `sed -i` |

Bump rules:

| Type | When |
|---|---|
| **patch** | Bug fixes, config tweaks, snippet edits |
| **minor** | New dotfile, new snippet, new feature in `update.sh` |
| **major** | Breaking change to `update.sh` interface or repo layout |
