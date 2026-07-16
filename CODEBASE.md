# CODEBASE — Physical File Mapping

## Target Environment

| Property | Value |
|---|---|
| Language | Bash (POSIX shell) |
| Shell requirement | bash ≥ 5.0 |
| Dependency manager | None — all deps are system-level or downloaded at runtime |
| Naming convention | `kebab-case` for directories; extension-based grouping for snippets |

---

## Directory Structure

```
.gitignore                          # Excludes *.bak and tmp/
AGENTS.md                           # Agent protocol
BLUEPRINT.md                        # Architecture specification
CODEBASE.md                         # This file — concrete file-to-component mapping
README.md                           # User-facing documentation
update.sh                           # Main installer (795 lines)
.docs/                              # Session logs
└── worklogs/
    ├── 2026-03-21-13-55-dotfile-installer.md
    ├── 2026-03-21-15-06-readme-and-snippets.md
    ├── 2026-03-21-15-57-update-sh-enhancements.md
    ├── 2026-03-23-18-25-readme-snippet-order.md
    └── 2026-03-23-18-27-sync-version.md
dots/                               # Dotfile sources — symlinked into $HOME by update.sh
├── tmux.conf                       # Escape-time 10ms, vi copy-mode keys, minimal status bar (70 lines)
├── vimrc                           # vim-plug plugins, LSP setup, Lucius theme (129 lines)
└── config/
    └── kitty/                      # Symlinked to ~/.config/kitty/
        ├── current-theme.conf      # Adwaita Light colour palette (51 lines)
        ├── kitty.conf              # Fonts, layouts, tab bar, keybindings (134 lines)
        └── linux.conf              # Platform-specific: dynamic background opacity (6 lines)
scripts/
├── bump-version.sh                 # Version bumping: .version + update.sh VERSION constant
snippets/                           # Shell snippets — injected into ~/.bashrc / ~/.zshrc
├── 00-local-bin.bash               # Add ~/.local/bin to PATH (guard-gated)
├── 10-bash-history.bash            # Enhanced history: size limits, histappend, realtime-write
├── batcat-config.bash              # Set BAT_THEME=Coldark-Cold for bat file viewer
├── bitwarden-ssh-agent.bash        # Bitwarden SSH agent socket auto-detection
├── kitty-ssh-workaround.bash       # SSH alias: TERM=xterm-256color, kssh = kitty +kitten ssh
├── ls-color.bash                   # alias ls='ls --color=auto'
├── opencode-aliases.bash           # Podman aliases (oc, ocw) for opencode AI container
└── 90-powerline-go.bash            # Powerline-go prompt setup (venv,direnv,user,host,cwd,...)
```

---

## Blueprint Component → Physical Path Mapping

| Blueprint component | Physical file(s) |
|---|---|
| Installer (entry point) | `update.sh` |
| Version management utility | `scripts/bump-version.sh` |
| Dotfile — Vim configuration | `dots/vimrc` |
| Dotfile — Tmux configuration | `dots/tmux.conf` |
| Dotfile — Kitty terminal main config | `dots/config/kitty/kitty.conf` |
| Dotfile — Kitty active colour theme | `dots/config/kitty/current-theme.conf` |
| Dotfile — Linux platform settings | `dots/config/kitty/linux.conf` |
| Snippet — PATH setup | `snippets/00-local-bin.bash` |
| Snippet — Bash history config | `snippets/10-bash-history.bash` |
| Snippet — bat file viewer theme | `snippets/batcat-config.bash` |
| Snippet — Bitwarden SSH agent | `snippets/bitwarden-ssh-agent.bash` |
| Snippet — Kitty SSH workaround | `snippets/kitty-ssh-workaround.bash` |
| Snippet — ls colour alias | `snippets/ls-color.bash` |
| Snippet — OpenCode podman aliases | `snippets/opencode-aliases.bash` |
| Snippet — powerline-go prompt | `snippets/90-powerline-go.bash` |

---

## Entry Points

| Purpose | Path | Invocation |
|---|---|---|
| Dotfile installer (main) | `./update.sh` | `./update.sh [-b] [-c] [-d DIR] [-n] [-V VERSION]` |
| Version bump utility | `scripts/bump-version.sh` | `scripts/bump-version.sh [patch\|minor\|major]` |
| Requirement check (standalone) | `./update.sh -c` | `./update.sh --check` |
| Help text | `./update.sh -h` | `./update.sh --help` |
| Script version | `./update.sh -v` | `./update.sh --version` |
| Vim plugin install | (inside Vim) | `:PlugInstall` |
| Vim plug bootstrapper | (manual one-time) | `curl ... ~/.vim/autoload/plug.vim` |

---

## Language Rationale

**Bash 5.0+** was chosen because this project is a dotfile installer and configuration manager. The shell is the only tool needed — no language abstraction, no runtime dependency beyond curl + python3 for optional GitHub API parsing. Bash satisfies all requirements: `BASH_SOURCE[0]` enables running from any working directory while resolving the repo root; associative arrays map snippet extensions to profile files extensibly; glob expansion with `nullglob` isolates pattern matching per dotfiles entry; guard blocks use simple string matching (`grep -qF`) — no templating engine needed.

**Symlink-based deployment** was chosen over package managers because dotfiles are personal preferences and should track the user's git history exactly, not a versioned release channel. Symlinks also mean every config change is immediately visible from the repo, making diffs trivial to review.

---

## Naming Conventions

| Scope | Convention | Example |
|---|---|---|
| Directory names | `kebab-case` | `dots/`, `docs/worklogs/` |
| Dotfile sources | Match target basename | `dots/vimrc → ~/.vimrc` |
| Kitty configs | `kebab-case` + short noun | `kitty.conf`, `current-theme.conf` |
| Snippet files | Numeric-prefixed `.bash` for ordered loads; bare `.bash` for unordered | `00-local-bin.bash`, `batcat-config.bash` |
| Script files | `kebab-case.sh` | `bump-version.sh` |
| Version tracking | Plain semver text in one-line file | `.version` contains `0.3.1` |
| Git commits | Conventional Commits format | `<type>(<scope>): <summary>` |
