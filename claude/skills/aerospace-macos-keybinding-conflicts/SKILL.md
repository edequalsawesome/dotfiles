---
name: aerospace-macos-keybinding-conflicts
description: |
  Fix AeroSpace keybindings that silently don't work on macOS. Use when:
  (1) alt+tab or alt+shift+tab bindings in AeroSpace config do nothing,
  (2) AeroSpace keybindings stop working when a Chromium/Electron app
  (Helium, Chrome, Electron-based apps) has focus, (3) setting up AeroSpace
  for the first time and choosing keybindings that won't conflict with macOS.
  Covers macOS system shortcut conflicts and Chromium alt+key interception.
author: Claude Code
version: 1.0.0
date: 2026-03-03
---

# AeroSpace macOS Keybinding Conflicts

## Problem
Certain AeroSpace keybindings silently fail on macOS — they appear valid in the config
but never fire. This happens for two distinct reasons: macOS system shortcut conflicts
and Chromium-based app key interception.

## Context / Trigger Conditions
- AeroSpace keybinding works in some apps but not others
- `alt-tab` or `alt-shift-tab` in aerospace config does absolutely nothing
- Layout toggles (`alt+,`, `alt+/`) or other alt+key bindings don't fire when a
  Chromium-based browser (Helium, Chrome, Brave, Arc) or Electron app has focus
- Keybindings work fine in Ghostty, Slack (native), Obsidian, etc.

## Solution

### Issue 1: macOS System Shortcut Conflicts

macOS intercepts these key combinations globally before AeroSpace sees them:

- **`alt+tab`** — macOS app switcher (Command+Tab uses Cmd, but Alt+Tab is also reserved)
- **`alt+shift+tab`** — macOS reverse app switcher

**Fix:** Rebind to non-conflicting keys:
```toml
# Instead of alt-tab:
alt-semicolon = 'workspace-back-and-forth'
# Instead of alt-shift-tab:
alt-shift-period = 'move-workspace-to-monitor --wrap-around next'
```

Note: The AeroSpace default config (`default-config.toml`) actually includes `alt-tab`
as a binding, which is misleading since it won't work on macOS.

### Issue 2: Chromium/Electron Apps Eating Alt+Key

Chromium-based apps intercept `alt+key` combinations for their own use (special character
input, menu accelerators). When a Chromium window has focus, AeroSpace's `alt+key`
bindings silently fail.

**Affected apps:** Helium Browser, Google Chrome, Brave, Arc, any Electron app
**Not affected:** Ghostty, native macOS apps, Slack (native), Obsidian

**Workarounds:**
1. Focus a non-Chromium window first (click or use `alt+arrows` if those work),
   then use the layout keybinding
2. Set problematic Chromium apps to auto-float so you rarely need layout commands
   while they're focused:
   ```toml
   [[on-window-detected]]
   if.app-id = 'com.heliumfloats.Helium'
   run = 'layout floating'
   ```
3. For critical bindings, consider using `ctrl-alt` or `cmd-alt` modifiers which
   Chromium is less likely to intercept

## Verification
- Test keybindings with a non-Chromium app focused (e.g., Ghostty)
- If they work there but not in Chrome/Helium, it's the Chromium issue
- If they don't work anywhere, it's likely a macOS system shortcut conflict

## Notes
- `aerospace list-apps` shows bundle IDs for creating app-specific rules
- The Chromium issue only matters when the Chromium window has focus — AeroSpace
  keybindings work fine for workspace switching etc. when other apps are focused
- This is a limitation of how Chromium handles keyboard events, not an AeroSpace bug
