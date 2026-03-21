---
when: 2026-03-21T13:55:14Z
why: Provide a repeatable, idempotent way to symlink dotfiles from the repository into the home directory
what: Add update.sh dotfile installer and BLUEPRINT.md
model: opencode/claude-sonnet-4-6
tags: [dotfiles, installer, bash, blueprint]
---

Added `update.sh` — a bash script that symlinks managed dotfiles (`.vimrc`, `.config/kitty/*`) from the repository into `$HOME` (or a custom target via `-d`). Supports dry-run (`-n`), backs up existing files as `.bak`, creates missing parent directories, and is fully idempotent. Also added `BLUEPRINT.md` documenting the repo layout, all managed dotfiles, Vim and Kitty configuration details, and `update.sh` usage. Supporting files added: `scripts/bump-version.sh` and `.version`. Version bumped to 0.1.0.
