---
name: session-doc
description: |
  Automatically create and maintain session documentation in Obsidian. Use when:
  (1) Starting any meaningful work session (not just Q&A), (2) After first substantive
  exchange in a session, (3) When claudeception extracts skills, (4) Before session ends.
  Creates markdown docs with proper frontmatter for work (a8c) vs personal (eT3) contexts.
author: Claude Code
version: 1.0.0
date: 2026-02-28
tags:
  - automation
  - documentation
  - obsidian
invocable: false
---

# Session Documentation

Automatically create and maintain session documentation throughout Claude Code sessions.

## Trigger Conditions

Create/update a session doc when:
1. **First meaningful exchange** - After the first substantive task (not just greetings or simple questions)
2. **Skill extraction** - When claudeception creates or updates a skill
3. **Session end** - Before the session concludes (sessions end abruptly, so don't wait)
4. **Major milestones** - When completing significant portions of work

## Path Selection

Infer from context - don't ask the user:

| Context | Path Pattern |
|---------|-------------|
| **Work** (Automattic, team management, HR, a8c) | `/Users/edequalsawesome/Obsidian/JiggyBrain/@a8c/!Logs/YYYY/MM/YYYY-MM-DD - [Topic].md` |
| **Everything else** (personal, tech, learning) | `/Users/edequalsawesome/Obsidian/JiggyBrain/Daily/YYYY/MM/YYYY-MM-DD - [Topic].md` |

## Frontmatter Templates

### Personal/Tech Sessions

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

### Work Sessions

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

## Content Structure

```markdown
## What we worked on
[Brief description of the task/problem]

## Key outcomes
[What works now, what was learned, what was built]

## Next steps
[If any - leave empty if truly complete]

## Rabbit holes
[Tangents, discoveries, gotchas worth remembering]
```

## Implementation

### Early Creation
After the first meaningful exchange:
1. Determine work vs personal context
2. Create the directory if needed: `mkdir -p "[path]/YYYY/MM"`
3. Create the doc with frontmatter and initial "What we worked on" section
4. Continue with the session

### Progressive Updates
As the session continues:
- Add key outcomes as they happen
- Note rabbit holes when discovered
- Update tldr to reflect current state

### Integration with Claudeception
When claudeception extracts a skill:
1. Add the skill path to "Rabbit holes" or "Key outcomes"
2. Update tldr if the skill represents the main work

## Example

After helping debug a tmux configuration:

```markdown
---
type: rollups
date: 2026-02-28
projects:
  - dotfiles
tags:
  - eT3
tldr: Configured tmux conditional status bar for laptop vs desktop. Discovered catppuccin flag gotchas.
---

## What we worked on
Conditional tmux status bar - battery on laptop, uptime on Mac mini.

## Key outcomes
- if-shell with pmset detects battery presence
- Catppuccin has built-in uptime module
- Flag discoveries: -ag vs -agF for shell commands, -g vs -gF for colors

## Next steps
- Test on laptop

## Rabbit holes
- Created skill: ~/.claude/skills/tmux-conditional-status-bar/SKILL.md
```

## Notes

- **Don't wait** - Sessions end abruptly, create early and update often
- **Infer context** - Don't ask work vs personal, figure it out from the conversation
- **Keep tldr tight** - Two sentences max, focus on what changed
- **Projects field** - Use existing project names when possible (dotfiles, docker, etc.)
