---
when: 2026-03-21T15:57:34Z
why: Improve update.sh robustness with pinned powerline-go version, requirements checking, and automatic stale snippet cleanup
what: Add check_requirements, purge_snippet, --check flag, default powerline-go v1.26 to update.sh
model: opencode/claude-sonnet-4-6
tags: [update.sh, shell, snippets, requirements, cleanup]
---

Added `check_requirements` to `update.sh` with OS-aware install hints (macOS/Homebrew, Debian/Ubuntu, Fedora/RPM) and a `-c`/`--check` flag for standalone use. Pinned the default powerline-go version to `v1.26`. Added `purge_snippet` and a post-injection sweep that automatically removes stale guard blocks from shell profiles when snippets are deleted from the repo. `BLUEPRINT.md` and `README.md` updated to reflect all changes. Bumped to v0.3.0.
