#!/bin/bash

# JiggyClaude Auto-Push Hook
# Triggers after Write tool calls. If the written file is in the
# jiggyclaude skills directory, auto-commits and pushes to GitHub.

JIGGYCLAUDE_DIR="$HOME/Development/jiggyclaude"
SKILLS_DIR="$JIGGYCLAUDE_DIR/skills"

# Read tool use JSON from stdin
INPUT=$(cat)

# Extract the file_path from the Write tool input
FILE_PATH=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    print(data.get('tool_input', {}).get('file_path', ''))
except:
    print('')
" 2>/dev/null)

# Check if the file is in the jiggyclaude skills directory
if [[ "$FILE_PATH" == "$SKILLS_DIR"* ]]; then
    # Extract skill name from path
    SKILL_NAME=$(echo "$FILE_PATH" | sed "s|$SKILLS_DIR/||" | cut -d'/' -f1)

    # Auto-commit and push in the background
    (
        cd "$JIGGYCLAUDE_DIR" || exit
        git add "skills/$SKILL_NAME/"
        if git diff --cached --quiet; then
            exit 0  # Nothing to commit
        fi
        git commit -m "Update skill: $SKILL_NAME

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>"
        git pull --rebase origin main 2>/dev/null
        git push origin main 2>/dev/null
    ) &>/dev/null &

    echo "Auto-pushing jiggyclaude skill: $SKILL_NAME"
fi
