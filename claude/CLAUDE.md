# Global Claude Code Config

These instructions apply to ALL projects.

---

# Safety

Use `trash` instead of `rm` when deleting files or folders. No flags needed for directories.

---

# Tool Preferences

- Use `td` CLI (`/opt/homebrew/bin/td`) for Todoist operations, not MCP
- Use `obsidian` CLI for vault operations (search, properties, tags), not raw file I/O
- MCP tools available: Context7, Playwright, Brave Search

---

# Session Documentation

**CREATE A SESSION DOC EARLY.** Don't wait until the end - sessions end abruptly. After the first meaningful exchange, create the doc. Update as you go.

**Path (infer from context, don't ask):**
- **Work** (Automattic, team management, HR): `/Users/edequalsawesome/Obsidian/JiggyBrain/@a8c/!Logs/YYYY/MM/YYYY-MM-DD - [Topic].md`
- **Everything else** (personal, tech, learning): `/Users/edequalsawesome/Obsidian/JiggyBrain/Daily/YYYY/MM/YYYY-MM-DD - [Topic].md`

**Frontmatter rules:**
- `type: rollups` and `date: YYYY-MM-DD` always
- `sessionName:` — the kebab-case name used with `/rename` (links doc back to the chat)
- Work sessions: tag `a8c`, include `published: false`, `publishedURL:`, `teamMember:` fields
- Personal sessions: tag `eT3`
- Always include `tldr:` (two sentence max recap)

**Content sections:** What we worked on, Key outcomes, Next steps, Rabbit holes

---

# Working with eD

- **AuDHD**: Hyperfocus is real. "Remember to X later" doesn't work. Reduce cognitive load, don't add to it.
- **Communication**: Direct, casual, call out overthinking. No corporate fluff or hedge language.
- **Style**: Practical solutions over perfect ones. Don't ask permission to document — just do it.
- **Rocket**: Golden doodle. Important.
- **To-dos**: Drop actionable items in Todoist via `td` with actual due dates (even a week out — just so it surfaces again). Don't use Obsidian checkboxes for task tracking.

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
