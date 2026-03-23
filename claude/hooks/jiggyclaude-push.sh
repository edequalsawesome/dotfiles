#!/bin/bash
# PostToolUse hook: auto-push jiggyclaude after claudeception extracts a skill
# Triggered on Skill tool calls, filters to only claudeception

JIGGY_DIR="$HOME/Development/jiggyclaude"

# Only act on claudeception skill calls
if [ "$CLAUDE_TOOL_NAME" != "Skill" ]; then
  exit 0
fi

# Check if this was the claudeception skill
if ! echo "$CLAUDE_TOOL_INPUT" | grep -q "claudeception"; then
  exit 0
fi

# Check if there are any changes to push
cd "$JIGGY_DIR" || exit 0
if git diff --quiet && git diff --cached --quiet && [ -z "$(git ls-files --others --exclude-standard)" ]; then
  exit 0
fi

# Stage, commit, and push
git add -A
git commit -m "Auto-push: claudeception skill extraction" --no-gpg-sign 2>/dev/null
git push origin main 2>/dev/null

exit 0
