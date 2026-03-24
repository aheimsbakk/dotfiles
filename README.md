# dotfiles

Personal configuration files for Vim, Kitty, and tmux — version-controlled and installed via a single script.

## Requirements

`bash` ≥ 5.0, `curl`, `python3`. Run `./update.sh --check` to verify; missing tools are reported with OS-specific install instructions.

## Quick start

```bash
# Clone and install dotfiles, shell snippets, and powerline-go
git clone git@github.com:aheimsbakk/dot-files.git ~/dotfiles
cd ~/dotfiles
./update.sh

# Bootstrap vim-plug (run once)
curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
  https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
```

This will:
1. Symlink all dotfiles into `$HOME`
2. Inject shell snippets into `~/.bashrc` / `~/.zshrc`
3. Download `powerline-go v1.26` into `~/.local/bin/`

Then open Vim and install plugins:

```vim
:PlugInstall
```

## update.sh

```
Usage: update.sh [OPTIONS]

  -b            Back up existing files as <file>.bak before replacing
  -c, --check   Check requirements only; print install hints and exit
  -d DIR        Target directory (default: $HOME)
  -n            Dry-run: show what would be done without making changes
  -V VERSION    powerline-go version to install (default: v1.26)
  -h            Show help and exit
  -v            Show script version and exit
```

The script is fully **idempotent** — safe to re-run at any time. It will only act on what has actually changed.

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

**Removing a snippet:** delete the file from `snippets/` and re-run `./update.sh`. The script automatically detects and removes any stale guard blocks from all profile files, so no manual cleanup is needed.

**Snippet order:** snippets are injected in lexicographic filename order. Prefix filenames with a two-digit number to control load order (e.g. `00-path.bash`, `10-history.bash`, `90-prompt.bash`). If existing blocks in a profile are out of order, re-running `./update.sh` reorders them automatically.

---

## Keybindings

### Kitty

> **Splits** are Kitty windows inside a layout. **Tabs** work like browser tabs.

#### Splits

| Key | Action |
|---|---|
| `Ctrl+Shift+Enter` | New split (opens in current directory) |
| `Alt+←/→/↑/↓` | Focus split in that direction |
| `Alt+Shift+←` | Narrow current split |
| `Alt+Shift+→` | Widen current split |
| `Alt+Shift+↑` | Taller current split |
| `Alt+Shift+↓` | Shorter current split |
| `Alt+Z` | Toggle zoom (stack layout — maximise current split) |

#### Tabs

| Key | Action |
|---|---|
| `Ctrl+Shift+T` / `Cmd+T` | New tab (opens in current directory) |
| `Ctrl+Shift+W` / `Cmd+W` | Close current window |

#### Themes

| Key | Action |
|---|---|
| `Ctrl+Alt+D` / `Cmd+Opt+D` | Switch to dark theme (`Gnome-ish gray-on-black`) |
| `Ctrl+Alt+L` / `Cmd+Opt+L` | Switch to light theme (`Gnome Light`) |
| `Ctrl+Shift+F12` / `Cmd+Shift+F12` | Open interactive theme switcher |

#### Config

| Key | Action |
|---|---|
| `Ctrl+Shift+F5` / `Cmd+Ctrl+,` | Reload `kitty.conf` |

#### Mouse

| Gesture | Action |
|---|---|
| `Ctrl+Shift+Click` drag | Rectangle selection (works inside Vim/Neovim) |

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
| `<leader>la` | Code action |
| `<leader>ld` | Document diagnostics (list all diagnostics in buffer) |
| `<leader>ln` | Next diagnostic |
| `<leader>lp` | Previous diagnostic |

#### Plugins

Install: `:PlugInstall` — Update: `:PlugUpdate` — Clean: `:PlugClean`

---

### tmux

> **Prefix** is `Ctrl+B` (default). Custom bindings only — all standard tmux defaults apply.

#### Synchronise panes

| Key | Action |
|---|---|
| `Ctrl+S` **[no prefix]** | Toggle synchronise-panes (type in all panes at once) |

> If the terminal freezes after `Ctrl+S`, press `Ctrl+Q` to unfreeze (bash XOFF/XON).

#### Copy mode — custom vi keys

| Key | Action |
|---|---|
| `v` | Begin selection (replaces default `Space`) |
| `y` | Yank (copy) selection and exit (replaces default `Enter`) |
| `Escape` | Cancel / exit copy mode |

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
