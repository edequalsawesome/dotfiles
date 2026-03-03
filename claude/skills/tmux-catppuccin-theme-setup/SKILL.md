---
name: tmux-catppuccin-theme-setup
description: |
  Fix Catppuccin tmux theme not loading, showing wrong colors, or missing status bar modules.
  Use when: (1) Switched from another tmux theme (Dracula, Nord, etc.) but old theme still
  shows after sourcing config, (2) Catppuccin loads but status bar is empty/bare with no
  modules, (3) Catppuccin options like flavor aren't taking effect. Covers TPM plugin cleanup,
  config ordering requirements, and v2 status module configuration.
author: Claude Code
version: 1.0.0
date: 2026-02-25
---

# Tmux Catppuccin Theme Setup

## Problem
Switching to Catppuccin tmux theme from another theme (e.g., Dracula) results in the old
theme persisting, or Catppuccin loading with a bare/empty status bar missing all the fancy
modules.

## Context / Trigger Conditions
- Switched tmux themes but old theme still appears after `tmux source ~/.tmux.conf`
- Catppuccin colors load but status bar is plain with no modules (no session, date, host, etc.)
- `@catppuccin_flavor` setting doesn't seem to take effect
- Status bar shows default tmux green or previous theme's colors

## Solution

### Issue 1: Old theme still showing

**Root cause:** Previous theme plugin still installed in `~/.tmux/plugins/`.

```bash
# Check for leftover theme plugins
ls ~/.tmux/plugins/
# The Dracula theme installs as ~/.tmux/plugins/tmux/ (the repo name)
# Remove it:
rm -rf ~/.tmux/plugins/tmux  # This is dracula/tmux
```

Also check that TPM isn't still referencing the old theme:
```bash
grep -i dracula ~/.tmux.conf  # or whatever the old theme was
```

### Issue 2: Catppuccin options not taking effect

**Root cause:** Options set AFTER the `run` line. Catppuccin reads its options at runtime.

**Wrong:**
```tmux
run ~/.config/tmux/plugins/catppuccin/tmux/catppuccin.tmux
set -g @catppuccin_flavor 'mocha'  # TOO LATE - already ran
```

**Correct:**
```tmux
set -g @catppuccin_flavor 'mocha'  # Set options FIRST
run ~/.config/tmux/plugins/catppuccin/tmux/catppuccin.tmux
```

### Issue 3: Status bar empty / no modules

**Root cause:** Catppuccin v2 requires explicit module configuration. Unlike v1 or Dracula,
it doesn't auto-populate the status bar.

Add status module configuration BEFORE the `run` line:

```tmux
# Catppuccin theme
set -g @catppuccin_flavor 'mocha'
set -g @catppuccin_window_status_style 'rounded'  # basic, rounded, slanted, custom, none

# Status bar modules
set -g status-left ""
set -g status-right-length 100
set -g status-right "#{E:@catppuccin_status_directory}#{E:@catppuccin_status_session}#{E:@catppuccin_status_date_time}#{E:@catppuccin_status_host}"

# MUST be last - runs the theme with the options above
run ~/.config/tmux/plugins/catppuccin/tmux/catppuccin.tmux
```

**Available modules** (found in `~/.config/tmux/plugins/catppuccin/tmux/status/`):
- `session`, `directory`, `host`, `user`, `application`
- `date_time`, `battery`, `cpu`, `load`, `uptime`
- `weather`, `kube`, `gitmux`, `clima`, `pomodoro_plus`

### Issue 4: Source doesn't fully apply

Sometimes `tmux source ~/.tmux.conf` doesn't fully clear cached styles from the old theme.
Nuclear option:

```bash
tmux kill-server
tmux
```

## Verification
- Status bar shows colored pill/rounded segments with module content
- `tmux show -g status-style` returns Catppuccin colors (e.g., `bg=#181825,fg=#cdd6f4` for Mocha)
- `tmux show -g @catppuccin_flavor` returns expected flavor

## Example

Complete working `.tmux.conf` Catppuccin section:

```tmux
# Catppuccin theme
set -g @catppuccin_flavor 'mocha' # latte, frappe, macchiato or mocha
set -g @catppuccin_window_status_style 'rounded'

# Status bar modules
set -g status-left ""
set -g status-right-length 100
set -g status-right "#{E:@catppuccin_status_directory}#{E:@catppuccin_status_session}#{E:@catppuccin_status_date_time}#{E:@catppuccin_status_host}"

run ~/.config/tmux/plugins/catppuccin/tmux/catppuccin.tmux

# TPM (keep at very bottom)
run '~/.tmux/plugins/tpm/tpm'
```

## Notes
- The `#{E:@catppuccin_status_<module>}` syntax is specific to Catppuccin v2
- Terminal theme (e.g., Shades of Purple) affects pane content colors; tmux theme affects status bar and borders
- If using TPM, the TPM `run` line should stay at the very bottom, after Catppuccin's `run` line
- Catppuccin install location varies: `~/.config/tmux/plugins/catppuccin/tmux/` (manual) vs `~/.tmux/plugins/tmux-catppuccin/` (TPM)
