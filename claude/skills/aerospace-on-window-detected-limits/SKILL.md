---
name: aerospace-on-window-detected-limits
description: |
  Fix AeroSpace config parse errors when using unsupported commands in on-window-detected.
  Use when: (1) aerospace.toml fails to parse with "argument must be a number" or
  "'run' is mandatory key" errors in on-window-detected blocks, (2) trying to resize,
  set proportions, or run arbitrary commands when a window is detected, (3) wanting
  per-app default window sizes in AeroSpace. Only move-node-to-workspace, layout floating,
  and layout tiling are supported in on-window-detected.run.
author: Claude Code
version: 1.0.0
date: 2026-03-05
---

# AeroSpace on-window-detected Command Limitations

## Problem
AeroSpace's `on-window-detected` callback only supports a very limited set of commands.
Attempting to use commands like `resize` causes misleading parse errors that don't
clearly explain the actual limitation.

## Context / Trigger Conditions
- AeroSpace fails to start or reload config after editing `on-window-detected` blocks
- Error messages like:
  - `on-window-detected[N].run: ERROR: <number> argument must be a number`
  - `on-window-detected[N]: 'run' is mandatory key`
- Trying to set per-app window proportions (e.g., Slack at 75% width)
- Trying to use `resize`, `focus`, or other commands in `on-window-detected.run`

## Solution

### What's allowed in `on-window-detected.run`
Only these commands work:
- `move-node-to-workspace <workspace>`
- `layout floating`
- `layout tiling`

### What does NOT work
- `resize` (any form: `resize width 75%`, `resize smart +50`, etc.)
- `focus` commands
- Most other AeroSpace commands

### Workarounds for per-app sizing
1. **Manual resize after launch**: Use keybindings (`alt+=` / `alt+-`) to adjust
   proportions after windows land on their workspace. AeroSpace remembers proportions
   until the workspace tree is reset.
2. **External scripting**: Use a separate script with `aerospace` CLI commands
   triggered by a launch agent or wrapper script.

### Correct config example
```toml
# This works - only workspace assignment
[[on-window-detected]]
if.app-id = 'com.tinyspeck.slackmacgap'
run = 'move-node-to-workspace W'

# This also works - multiple allowed commands
[[on-window-detected]]
if.app-id = 'com.some.app'
run = ['move-node-to-workspace 3', 'layout floating']

# This FAILS - resize is not supported here
[[on-window-detected]]
if.app-id = 'com.tinyspeck.slackmacgap'
run = ['move-node-to-workspace W', 'resize width 75%']
```

## Verification
After fixing the config, reload with service mode (`alt+shift+;` then `esc`) or
restart AeroSpace. No parse errors should appear.

## Notes
- The error message is misleading - it complains about the number argument rather
  than telling you `resize` isn't a valid command in this context
- There's an open GitHub issue requesting broader command support:
  https://github.com/nikitabobko/AeroSpace/issues/20
- See also: `aerospace-macos-keybinding-conflicts` for keybinding issues

## References
- [AeroSpace Commands](https://nikitabobko.github.io/AeroSpace/commands)
- [GitHub Issue #20: Lift limitations in on-window-detected.run](https://github.com/nikitabobko/AeroSpace/issues/20)
