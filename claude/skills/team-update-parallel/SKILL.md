---
name: team-update-parallel
description: Process Reactor team weekly updates using parallel agents for faster processing and better context management. Use when processing large weekly update files to avoid context overflow.
---

# Parallel Weekly Update Processing

Process team weekly updates using a Python splitter + parallel agents for faster processing and better context management.

## Usage

Use when new weekly updates are posted. This approach is preferred for large update files as it:
- Splits the big file into individual files first (Python script)
- Each agent reads only their small pre-split file (~1-3k tokens)
- Agents edit files in place
- Raw update text is preserved in each processed file

**IMPORTANT:** Agents MUST be spawned in the **foreground** (do NOT use `run_in_background: true`). Background agents cannot surface permission prompts for Edit tool calls and will silently fail. Foreground parallel agents still run concurrently when launched in a single message with multiple Task tool calls.

## How It Works

1. **Coordinator** escapes P2 hashtags in the source file
2. **Python script** splits the source into individual files with frontmatter + raw update text
3. **Parallel agents** spawn in the **foreground** for each team member -- each reads their small file and edits it in place to add analysis
4. **Coordinator** generates the team dashboard from agent results

## Instructions

See the full prompt template: [Claude - Team Update Parallel Processor](../../../@a8c/Claude Rules/Claude - Team Update Parallel Processor.md)
