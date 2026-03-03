---
name: process-quill
description: Process Quill meeting recordings into structured 1:1 notes with embedded transcripts. Creates notes in @a8c/One on Ones/ for Reactor team members and @a8c/Meetings/ for other meetings. Optionally creates follow-up tasks in Todoist.
---

# Process Quill Meetings

Process meeting recordings from Quill into structured notes for the Obsidian vault.

## MCP Server

This skill uses the **Quill MCP server** which provides tools prefixed with `mcp__quill__`:
- `mcp__quill__search_meetings` - Search and list meetings
- `mcp__quill__get_meeting` - Get meeting details
- `mcp__quill__get_minutes` - Get meeting minutes/summary
- `mcp__quill__get_transcript` - Get full transcript

The Quill MCP server must be configured and running for this skill to work.

## Usage

Use after having meetings recorded by Quill. Will prompt you to select which meetings to process, then creates properly formatted notes with summaries, action items, and full transcripts.

## What it Does

1. Lists recent Quill meetings for selection (via `mcp__quill__search_meetings`)
2. Spawns **`quill-processor`** agents (one per meeting, in parallel) to fetch and write notes
3. Each agent creates a structured note and returns a JSON summary
4. Extracts follow-ups and optionally creates tasks in **Todoist**

## Output Locations

- **1:1s with Reactor team**: `@a8c/One on Ones/YYYY-MM-DD - [Name].md`
- **Other meetings**: `@a8c/Meetings/YYYY-MM-DD - [Title].md`

## Instructions

See the full prompt template: [Claude - Process Quill Meetings](../../../@a8c/Claude Rules/Claude - Process Quill Meetings.md)
