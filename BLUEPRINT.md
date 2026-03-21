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
├── .vimrc                       # Vim configuration
├── .gitignore
├── AGENTS.md                    # Agent protocol (from agentic-template)
├── BLUEPRINT.md                 # This file
├── CONTEXT.md                   # Session context for agents
├── opencode.json                # opencode AI config
├── scripts/
│   └── bump-version.sh          # Version bumping utility
└── update.sh                    # Dotfile symlink installer
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

## update.sh — Dotfile Installer

**Location:** `./update.sh` (repo root)  
**Must be run from:** anywhere — it resolves its own location via `BASH_SOURCE[0]`.  
**Default target:** `$HOME`

### Behaviour
- Only files are symlinked; directories are never linked directly.
- Missing parent directories in the target are created with `mkdir -p`.
- Existing regular files at the destination are backed up as `<file>.bak` before
  being replaced.
- Stale or wrong symlinks are removed and re-created.
- Correct symlinks are left untouched (`OK`).
- Fully idempotent — safe to run repeatedly.

### Options
| Flag | Effect |
|---|---|
| `-d DIR` | Install into `DIR` instead of `$HOME` |
| `-n` | Dry-run: print actions without making changes |
| `-v` | Print version and exit |
| `-h` | Print help and exit |

### Adding a new dotfile
Edit the `DOTFILES` array in `update.sh`:
```bash
DOTFILES=(
    ".vimrc:.vimrc"
    ".config/kitty/*:.config/kitty/*"
    # Add new entries here:
    ".tmux.conf:.tmux.conf"
)
```
Format: `"REPO_RELATIVE_PATH:TARGET_RELATIVE_PATH"`.  
Glob `*` in the target is replaced with the matched filename from the source.

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
Current version tracked in that script. Every merged change must bump the version.

| Bump | When |
|---|---|
| patch | Bug fixes, config tweaks |
| minor | New dotfile added, new feature in `update.sh` |
| major | Breaking change to `update.sh` interface or repo layout |
