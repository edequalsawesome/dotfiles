# Always Read First

At the start of every session, read `/Users/edequalsawesome/Obsidian/JiggyBrain/Robots/Claude Memory.md` for context on how to work with eD, communication preferences, active projects, and documentation patterns. Do this before diving into any task.

**Why this matters:** eD is AuDHD and has specific workflow needs. Reading this file first prevents having to re-explain context, reduces cognitive load, and ensures you communicate in a way that actually helps.

---

# Session Documentation (Do This Automatically)

**When to create:** Once the session has a clear direction (after first meaningful exchange), create the session doc. Don't wait until the end - sessions may end abruptly.

**Update as you go:** Add to the doc when hitting milestones, solving problems, or shifting topics. Partial documentation beats no documentation.

**Which path to use (infer from context, don't ask):**
- **Work sessions** (Automattic, team management, HR, work processes): `/Users/edequalsawesome/Obsidian/JiggyBrain/@a8c/!Logs/YYYY/MM/YYYY-MM-DD - [Topic Description].md`
- **Everything else** (personal, learning, music theory, tech/home lab, health): `/Users/edequalsawesome/Obsidian/JiggyBrain/Daily/YYYY/MM/YYYY-MM-DD - [Topic Description].md`

**Doc structure:**
```
What we worked on: [brief description]
Key outcomes: [what works now/what was learned]
Next steps: [if any]
Rabbit holes: [tangents worth remembering]
```

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
