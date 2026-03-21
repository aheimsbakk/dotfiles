# BLUEPRINT — dotfiles

## Purpose
A personal dotfiles repository. Configuration files are version-controlled here
and symlinked into the user's home directory by `update.sh`. No package manager,
no framework — just bash and symlinks.

---

## Repository Layout

```
.
├── .config/
│   └── kitty/
│       ├── kitty.conf           # Kitty terminal emulator main config
│       └── current-theme.conf   # Active colour theme (Gnome Light by default)
├── .opencode/                   # Agentic template files (managed by .opencode/update.sh)
│   ├── RULES.md
│   ├── update.sh
│   └── WORKLOG_TEMPLATE.md
├── snippets/                    # Shell snippets injected into user profiles
│   └── powerline-go.bash        # powerline-go prompt setup for bash
├── .vimrc                       # Vim configuration
├── .gitignore
├── AGENTS.md                    # Agent protocol (from agentic-template)
├── BLUEPRINT.md                 # This file
├── README.md                    # User-facing documentation and keybinding reference
├── CONTEXT.md                   # Session context for agents
├── opencode.json                # opencode AI config
├── scripts/
│   └── bump-version.sh          # Version bumping utility
└── update.sh                    # Dotfile installer, snippet injector, tool downloader
```

---

## Managed Dotfiles

| Repository path | Symlinked to |
|---|---|
| `.vimrc` | `~/.vimrc` |
| `.config/kitty/kitty.conf` | `~/.config/kitty/kitty.conf` |
| `.config/kitty/current-theme.conf` | `~/.config/kitty/current-theme.conf` |

The list is declared in the `DOTFILES` array at the top of `update.sh`.
Glob patterns (`*`) are supported and expand against the repository at runtime.

---

## update.sh — Installer

**Location:** `./update.sh` (repo root)  
**Must be run from:** anywhere — it resolves its own location via `BASH_SOURCE[0]`.  
**Default target:** `$HOME`

The script runs three phases in order: **dotfiles → snippets → powerline-go**.

### Options
| Flag | Effect |
|---|---|
| `-b` | Back up existing regular files as `<file>.bak` before replacing |
| `-d DIR` | Install into `DIR` instead of `$HOME` |
| `-n` | Dry-run: print actions without making changes |
| `-V VERSION` | powerline-go version to install (e.g. `v1.26`; default: latest) |
| `-v` | Print script version and exit |
| `-h` | Print help and exit |

### Status labels
| Label | Meaning |
|---|---|
| `OK` | Already correct — no-op |
| `LINK` | Symlink created |
| `MKDIR` | Parent directory created |
| `SKIP` | Regular file exists at destination; use `-b` to replace |
| `BACKUP` | Existing file moved to `<file>.bak` (only with `-b`) |
| `UNLINK` | Stale/wrong symlink removed before re-linking |
| `MISSING` | Glob matched no files in the repository |
| `CREATE` | New profile file created (was absent) |
| `INJECT` | Snippet block appended to profile |
| `DOWNLOAD` | Binary fetched from GitHub (dry-run label) |
| `INSTALLED` | Binary downloaded, placed, and made executable |

### Phase 1 — Dotfiles
Symlinks files from the repo into `TARGET_DIR`. Only files are linked; directories are never linked directly. Missing parent directories are created automatically. Fully idempotent.

Add new dotfiles by editing the `DOTFILES` array at the top of `update.sh`:
```bash
DOTFILES=(
    ".vimrc:.vimrc"
    ".config/kitty/*:.config/kitty/*"
    # Add new entries here:
    ".tmux.conf:.tmux.conf"
)
```
Format: `"REPO_RELATIVE_PATH:TARGET_RELATIVE_PATH"`. Glob `*` in the target is replaced with the matched filename from the source.

### Phase 2 — Shell snippets
Files in `snippets/` are named `<anything>.<shell>`. The extension determines which profile file receives the injection:

| Extension | Profile file |
|---|---|
| `.bash` | `.bashrc` |
| `.zsh` | `.zshrc` |

Each snippet is wrapped in a unique guard block and appended to the profile:
```bash
# >>> dotfiles:powerline-go.bash >>>
source "/path/to/repo/snippets/powerline-go.bash"
# <<< dotfiles:powerline-go.bash <<<
```
The guard makes injection idempotent — re-running never duplicates the block. If the profile file does not exist it is created. To add support for a new shell, add an entry to the `SHELL_PROFILES` associative array in `update.sh`.

