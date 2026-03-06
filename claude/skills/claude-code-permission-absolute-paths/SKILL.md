---
name: claude-code-permission-absolute-paths
description: |
  Fix Claude Code permission rules silently not matching files despite correct-looking paths.
  Use when: (1) Read/Edit/Write permissions in settings.json or settings.local.json don't
  prevent permission prompts, (2) permissions with absolute paths like /Users/foo/bar/**
  still trigger approval dialogs, (3) permissions seem correct but Claude keeps asking for
  every subfolder. Root cause: single-slash /path is relative to project root, not filesystem
  root. Must use //path (double slash) for absolute filesystem paths.
author: Claude Code
version: 1.0.0
date: 2026-03-03
---

# Claude Code Permission Absolute Paths

## Problem

Permission rules in Claude Code's `settings.json` or `settings.local.json` that use absolute
filesystem paths (e.g., `Write(/Users/alice/Documents/**)`) silently fail to match. Claude
still prompts for permission on every file write, even though the rule looks correct.

## Context / Trigger Conditions

- You've added `Read`, `Edit`, or `Write` permissions with absolute paths in `settings.json` or `settings.local.json`
- Claude Code still prompts for permission when accessing files under those paths
- The prompts appear for each new subdirectory (e.g., `Daily/2026/03/`)
- The paths look correct and `**` glob should match recursively
- Particularly common when using a "hub" directory with symlinks to other locations

## Solution

Use `//` (double slash) prefix for absolute filesystem paths in permission rules.

Claude Code's permission path prefixes:

| Prefix | Meaning | Example |
|--------|---------|---------|
| `//path` | Absolute filesystem path | `Read(//Users/alice/docs/**)` |
| `~/path` | Home directory | `Read(~/Documents/**)` |
| `/path` | **Relative to project root** | `Edit(/src/**/*.ts)` |
| `path` | Relative to current dir | `Read(*.env)` |

The gotcha: `/Users/alice/Documents/**` looks like an absolute path, but Claude Code treats
single-slash `/` as relative to the project root. So it's actually matching
`<project-root>/Users/alice/Documents/**`, which doesn't exist.

### Fix

Change all absolute path permissions from single to double slash:

```json
{
  "permissions": {
    "allow": [
      "Read(//Users/alice/Obsidian/**)",
      "Edit(//Users/alice/Obsidian/**)",
      "Write(//Users/alice/Obsidian/**)"
    ]
  }
}
```

### Where to put permissions

- `~/.claude/settings.json` -- global, applies to all projects and sessions
- `<project>/.claude/settings.local.json` -- project-level, only when launched from that directory

Global is more reliable for cross-directory access patterns (e.g., hub directory with symlinks).

## Verification

1. Restart Claude Code (settings are loaded at session start)
2. Try writing a file to a deeply nested path under the allowed directory
3. If no permission prompt appears, the fix is working

## Example

Before (broken -- silently doesn't match):
```json
"Write(/Users/edequalsawesome/Obsidian/**)"
```

After (works):
```json
"Write(//Users/edequalsawesome/Obsidian/**)"
```

## Notes

- This affects `Read`, `Edit`, and `Write` tool permissions only -- `Bash` rules use a different pattern syntax
- The `**` glob itself works correctly for recursive matching; the issue is purely the path prefix
- Settings changes require a session restart to take effect
- `~/` also works as an alternative to `//Users/<username>/` for paths under your home directory
- When using a hub directory with symlinks, use the **real** (resolved) paths, not the symlink paths -- Claude resolves symlinks before matching
