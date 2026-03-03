---
name: tmux-multi-device-setup
description: |
  Fix tmux conflicts when using multiple terminal apps across devices (Moshi iOS,
  Ghostty, SSH, Mosh). Use when: (1) "sessions should be nested with care" error
  when connecting via Moshi/Mosh, (2) garbled tmux commands echoed on connect,
  (3) Ghostty "failed to launch the requested command" with tmux, (4) tmux
  base-index ignored after tmux-resurrect restore, (5) setting up auto-tmux for
  SSH but not Mosh connections. Covers parent process detection for Mosh vs SSH,
  Ghostty command wrapping, and tmux-resurrect conflicts.
author: Claude Code
version: 1.0.0
date: 2026-02-23
---

# tmux Multi-Device Setup Gotchas

## Problem
Setting up tmux to auto-start across multiple connection types (SSH from laptop,
Mosh from iOS via Moshi) causes nesting conflicts, garbled output, and configuration
issues with terminal apps like Ghostty.

## Context / Trigger Conditions

### Trigger 1: Moshi tmux nesting
- Connecting via Moshi (iOS) to a server that auto-starts tmux in .zshrc
- See garbled tmux commands echoed: `tmux set -g set-titles on; set -g mouse on...`
- Error: "sessions should be nested with care, unset $TMUX to force"
- Cause: Moshi has native tmux integration and manages sessions itself

### Trigger 2: Ghostty command failure
- Ghostty config `command = tmux new-session -A -s local` fails
- Error: "Ghostty failed to launch the requested command"
- Shows `/usr/bin/login -flp ... /bin/bash --noprofile --norc -c exec -l tmux new-session -A -s local`
- Cause: Ghostty passes command through `/usr/bin/login` which mangles argument parsing

### Trigger 3: tmux-resurrect ignoring base-index
- Set `base-index 1` in .tmux.conf but windows still start at 0
- "Session restored!" flash followed by windows numbered from 0
- Cause: tmux-resurrect/continuum restores saved sessions that used old base-index

## Solution

### Fix 1: Detect Mosh vs SSH connections
Auto-start tmux only for SSH, let Moshi handle tmux for Mosh connections:

```bash
# In .zshrc — check parent process to distinguish SSH from Mosh
if [[ -n "$SSH_CONNECTION" ]] && [[ -z "$TMUX" ]] && [[ "$(ps -o comm= -p $PPID 2>/dev/null)" != "mosh-server" ]]; then
  tmux new-session -A -s main
fi
```

Key insight: `$SSH_CONNECTION` is set for BOTH SSH and Mosh connections (Mosh bootstraps
via SSH). Must check parent process name to distinguish them. `pgrep -P "$PPID"` checks
children of parent (wrong) — use `ps -o comm= -p $PPID` to check the parent itself.

### Fix 2: Wrap Ghostty command in shell
```
# In Ghostty config
command = /bin/zsh -l -c "tmux new-session -A -s local"
```

The `-l` flag ensures login shell initialization (.zshrc/.zshenv load properly).

### Fix 3: Clear tmux-resurrect saved state
```bash
rm -rf ~/.tmux/resurrect/*
tmux kill-server
```

Then reopen terminal. New sessions save with correct base-index going forward.

## Verification
- SSH from laptop: auto-drops into tmux session "main"
- Moshi from iPhone: no nesting error, Moshi manages tmux natively
- Ghostty opens: auto-drops into tmux session "local"
- `tmux show-option -g base-index` returns 1
- Windows in status bar numbered from 1

## Notes
- Use distinct session names per connection type: "main" (SSH), "local" (Ghostty), etc.
- Moshi has a built-in tmux session picker — it detects existing sessions from its UI
- `set -g mouse on` in tmux captures touch events on iOS, preventing text selection — may need to disable for mobile
- Tailscale can silently disconnect after Mac sleep — if SSH suddenly stops connecting, restart Tailscale first
- Store API tokens (like Moshi webhook token) in ~/.secrets, source from .zshenv, reference via env vars in committed files

## References
- Moshi setup guide: https://getmoshi.app/articles/mac-remote-endless-agent-setup
- Ghostty config docs: https://ghostty.org/docs/config