### Phase 3 — powerline-go
Downloads the correct binary for the current OS and architecture from the [justjanne/powerline-go](https://github.com/justjanne/powerline-go) GitHub releases and installs it to `TARGET_DIR/.local/bin/powerline-go`. A version stamp file (`.local/bin/.powerline-go-version`) prevents redundant re-downloads. Pass `-V VERSION` to pin a specific release tag; omit it to always resolve and install the latest.

**Arch mapping:**

| `uname -m` | Asset suffix |
|---|---|
| `x86_64` | `amd64` |
| `aarch64` / `arm64` | `arm64` |
| `armv7l` / `armv6l` | `arm` |
| `i386` / `i686` | `386` |

---

## Snippets (snippets/)

Shell snippets are small, self-contained shell scripts sourced into the user's interactive shell profile by `update.sh`. Naming convention: `<description>.<shell-ext>`.

| File | Shell | Purpose |
|---|---|---|
| `powerline-go.bash` | bash | Configures `powerline-go` as the `PS1` prompt via `PROMPT_COMMAND` |

The `powerline-go.bash` snippet guards itself: it only activates when `$TERM != linux` and the `powerline-go` binary is on `PATH`.

---

## Vim (.vimrc)

**Plugin manager:** [vim-plug](https://github.com/junegunn/vim-plug)  
**Bootstrap:** `curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim`  
**Install plugins:** `:PlugInstall` inside Vim

### Plugin groups
| Group | Plugins |
|---|---|
| LSP & Autocomplete | vim-lsp, vim-lsp-settings, asyncomplete.vim, asyncomplete-lsp.vim |
| Navigation | NERDTree, fzf, fzf.vim |
| Git | vim-gitgutter |
| Editing | auto-pairs, vim-polyglot |
| Visuals | vim-airline, vim-airline-themes, vim-one, vim-lucius |
| Tools | todo.txt-vim, markdown-preview.nvim |

**Colourscheme:** Lucius (light, high contrast)  
**Leader key:** `Space` / local leader: `,`

### Key bindings
| Key | Action |
|---|---|
| `Ctrl+n` | Toggle NERDTree |
| `<leader>p` | Fuzzy-find files (fzf) |
| `<leader>s` | Ripgrep search in files |
| `<leader><leader>` | Clear search highlights |
| `gd` | LSP: go to definition |
| `gr` | LSP: references |
| `K` | LSP: hover docs |
| `<leader>rn` | LSP: rename |
| `<leader>f` | LSP: format document |

---

## Kitty Terminal (.config/kitty/)

**Font:** Cascadia Code (variable, Regular/Bold/Italic)  
**Font size:** 12pt, line height 120%  
**Default theme:** Gnome Light (`current-theme.conf`)

### Layout & window
- Layouts enabled: `tall, fat, grid, horizontal, vertical, stack`
- Initial size: 120×24 characters
- Background opacity: 0.95 (dynamic, adjustable at runtime)
- Tab bar style: powerline

### Key bindings
| Key | Action |
|---|---|
| `Alt+←/→/↑/↓` | Navigate splits |
| `Alt+Shift+←/→/↑/↓` | Resize splits |
| `Alt+Z` | Toggle stack (zoom) layout |
| `Ctrl+Shift+T` / `Cmd+T` | New tab (cwd) |
| `Ctrl+Shift+W` / `Cmd+W` | Close window |
| `Ctrl+Alt+D` / `Cmd+Opt+D` | Switch to dark theme |
| `Ctrl+Alt+L` / `Cmd+Opt+L` | Switch to light theme |
| `Ctrl+Shift+F12` / `Cmd+Shift+F12` | Open theme switcher overlay |
| `Ctrl+Shift+F5` / `Cmd+Ctrl+,` | Reload config |

### Platform notes
- **Linux/Wayland:** `linux_display_server wayland`
- **macOS:** `macos_option_as_alt yes`, `macos_quit_when_last_window_closed yes`

---

## Versioning

Managed by `scripts/bump-version.sh [patch|minor|major]`.  
Current version stored in `.version`. Every merged change must bump the version.

| Bump | When |
|---|---|
| patch | Bug fixes, config tweaks, snippet edits |
| minor | New dotfile, new snippet, new feature in `update.sh` |
| major | Breaking change to `update.sh` interface or repo layout |
