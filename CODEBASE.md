# CODEBASE — Physical File Mapping

## Target Environment

| Property | Value |
|---|---|
| Language | Bash |
| Shell requirement | bash ≥ 5.0 |
| Dependency manager | None — deps are system-level or downloaded at runtime |
| Naming convention | `kebab-case` for directories; extension-based grouping for snippets |
| Version | 0.4.2 |

---

## Directory Structure

```
.
├── .gitignore                          # Excludes *.bak, tmp/, and docs/
├── AGENTS.md                           # Agent orchestration protocol
├── BLUEPRINT.md                        # Architecture specification
├── CHANGELOG.md                        # Release history with bump rationale
├── CODEBASE.md                         # This file — file-to-component mapping
├── README.md                           # User-facing documentation
├── opencode.json                       # Agent tooling config (autoupdate off)
├── update.sh                           # Main installer (795 lines)
├── .version                            # Source of truth for version (0.4.2)
├── docs/                               # Session memory and worklogs
│   └── memory/
│       ├── INDEX.md                    # Memory skill index
│       └── archive/                    # Memory entries
├── dots/                               # Dotfile sources — symlinked into $HOME
│   ├── tmux.conf                       # Escape-time 10ms, vi copy-mode keys (70 lines)
│   ├── vimrc                           # vim-plug plugins, LSP setup (129 lines)
│   └── config/
│       └── kitty/                      # Symlinked to ~/.config/kitty/
│           ├── current-theme.conf      # Active colour palette (Ayu Light, 21 lines)
│           ├── kitty.conf              # Fonts, layouts, tab bar, keybindings (134 lines)
│           └── linux.conf              # Linux-specific: background opacity (6 lines)
├── scripts/
│   ├── bump-version.sh                 # Version bumping: .version + update.sh VERSION
│   └── verify_codebase_sync.sh         # Validates CODEBASE.md paths exist on disk
├── snippets/                           # Shell snippets — injected into profiles
│   ├── 00-local-bin.bash               # Add ~/.local/bin to PATH
│   ├── 10-bash-history.bash            # Enlarged history + realtime-write
│   ├── 90-powerline-go.bash            # Powerline-go prompt (venv, git, kube, …)
│   ├── batcat-config.bash              # Set BAT_THEME='Coldark-Cold'
│   ├── bitwarden-ssh-agent.bash        # Bitwarden SSH agent socket detection
│   ├── kitty-ssh-workaround.bash       # ssh/kssh aliases for TERM handling
│   ├── ls-color.bash                   # alias ls='ls --color=auto'
│   └── opencode-aliases.bash           # Podman aliases (oc, ocw) for opencode
└── .opencode/                          # Agent-setup runtime
    ├── RULES.md                        # Project rules (dev constraints)
    ├── update.sh                       # Template updater from agentic-opencode
    ├── agents/                         # Agent instruction files (primary mode)
    │   ├── facts.md
    │   ├── linux-expert.md
    │   ├── reflect.md
    │   └── vibe.md
    ├── skills/                         # Loadable skills
    │   ├── clear-language-norwegian/
    │   ├── clear-language/
    │   ├── memory/
    │   ├── todo-txt/
    │   └── wrap-up/
    ├── .gitignore                       # Excludes node_modules and lockfiles
    ├── package.json                     # Dev-only plugin dependency (uncommitted)
    └── node_modules/                    # Dependency cache (git-ignored)
```

---

## Blueprint Component → Physical Path Mapping

| Blueprint component | Physical file(s) |
|---|---|
| Installer (entry point) | `update.sh` |
| Version management utility | `scripts/bump-version.sh` |
| Doc-sync verification | `scripts/verify_codebase_sync.sh` |
| Version source of truth | `.version` |
| Release history | `CHANGELOG.md` |
| Dotfile — Vim configuration | `dots/vimrc` |
| Dotfile — Tmux configuration | `dots/tmux.conf` |
| Dotfile — Kitty terminal main config | `dots/config/kitty/kitty.conf` |
| Dotfile — Kitty active colour theme | `dots/config/kitty/current-theme.conf` |
| Dotfile — Linux platform settings | `dots/config/kitty/linux.conf` |
| Snippet — PATH setup | `snippets/00-local-bin.bash` |
| Snippet — Bash history config | `snippets/10-bash-history.bash` |
| Snippet — powerline-go prompt | `snippets/90-powerline-go.bash` |
| Snippet — bat file viewer theme | `snippets/batcat-config.bash` |
| Snippet — Bitwarden SSH agent | `snippets/bitwarden-ssh-agent.bash` |
| Snippet — Kitty SSH workaround | `snippets/kitty-ssh-workaround.bash` |
| Snippet — ls colour alias | `snippets/ls-color.bash` |
| Snippet — OpenCode podman aliases | `snippets/opencode-aliases.bash` |
| Project rules (constraints) | `.opencode/RULES.md` |
| Agent-setup templates | `.opencode/update.sh` |
| Optional agent skills | `.opencode/skills/*/` |

---

## Entry Points

| Purpose | Path | Invocation |
|---|---|---|
| Dotfile installer (main) | `update.sh` | `./update.sh [-b] [-c] [-d DIR] [-n] [-V VERSION]` |
| Requirement check (standalone) | `update.sh -c` | `./update.sh --check` |
| Help text | `update.sh -h` | `./update.sh --help` |
| Script version | `update.sh -v` | `./update.sh --version` |
| Version bump utility | `scripts/bump-version.sh` | `scripts/bump-version.sh [patch\|minor\|major]` |
| CODEBASE sync verification | `scripts/verify_codebase_sync.sh` | `scripts/verify_codebase_sync.sh` |
| Agent-setup template updater | `.opencode/update.sh` | `.opencode/update.sh` |
| Vim plugin install | (inside Vim) | `:PlugInstall` |

---

## Language Rationale

**Bash 5.0+** was chosen because this project is a dotfile installer and configuration manager. The shell is the only tool needed — no language abstraction, no runtime dependency beyond `curl` + `python3` (for the optional GitHub API lookup). Bash satisfies all requirements: `BASH_SOURCE[0]` lets the script resolve its own repo root from any working directory; associative arrays map snippet extensions to profile files; glob expansion with `nullglob` isolates per-entry pattern matching; guard blocks use simple string matching — no templating engine needed.

**Symlink-based deployment** was chosen over a package manager because dotfiles are personal preferences that should track the user's git history exactly, not a versioned release channel. Symlinks make every config change immediately visible from the repo, and diffs stay easy to review.

---

## Naming Conventions

| Scope | Convention | Example |
|---|---|---|
| Directory names | `kebab-case` | `dots/`, `scripts/`, `tmp/` |
| Dotfile sources | Match target basename | `dots/vimrc → ~/.vimrc` |
| Kitty configs | `kebab-case` + short noun | `kitty.conf`, `current-theme.conf` |
| Snippet files | Numeric-prefixed `.bash` for ordered loads; bare `.bash` for unordered | `00-local-bin.bash`, `batcat-config.bash` |
| Script files | `kebab-case.sh` | `bump-version.sh` |
| Version tracking | Plain semver text in a one-line file | `.version` contains `0.4.2` |
| Git commits | Conventional Commits format | `<type>(<scope>): <summary>` |