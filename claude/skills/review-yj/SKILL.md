---
name: review-yj
description: |
  Full team code review by Young Justice — runs specialist reviewers in parallel:
  Reddy (gotchas), Tim (security), Cassie (accessibility), Bart (performance),
  Conner (WordPress, auto-detected), Cissie (Obsidian plugins, auto-detected).
  Spawns parallel agents for each reviewer and consolidates findings.
  Use: /review-yj <file-or-directory>
author: Claude Code
version: 1.1.0
date: 2026-03-10
allowed-tools:
  - Read
  - Glob
  - Grep
  - Agent
---

# Young Justice — Full Team Code Review

*The whole squad assembles. Specialist reviewers analyze your code in parallel, each bringing their unique expertise. Like the show, they're stronger together.*

## Instructions

When the user invokes `/review-yj`, follow this process:

### Step 1: Determine Scope

Read the target files/directory the user specified. If they gave a directory, use Glob to identify all relevant source files.

### Step 2: Detect Platform Specialists

**Always run the core four:** Reddy, Tim, Cassie, Bart.

**Detect WordPress** — check for:
- `*.php` files with WordPress functions (`add_action`, `add_filter`, `wp_enqueue`)
- `block.json` files
- `style.css` with `Theme Name:` header
- `composer.json` with `wordpress` dependencies

If WordPress detected, also run **Conner** (WordPress specialist).

**Detect Obsidian plugin** — check for:
- `manifest.json` with `minAppVersion` field
- Imports from `'obsidian'` in TypeScript/JavaScript files
- `esbuild.config.mjs` with obsidian externals

If Obsidian plugin detected, also run **Cissie** (Obsidian specialist).

Both Conner and Cissie can run simultaneously if somehow both platforms are detected (unlikely but possible).

### Step 3: Launch Parallel Agents

Spawn agents in parallel using the Agent tool. Each agent should:

1. Receive the FULL skill prompt from the corresponding reviewer skill
2. Be told which files to review
3. Be instructed to stay in character and follow their skill's output format
4. Be told this is a research/review task — NO code modifications

For each agent, first READ the corresponding SKILL.md file to get the full persona and instructions:
- `/Users/edequalsawesome/.claude/skills/review-red/SKILL.md`
- `/Users/edequalsawesome/.claude/skills/review-tim/SKILL.md`
- `/Users/edequalsawesome/.claude/skills/review-cassie/SKILL.md`
- `/Users/edequalsawesome/.claude/skills/review-bart/SKILL.md`
- `/Users/edequalsawesome/.claude/skills/review-conner/SKILL.md` (WordPress only)
- `/Users/edequalsawesome/.claude/skills/review-cissie/SKILL.md` (Obsidian only)

Use this prompt template for each agent:

```
You are performing a specialized code review. Here is your full persona and review checklist:

[PASTE THE FULL CONTENT OF THEIR SKILL.md]

Review the following files: [FILE LIST]

Important: This is a READ-ONLY review. Do not modify any files. Read all files, analyze them according to your review focus areas, and produce your review in the specified output format, fully in character.
```

### Step 4: Consolidate Results

After all agents complete, present a consolidated report:

```markdown
# Young Justice — Code Review Assembly

**Target:** [what was reviewed]
**Squad deployed:** [which reviewers ran]

---

[Each reviewer's full output, separated by horizontal rules]

---

## Mission Debrief

**Critical findings across all reviewers:** [count]
**High priority findings:** [count]
**Total findings:** [count]

### Priority Action Items
[Numbered list of the most important findings across ALL reviewers, ordered by severity]

### The Team's Verdict
[A brief in-character moment where the team discusses — Reddy states facts, Tim connects security dots, Cassie advocates for users, Bart vibrates impatiently, Conner (if present) grumbles about WordPress anti-patterns, and Cissie (if present) takes precise aim at Obsidian API misuse]
```

## Notes

- Always run agents in PARALLEL for speed — don't wait for one to finish before starting another
- If the codebase is very large, focus each reviewer on the most relevant files for their specialty
- The consolidated Priority Action Items list should deduplicate — if Reddy and Tim both flag the same issue, combine them
- The Team's Verdict section should be fun and in-character but also genuinely useful as a summary
