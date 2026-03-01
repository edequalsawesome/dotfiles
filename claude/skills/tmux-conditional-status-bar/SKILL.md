---
name: tmux-conditional-status-bar
description: |
  Configure tmux status bar to show different modules based on machine type (laptop vs desktop).
  Use when: (1) tmux config is synced via dotfiles across multiple machines, (2) battery indicator
  shows "no battery" or placeholder on desktops, (3) want to show uptime on desktops instead of
  battery on laptops. Covers macOS battery detection with pmset, if-shell conditionals, and the
  critical -ag vs -agF flag difference for catppuccin modules.
author: Claude Code
version: 1.1.0
date: 2026-02-28
---

# tmux Conditional Status Bar by Machine Type

## Problem
When syncing tmux config via dotfiles (GitHub) across multiple machines, status bar modules like
battery show useless information on desktops ("no battery" or placeholder icons). You want laptop
to show battery, desktop to show something useful like uptime.

## Context / Trigger Conditions
- tmux config synced across laptop and desktop (e.g., Mac mini)
- Battery indicator shows placeholder/empty on machines without batteries
- Using catppuccin theme with status modules
- Want machine-specific status bar content from a single config file

## Solution

### 1. Detect Battery Presence (macOS)
Use `pmset -g batt` which returns battery info on laptops, nothing useful on desktops:

```bash
pmset -g batt 2>/dev/null | grep -q 'InternalBattery'
```

### 2. Use tmux if-shell Conditional
Replace your static battery line with a conditional:

```tmux
# Conditional: battery on laptops, uptime on desktops
if-shell "pmset -g batt 2>/dev/null | grep -q 'InternalBattery'" \
    "set -agF status-right '#{E:@catppuccin_status_battery}'" \
    "set -ag status-right '#{E:@catppuccin_status_uptime}'"
```

### 3. Critical: Use Correct Flags

**This is the non-obvious part:**

- `set -agF` = append, global, **F**ormat expansion (immediate)
- `set -ag` = append, global, no immediate format expansion

For modules containing `#()` shell commands (like uptime), use `-ag` WITHOUT the `F` flag.
The `F` flag forces immediate expansion at config load time, but `#()` needs to re-evaluate
on each status refresh.

- **Battery**: Can use `-agF` (static module)
- **Uptime**: Must use `-ag` (contains `#()` shell command)

## Verification
1. On laptop: `tmux source-file ~/.tmux.conf` - should show battery icon with percentage
2. On desktop: `tmux source-file ~/.tmux.conf` - should show uptime like "2d 11h"

## Example

Full status-right configuration with conditional:

```tmux
# Status bar modules (must come AFTER catppuccin.tmux loads)
set -g status-left ""
set -g status-right-length 100
set -g status-right "#{E:@catppuccin_status_directory}#{E:@catppuccin_status_session}#{E:@catppuccin_status_date_time}"

# Conditional: battery on laptops, uptime on desktops
if-shell "pmset -g batt 2>/dev/null | grep -q 'InternalBattery'" \
    "set -agF status-right '#{E:@catppuccin_status_battery}'" \
    "set -ag status-right '#{E:@catppuccin_status_uptime}'"
```

## Customizing Module Colors

To change a catppuccin module's color (e.g., make uptime match battery's lavender):

```tmux
# Load catppuccin first
run ~/.config/tmux/plugins/catppuccin/tmux/catppuccin.tmux

# Override color AFTER catppuccin loads, BEFORE status-right is set
# Use the icon_bg variable, NOT the _color variable
set -g @catppuccin_status_uptime_icon_bg "#{E:@thm_lavender}"
```

**Critical flags for color overrides:**
- Use `set -g` (NOT `set -gF`) for color variables
- The `-F` flag expands format strings immediately, but theme variables like `@thm_lavender`
  need to expand at render time
- Override `@catppuccin_status_MODULE_icon_bg` directly, not `@catppuccin_MODULE_color`
  (the latter is only used during initial module setup)

Available catppuccin mocha colors: `@thm_rosewater`, `@thm_flamingo`, `@thm_pink`, `@thm_mauve`,
`@thm_red`, `@thm_maroon`, `@thm_peach`, `@thm_yellow`, `@thm_green`, `@thm_teal`, `@thm_sky`,
`@thm_sapphire`, `@thm_blue`, `@thm_lavender`

## Notes

- **Catppuccin built-in modules**: The uptime module is built into catppuccin at
  `~/.config/tmux/plugins/catppuccin/tmux/status/uptime.conf` - no additional plugin needed
- **Linux detection**: Replace pmset check with `test -d /sys/class/power_supply/BAT0`
- **Other conditionals**: Can extend pattern for hostname-based config:
  `if-shell "[ $(hostname) = 'macmini' ]" "..." "..."`
- **Quote escaping**: Complex shell commands in if-shell may need helper scripts if escaping
  becomes unwieldy

## References
- [tmux if-shell documentation](https://man7.org/linux/man-pages/man1/tmux.1.html)
- [Catppuccin tmux status modules](https://github.com/catppuccin/tmux/tree/main/status)
