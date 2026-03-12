---
name: claude-code-plugin-update-stale-marketplace
description: |
  Fix Claude Code plugin updates that silently install the old version. Use when:
  (1) `claude plugins update <plugin>` runs without error but skills/version don't change,
  (2) plugin repo has newer commits but installed version stays the same,
  (3) new skills added to a plugin repo don't appear after update. The root cause is a
  stale marketplace cache — you must run `claude plugins marketplace update <name>` before
  updating the plugin itself.
author: Claude Code
version: 1.0.0
date: 2026-03-10
---

# Claude Code Plugin Update Ignores New Versions (Stale Marketplace Cache)

## Problem
`claude plugins update <plugin>` silently succeeds but installs the same old version,
even when the source repository has newer commits and a bumped version number.

## Context / Trigger Conditions
- You run `claude plugins update <plugin>@<marketplace>` and it exits cleanly (no error)
- The installed version doesn't change (check `~/.claude/plugins/installed_plugins.json`)
- The source repo on GitHub has newer commits with updated `plugin.json` version
- New skills added to the repo don't appear in the local cache
- `~/.claude/plugins/known_marketplaces.json` shows `lastUpdated` is weeks/months old for that marketplace

## Solution

### 1. Update the marketplace cache first
```bash
claude plugins marketplace update <marketplace-name>
```
This fetches the latest commit/manifest from the source repo.

### 2. Then update the plugin
```bash
claude plugins update <plugin>@<marketplace>
```
Now this will see the new version and actually pull it.

### 3. Verify
```bash
# Check the new version directory exists
ls ~/.claude/plugins/cache/<marketplace>/<plugin>/

# Check installed_plugins.json points to new version
cat ~/.claude/plugins/installed_plugins.json | python3 -m json.tool | grep -A5 '<plugin>'
```

### 4. Restart Claude Code
New/updated skills only load on session start.

## Key Files
- `~/.claude/plugins/known_marketplaces.json` — marketplace sources and `lastUpdated` timestamps
- `~/.claude/plugins/installed_plugins.json` — installed plugins with version, path, and git SHA
- `~/.claude/plugins/cache/<marketplace>/<plugin>/<version>/` — actual plugin files

## Verification
After the two-step update:
- A new version directory appears in the cache (e.g., `1.0.1/` alongside old `1.0.0/`)
- `installed_plugins.json` shows the new version and a different `gitCommitSha`
- New skills appear in the `skills/` subdirectory of the new version

## Example
```bash
# Symptom: obsidian plugin stuck at 1.0.0, repo is at 1.0.1
claude plugins update obsidian@obsidian-skills  # silently does nothing

# Fix: refresh marketplace first
claude plugins marketplace update obsidian-skills
claude plugins update obsidian@obsidian-skills

# Verify
ls ~/.claude/plugins/cache/obsidian-skills/obsidian/
# Output: 1.0.0  1.0.1  <-- new version now present
```

## Notes
- The `claude plugins uninstall` + `claude plugins install` cycle also fails to get the new version if the marketplace cache is stale — same root cause
- There is no warning or error when the marketplace cache is stale; the command exits 0
- You can check all marketplace freshness at once in `known_marketplaces.json`
- To update ALL marketplaces: `claude plugins marketplace update` (no name = updates all)
