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
