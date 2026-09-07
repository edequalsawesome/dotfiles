# dotfiles — agent instructions

Shared project guidance for Codex and Claude Code. Keep it here; `CLAUDE.md` imports this file.

Personal macOS shell and application configuration. Read `readme.md` and `setup.sh`, then inspect the relevant directory (for example `zsh/`, `git/`, `ghostty/`, `tmux/`, or `awesomux/`). Existing symlinks can make edits live immediately.

Preserve machine-specific paths and personal/work Git identity separation. Never copy a whole machine's SSH or credential configuration to another host. Keep credentials out of the repository.

Inspect git status before editing and stage only owned changes. External-editor edits are not proof of an automatic commit; verify commit and push state separately. Validate changed shell files with the matching shell's syntax checker, parse structured configuration, and use the application's config check when available. Do not run the setup script as a test: it installs software and relinks live files.

## Completion and sync

This repository is approved for direct-to-main commits. After completing and validating an authorized change, commit the files owned by that task and push to origin without another confirmation so other machines can receive them through dotpull. Do not leave completed work local-only. Preserve unrelated or unfinished changes; never bulk-stage them, force-push, or weaken review gates. Verify the remote branch contains the commit before reporting it synced.
