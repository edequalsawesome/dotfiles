---
name: linear-metrics
description: Pull weekly metrics from SECSUP and DHMIG Linear queues in parallel for spreadsheet reporting. Use when you need to "pull Linear metrics", "get weekly metrics", "SECSUP stats", "DHMIG stats", "migrations and security stats", or "run /linear-metrics".
---

# Linear Weekly Metrics

Pull weekly metrics from SECSUP (security support) and DHMIG (assisted migrations) Linear queues for spreadsheet reporting.

## Usage

```
/linear-metrics 2026-02-02
```

Or ask naturally: "Pull Linear metrics for the week of February 2nd"

**Argument**: A Monday date (YYYY-MM-DD). If no date provided, ask for one.

## Validation

FIRST: Verify the provided date is a Monday. If not, alert the user and stop.

## Execution

Spawn **two parallel agents** to pull metrics simultaneously:

### Agent 1: SECSUP Metrics

Use `mcp__plugin_linear_linear__list_issues` for all API calls.

**Steps:**
1. Pull Done issues: `team="SECSUP" state="Done" updatedAt="-P21D" limit=250`
2. Pull In Review issues: `team="SECSUP" state="In Review" updatedAt="-P21D" limit=250`
3. Filter by `completedAt` within target week (>= Monday 00:00:00Z, < following Monday 00:00:00Z)
4. From Done issues, EXCLUDE those with "Escalated to Security Research" label (may have arrow emoji prefix)
5. Combine filtered Done + filtered In Review

**Calculate:**
- **Issues Completed**: Count of combined issues from step 5
- **Reinfections**: Count of issues with "Reinfection" label (may have emoji prefix)
- **95% Cycle Time**:
  a. Filter to issues where `createdAt` is ALSO within target week
  b. Calculate `(completedAt - createdAt)` in hours for each
  c. Sort ascending, find 95th percentile value
  d. Round to 2 decimal places

### Agent 2: DHMIG Metrics

**Steps:**
1. Pull Done issues: `team="DHMIG" state="Done" updatedAt="-P21D" limit=250`
2. Filter by `createdAt` within target week (>= Monday 00:00:00Z, < following Monday 00:00:00Z)
3. Filter: title must start with "Migration:" (excludes sub-issues)
4. Filter: labels must NOT include "Intake Issue"

**Calculate:**
- **Migrations Completed**: Count of filtered issues
- **Summer Special Plan**: Count of issues with "Summer Special Plan" label

**Note:** Cycle time cannot be accurately calculated via API (Linear measures from "In Progress", not creation). Note that P50/P95 should be pulled from the Linear dashboard manually.

## Output Format

Present results in this exact format:

```
=== SECSUP (Week of YYYY-MM-DD) ===
Issues Completed: XX
Reinfections: X
95% Cycle Time: X.XX hours

=== DHMIG (Week of YYYY-MM-DD) ===
Migrations Completed: XX
Summer Special Plan: X
(Cycle times from Linear dashboard: P50=?h, P95=?h)
```

## Technical Notes

- Week starts Monday 00:00:00 UTC, ends following Sunday 23:59:59 UTC
- Linear timestamps are ISO 8601 format with milliseconds
- SECSUP requires 2 API calls (Done + In Review states)
- DHMIG requires 1-2 API calls (Done, optionally Cancelled for Summer Special Plan)
- Large result sets may need pagination - check if results hit the 250 limit
- Label matching should be flexible (emoji prefixes like arrows may vary)

## Reference

Full methodology docs in the Obsidian vault:
- `@a8c/Claude Rules/Claude - Linear Weekly Metrics.md` - Combined reference
- `@a8c/Claude Rules/Claude - SECSUP Weekly Metrics.md` - SECSUP methodology
- `@a8c/Claude Rules/Claude - DHMIG Weekly Metrics.md` - DHMIG methodology
