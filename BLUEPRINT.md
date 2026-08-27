# BLUEPRINT — dotfiles

## Purpose

A personal dotfiles repository. Configuration files are version-controlled inside the `dots/` directory and symlinked into the user's home directory by `update.sh`. No package manager, no framework — just bash and symlinks. The same repository also carries the agent instruction set (`.opencode/`, `AGENTS.md`, `RULES.md`) used to drive development of this repository itself.

---

## System Goals

1. **Centralised configuration** — all dotfile sources live in a single git repository.
2. **Idempotent installation** — `update.sh` is safe to re-run; it only acts on what has changed.
3. **Snippet guard blocks** — shell snippets are injected into user profiles using unique delimiter markers, preventing duplicates and enabling automatic stale-block cleanup and reordering.
4. **Cross-platform portability** — dotfiles and scripts work on both Linux (Wayland) and macOS.
5. **Self-documented agent setup** — the repository carries both the user-facing docs and the agent-instruction files that generate and maintain them, so the whole system can be regenerated from the working tree.

---

## Component Hierarchy

```
┌──────────────────┐   ┌─────────────────┐   ┌──────────────────┐
│  update.sh       │──▶│ Phase 1:        │──▶│ Symlink engine   │
│  (entry point)   │   │ dotfile linking │   │  link_file()     │
├──────────────────┤   ├─────────────────┤   ├──────────────────┤
│  .version        │   │ Phase 2:        │──▶│ Snippet engine    │
│  scripts/        │   │ snippet injection│   │ inject_snippet(),│
│   bump-version.sh│   │                 │   │ relocate/purge/  │
│   verify-…sync.sh│   │                 │   │ reorder()        │
├──────────────────┤   ├─────────────────┤   ├──────────────────┤
│  dots/           │   │ Phase 3:        │──▶│ Binary downloader│
│    vimrc         │──▶│ powerline-go    │   │ install_powerline│
│    tmux.conf     │   │ download        │   │ _go()            │
│    config/kitty/*│──▶└─────────────────┘   └──────────────────┘
├──────────────────┤        ┌──────────┐   ┌──────────────────┐
│  snippets/*.bash │──▶     │  profiles │   │ dotfiles state   │
│  (see below)     │        │ .bashrc  │   │ tree (symlinked  │
├──────────────────┤        │ .zshrc   │   │  files read each │
│  .opencode/      │        └──────────┘   └──────────────────┘
│  AGENTS.md       │        ┌──────────┐   ┌──────────────────┐
│  opencode.json   │        │ snapshots│   │ profile state    │
│  docs/           │        └──────────┘   │ (modified by     │
└──────────────────┘                       │  inject_snippet) │
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
  resolve CLI arguments → set TARGET_DIR, DRY_RUN, BACKUP, VERSION flags
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
    Collect all files from snippets/*.* sorted lexicographically.
    For each snippet:
      - Determine shell extension (.bash, .zsh)
      - Map to profile file via SHELL_PROFILES associative array
      - inject_snippet(snippet_path, profile_path)
          - If guard block absent → append guarded source line (INJECT)
          - If guard block present but stale path → update in-place (RELOCATE)
          - If guard block present and current → no-op (OK)
    After injection:
      - reorder_snippets() — purge and re-inject all blocks in sorted order
      - Purge orphan guards — remove blocks whose snippet file was deleted
        │
        ▼
  Phase 3 — powerline-go binary download
    detect_os() + detect_arch() → asset name (e.g. "powerline-go-linux-amd64")
    Check .powerline-go-version stamp in .local/bin against requested version
      - If match and binary is executable → no-op (OK)
      - Otherwise → curl from GitHub releases, install, update stamp
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
| `BACKUP` | Existing file moved to `<file>.bak` | Followed by `LINK` |
| `UNLINK` | Stale symlink removed (followed by new `LINK`) | Becomes `OK` next run |

### Snippet state (Phase 2)

Guard block format in a profile file:
```
# >>> dotfiles:<filename> >>>
source "<absolute path to repo/snippets/<filename>>"
# <<< dotfiles:<filename> <<<
```

| State | Meaning | Resolved by |
|---|---|---|
| Present, path current | Guard and source line both match repo location | No-op |
| Present, path stale | Source path points to an old repo location | Path rewritten in place |
| Absent (file exists) | Snippet in repo but no guard in profile | Insert guarded source |
| Absent (file deleted) | Guard present but snippet no longer in `snippets/` | Removed by stale-cleanup pass |

Snippet order is the lexicographic filename order. Numeric prefixes (`00-`, `10-`, `90-`) define chronological loading. Out-of-order blocks are purged and re-injected.

### powerline-go state (Phase 3)

A version-stamp file (`.powerline-go-version`) under the install dir stores the last installed version tag. Re-running with the same version is a no-op if the binary already exists.

---

## Contracts

### Entry point

`update.sh` at the repository root. It resolves the repo root from `BASH_SOURCE[0]` and defaults to installing into `$HOME`.

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
- **Unknown flags / unexpected args**: die with the message on stderr and exit code 1.
- **Download failure** (powerline-go): a failed download reports the URL/OS/arch/version and exits non-zero.
- **Missing target directory**: validated before writes; exits with code 1 if absent.

### DOTFILES map format

Each array entry is a `"REPO_RELATIVE_PATH:TARGET_RELATIVE_PATH"` pair. A `*` in the repo side expands at runtime; a `*` in the target side becomes the matched filename. Only files are linked; directories are never linked directly. Missing parent directories are created.

### Snippet extension mapping

Defined by the `SHELL_PROFILES` associative array:

| Extension | Profile file |
|---|---|
| `.bash` | `.bashrc` |
| `.zsh` | `.zshrc` |

Adding a shell means adding an entry to this array.

---

## Persistence

### Local filesystem state (symlinked)

| Repository path | Symlink target on disk |
|---|---|
| `dots/vimrc` | `~/.vimrc` |
| `dots/tmux.conf` | `~/.tmux.conf` |
| `dots/config/kitty/*` | `~/.config/kitty/<basename>` |

The list is declared in the `DOTFILES` array. Only files are linked. Missing parent directories are created automatically.

### Profile mutations (injected)

User profile files (`~/.bashrc`, `~/.zshrc`) are modified in place by snippet injection. Each injected block adds a blank line, the opening guard, the absolute `source` line, and the closing guard.

### Version stamp files

| Path | Purpose |
|---|---|
| `.version` (repo root) | Human-readable version for git history |
| `<install dir>/.powerline-go-version` | Installed powerline-go version tag |

Both are plain-text files containing a single version string.

### Repository documentation state

`docs/memory/` and the worklogs are generated artifacts. The repo also tracks `CHANGELOG.md` (version history) and `scripts/verify_codebase_sync.sh` (validates that every path declared in `CODEBASE.md` exists on disk).

---

## External Dependencies

### Binary requirements

| Tool | Purpose | Required by |
|---|---|---|
| `bash` ≥ 5.0 | Script runtime | `update.sh` (feature compatibility) |
| `curl` | HTTP download (powerline-go binary, vim-plug bootstrap) | Phases 2–3 |
| `python3` | JSON parsing of the GitHub API response | Powerline-go version lookup |

Installed at runtime as needed; not distributed with the repo.

### Third-party services

| Service | Resource | Purpose |
|---|---|---|
| GitHub releases (`justjanne/powerline-go`) | OS-specific binary assets | powerline-go prompt tool (Phase 3) |
| GitHub raw content (`junegunn/vim-plug`) | `plug.vim` bootstrapper file | Vim plugin manager |

### Optional dependencies (no failure if absent)

| Dependency | Usage | Fallback / note |
|---|---|---|
| powerline-go | Prompt binary downloaded from GitHub | Prompt degrades to a raw prompt if not found |
| ripgrep (`rg`) | Fuzzy-file search in Vim | Command silently fails; empty results |
| fzf | File finder in Vim | `fzf#install()` bootstraps on demand |

---

## Versioning

Managed by `scripts/bump-version.sh [patch|minor|major]`. The version is stored in `.version` and mirrored into the `update.sh` `VERSION` constant:

| Location | Content | Synced by |
|---|---|---|
| `.version` | Version string (e.g. `0.4.1`) | `bump-version.sh` writes here |
| `update.sh` → `readonly VERSION` | Same string, compiled into the script | `bump-version.sh` updates it |

Bump rules:

| Type | When |
|---|---|
| **patch** | Bug fixes, config tweaks, snippet edits |
| **minor** | New dotfile, new snippet, new `update.sh` feature |
| **major** | Breaking change to `update.sh` interface or repo layout |

`CHANGELOG.md` is updated manually to describe each release's rationale.