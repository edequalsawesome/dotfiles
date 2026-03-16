#!/bin/bash

# Session Doc Auto-Reminder Hook
# Reminds Claude to create/update session documentation in Obsidian.
# Independent from claudeception — safe to update either without affecting the other.

cat << 'EOF'
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📝 SESSION DOCUMENTATION REMINDER
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

If this is a substantive work session (not just a quick Q&A), you MUST
create a session doc after the first meaningful exchange. Don't wait —
sessions end abruptly and context is lost.

PROTOCOL:
1. After the first substantive exchange, create the session doc
2. Update it as the session progresses (key outcomes, rabbit holes)
3. Path is based on context:
   - Work (Automattic/a8c): @a8c/!Logs/YYYY/MM/
   - Everything else: Daily/YYYY/MM/

If a session doc already exists for this topic today, UPDATE it
instead of creating a new one.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF
