---
when: 2026-03-21T15:06:39Z
why: Provide user documentation, keybinding reference, and complete the dotfile installer with snippet injection, powerline-go download, and tmux support
what: Add README.md, update update.sh with snippets/powerline-go/tmux, fix -h parser bug and JSON stdin fix
model: opencode/claude-sonnet-4-6
tags: [docs, readme, update.sh, snippets, powerline-go, tmux, bugfix]
---

Added `README.md` with full user documentation covering quick start, `update.sh` usage, all managed files, and keybinding references for Kitty, Vim, and tmux. Updated `update.sh` to v2.0.0 with three phases: dotfile symlinking, shell snippet injection (snippets/*.bash → .bashrc, *.zsh → .zshrc with idempotent guard blocks), and powerline-go binary download with OS/arch detection and version pinning via `-V`. Fixed `-h` crash caused by command substitution with redirect inside heredoc, and fixed JSON parse error by piping API response via stdin instead of embedding in Python string literal. Added `.tmux.conf` to the managed `DOTFILES` array. `BLUEPRINT.md` updated throughout. Version bumped to 0.2.0.
