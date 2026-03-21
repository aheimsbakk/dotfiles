# dotfiles

Personal configuration files for Vim, Kitty, and tmux — version-controlled and installed via a single script.

## Requirements

| Tool | Notes |
|---|---|
| `bash` ≥ 4.0 | Required by `update.sh` (associative arrays) |
| `curl` | Required to download powerline-go |
| `python3` | Required to parse the GitHub API response |
| `vim` | With [vim-plug](https://github.com/junegunn/vim-plug) for plugins |
| `kitty` | Terminal emulator |
| `tmux` | Terminal multiplexer |

## Quick start

```bash
git clone <your-repo-url> ~/dotfiles
cd ~/dotfiles
./update.sh
```

This will:
1. Symlink all dotfiles into `$HOME`
2. Inject shell snippets into `~/.bashrc` / `~/.zshrc`
3. Download the latest `powerline-go` binary into `~/.local/bin/`

After the first run, bootstrap Vim plugins:

```vim
:PlugInstall
```

## update.sh

```
Usage: update.sh [OPTIONS]

  -b            Back up existing files as <file>.bak before replacing
  -d DIR        Target directory (default: $HOME)
  -n            Dry-run: show what would be done without making changes
  -V VERSION    powerline-go version to install (e.g. v1.26; default: latest)
  -h            Show help and exit
  -v            Show script version and exit
```

**Examples:**

```bash
./update.sh                  # install into $HOME, latest powerline-go
./update.sh -n               # dry-run, see what would change
./update.sh -b               # back up any existing files before replacing
./update.sh -V v1.26         # pin a specific powerline-go version
./update.sh -d ~/test        # install into a different directory
```

The script is fully **idempotent** — safe to re-run at any time. It will only act on what has actually changed.

### Status labels

| Label | Meaning |
|---|---|
| `OK` | Already correct — no-op |
| `LINK` | Symlink created |
| `MKDIR` | Parent directory created |
| `SKIP` | Regular file exists; use `-b` to replace |
| `BACKUP` | Existing file moved to `<file>.bak` |
| `UNLINK` | Stale symlink removed before re-linking |
| `MISSING` | Glob matched no files in the repository |
| `CREATE` | New shell profile file created |
| `INJECT` | Snippet block appended to profile |
| `INSTALLED` | powerline-go downloaded and installed |

### Adding a new dotfile

Edit the `DOTFILES` array at the top of `update.sh`:

```bash
DOTFILES=(
    ".vimrc:.vimrc"
    ".config/kitty/*:.config/kitty/*"
    ".tmux.conf:.tmux.conf"        # ← add entries like this
)
```

Format: `"REPO_PATH:TARGET_PATH"`. Glob `*` in the target is replaced with the matched filename.

### Adding a shell snippet

Drop a file into `snippets/` named `<description>.<shell>`:

| Extension | Injected into |
|---|---|
| `.bash` | `~/.bashrc` |
| `.zsh` | `~/.zshrc` |

The snippet is wrapped in a unique guard so it is never duplicated:

```bash
# >>> dotfiles:my-snippet.bash >>>
source "/path/to/repo/snippets/my-snippet.bash"
# <<< dotfiles:my-snippet.bash <<<
```

---

## Managed files

| Repository path | Installed to |
|---|---|
| `.vimrc` | `~/.vimrc` |
| `.config/kitty/kitty.conf` | `~/.config/kitty/kitty.conf` |
| `.config/kitty/current-theme.conf` | `~/.config/kitty/current-theme.conf` |
| `.tmux.conf` | `~/.tmux.conf` |
| `snippets/powerline-go.bash` | sourced from `~/.bashrc` |
| *(binary)* powerline-go | `~/.local/bin/powerline-go` |

---

## Keybindings

### Kitty

> **Splits** are Kitty windows inside a layout. **Tabs** work like browser tabs.

#### Navigation

| Key | Action |
|---|---|
| `Alt+←` | Focus split to the left |
| `Alt+→` | Focus split to the right |
| `Alt+↑` | Focus split above |
| `Alt+↓` | Focus split below |

#### Resize splits

| Key | Action |
|---|---|
| `Alt+Shift+←` | Narrow current split |
| `Alt+Shift+→` | Widen current split |
| `Alt+Shift+↑` | Taller current split |
| `Alt+Shift+↓` | Shorter current split |

#### Layouts

| Key | Action |
|---|---|
| `Alt+Z` | Toggle zoom (stack layout — maximise current split) |

Enabled layouts cycle with `next_layout`: `tall`, `fat`, `grid`, `horizontal`, `vertical`, `stack`.

#### Tabs

| Key | Action |
|---|---|
| `Ctrl+Shift+T` / `Cmd+T` | New tab (opens in current directory) |
| `Ctrl+Shift+W` / `Cmd+W` | Close current window |

#### Themes

| Key | Action |
|---|---|
| `Ctrl+Alt+D` / `Cmd+Opt+D` | Switch to dark theme |
| `Ctrl+Alt+L` / `Cmd+Opt+L` | Switch to light theme |
| `Ctrl+Shift+F12` / `Cmd+Shift+F12` | Open interactive theme switcher |

#### Config

| Key | Action |
|---|---|
| `Ctrl+Shift+F5` / `Cmd+Ctrl+,` | Reload `kitty.conf` |

---

### Vim

> **Leader** key is `Space`. **Local leader** is `,`.

#### File & search

| Key | Action |
|---|---|
| `<leader>p` | Fuzzy-find files (fzf) |
| `<leader>s` | Search text in files (ripgrep) |
| `<leader><leader>` | Clear search highlights |

#### File tree

| Key | Action |
|---|---|
| `Ctrl+N` | Toggle NERDTree sidebar |

#### LSP

| Key | Action |
|---|---|
| `gd` | Go to definition |
| `gr` | Find references |
| `K` | Hover documentation |
| `<leader>rn` | Rename symbol |
| `<leader>f` | Format document |

#### Plugins

Install: `:PlugInstall` — Update: `:PlugUpdate` — Clean: `:PlugClean`

vim-plug bootstrap (run once):

```bash
curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
  https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
```

---

### tmux

> **Prefix** is `Ctrl+B` (default). All bindings below require the prefix unless marked **[no prefix]**.

#### Sessions, windows, panes

| Key | Action |
|---|---|
| `Prefix + c` | New window |
| `Prefix + ,` | Rename window |
| `Prefix + 1`…`9` | Switch to window by number (1-indexed) |
| `Prefix + n` / `p` | Next / previous window |
| `Prefix + %` | Split pane vertically |
| `Prefix + "` | Split pane horizontally |
| `Prefix + x` | Close current pane |
| `Prefix + z` | Toggle pane zoom (maximise) |
| `Prefix + o` | Cycle focus through panes |
| `Prefix + q` | Show pane numbers (press number to jump) |
| `Prefix + {` / `}` | Swap pane left / right |

#### Resize panes

| Key | Action |
|---|---|
| `Prefix + ←/→/↑/↓` | Resize pane (hold to repeat) |

#### Synchronise panes

| Key | Action |
|---|---|
| `Ctrl+S` **[no prefix]** | Toggle synchronise-panes (type in all panes at once) |

> If the terminal freezes after `Ctrl+S`, press `Ctrl+Q` to unfreeze (bash XOFF/XON).

#### Copy mode (vi keys)

| Key | Action |
|---|---|
| `Prefix + [` | Enter copy mode |
| `v` | Begin selection |
| `y` | Yank (copy) selection and exit |
| `Escape` | Cancel / exit copy mode |
| `q` | Exit copy mode |
| `h/j/k/l` | Move cursor |
| `/` | Search forward |
| `?` | Search backward |
| `n` / `N` | Next / previous search match |

#### Mouse

Mouse support is enabled. Click to focus a pane, drag pane borders to resize, scroll to enter copy mode.

#### Status bar

The status bar is transparent (inherits Kitty's background) so it works in both light and dark themes. It shows:
- **Left:** session name
- **Right:** date and time (`YYYY-MM-DD HH:MM`)
- Active window is bold and bracketed: `[1: bash]`

---

## powerline-go

The prompt is powered by [powerline-go](https://github.com/justjanne/powerline-go), installed to `~/.local/bin/powerline-go` and activated via `snippets/powerline-go.bash`.

**Modules shown (left to right):**

`venv` · `direnv` · `user` · `host` · `cwd` · `perms` · `terraform-workspace` · `kube` · `git` · `hg` · `jobs` · `exit` · `newline` · `root`

The prompt only activates when `$TERM != linux` and `powerline-go` is on `PATH`. It uses flat mode with compact git status and colourised hostnames.

Make sure `~/.local/bin` is on your `PATH`:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

Add this to your `~/.bashrc` or `~/.zshrc` if it isn't already there.
