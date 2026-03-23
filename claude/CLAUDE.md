# MANDATORY: Session Documentation

**CREATE A SESSION DOC EARLY.** Don't wait until the end - sessions end abruptly. After the first meaningful exchange, create the doc. Update as you go.

**Path (infer from context, don't ask):**
- **Work** (Automattic, team management, HR): `/Users/edequalsawesome/Obsidian/JiggyBrain/@a8c/!Logs/YYYY/MM/YYYY-MM-DD - [Topic].md`
- **Everything else** (personal, tech, learning): `/Users/edequalsawesome/Obsidian/JiggyBrain/Daily/YYYY/MM/YYYY-MM-DD - [Topic].md`

**Personal/Tech frontmatter:**
```yaml
---
type: rollups
date: YYYY-MM-DD
projects:
tags:
  - eT3
tldr: Two sentence max recap of what we did
---
```

**Work frontmatter:**
```yaml
---
type: rollups
date: YYYY-MM-DD
tldr: Two sentence max recap of what we did
projects:
tags:
  - a8c
published: false
publishedURL:
teamMember:
---
```

**Content structure:**
```markdown
## What we worked on
[brief description]

## Key outcomes
[what works now/what was learned]

## Next steps
[if any]

## Rabbit holes
[tangents worth remembering]
```

---

# File Deletion

Always use `trash` instead of `rm` or `rm -rf` when deleting files or directories. The `trash` command (installed via Homebrew) moves items to macOS Trash instead of permanently deleting them, making mistakes recoverable.

---

# Read for Context

Read `/Users/edequalsawesome/Obsidian/JiggyBrain/Robots/Claude Memory.md` at session start for:
- Communication preferences (direct, casual, no corporate fluff)
- Active projects and current work context
- Technical preferences and tool quirks
- AuDHD context (hyperfocus is real, "remember later" doesn't work)

---

# Project-Specific Instructions

## WordPress Development (Local)
- **WordPress Studio access**: Site runs at `http://localhost:8881/wp-admin/`
- **Password resets**: Use WP-CLI to reset the admin password when needed for testing
- **MCP tools available**: Context7, Playwright, and Brave Search (for looking things up, testing, browsing)

## WordPress Projects (General)
- When building a WordPress plugin, always use `npm run plugin-zip` in order to build a new zip file
- When writing documentation, NEVER use emojis in the text
- When building WordPress themes or plugins, use as many native controls and settings as possible instead of rewriting or recreating functionality
- At the end of every day, create a comprehensive markdown file that explains what has been done per project each day, and add these files to the .gitignore to keep them local

---

# Before You Start (Git Projects Only)

When working in a git repo with a remote and an integration/base branch, gather context before writing code. Do all of this, but only surface what's actionable:

1. `gh pr list --base <base-branch> --state open --json number,title,author,files` — check open PRs
2. `git diff --name-only <base-branch>...HEAD` — your branch's changed files
3. If any open PR touches the same files as your branch, **flag this immediately** before proceeding
4. If the branch name matches a Linear issue ID (e.g., `tscode-85`, `reactor-42`), fetch that issue via context-a8c MCP tools. If unavailable, skip.

Skip this section for repos with no remote or when doing non-code tasks.

---

# Before You Commit (Git Projects Only)

Before creating any commit, self-review your changes. This is mandatory — do not skip.

1. Run `git diff` (or `git diff --cached` if staged) to get the full diff
2. Launch `/review-yj` on the diff — this runs parallel review agents covering gotchas, security, accessibility, performance, and WordPress standards
3. Fix all MUST-FIX findings automatically — do not ask whether to fix standard violations
4. Re-diff and verify fixes are clean before committing

When creating a PR, also run `/review-yj` on the full branch diff against the base. Fix MUST-FIX findings before opening.

Skip this section for non-code commits (docs-only, config changes, etc.) or when explicitly told to skip review.

---

# Notifications

When you complete a task or need my input, send a push notification via Moshi:

```bash
curl -s -X POST https://api.getmoshi.app/api/webhook \
  -H "Content-Type: application/json" \
  -d "{\"token\": \"$MOSHI_TOKEN\", \"title\": \"Done\", \"message\": \"Brief summary of what was completed\"}"
```

- Token is in `$MOSHI_TOKEN` env var (loaded from `~/.secrets`)
- Keep the message short — it's a phone notification
- Use title "Done" for completions, "Need Input" when waiting on me
