#!/bin/bash
#
# Set up Claude Code MCP servers
# Run once on a new machine after setup.sh
#
# API keys are read from ~/.secrets (not committed to git)
# Usage:
#   ./setup-mcps.sh           # install all shared MCPs
#   ./setup-mcps.sh --work    # also install work-specific MCPs (context-a8c)

set -e

# Load secrets for API keys
if [ -f ~/.secrets ]; then
    source ~/.secrets
else
    echo "WARNING: ~/.secrets not found. Some MCPs may need manual API key setup."
fi

echo "Setting up Claude Code MCP servers..."

# --- Shared MCPs (all machines) ---

claude mcp add memory -- npx -y @modelcontextprotocol/server-memory
echo "  ✓ memory"

claude mcp add context7 -- npx -y @upstash/context7-mcp@latest
echo "  ✓ context7"

claude mcp add todoist -- npx @greirson/mcp-todoist
echo "  ✓ todoist"

# Brave Search - needs API key from ~/.secrets
if [ -n "$BRAVE_API_KEY" ]; then
    claude mcp add brave-search -e BRAVE_API_KEY="$BRAVE_API_KEY" -- npx -y @modelcontextprotocol/server-brave-search
    echo "  ✓ brave-search"
else
    echo "  ⚠ brave-search skipped (BRAVE_API_KEY not set in ~/.secrets)"
fi

# Quill - only if installed
QUILL_BRIDGE="$HOME/Library/Application Support/Quill/mcp-stdio-bridge.js"
if [ -f "$QUILL_BRIDGE" ]; then
    claude mcp add quill -- node "$QUILL_BRIDGE"
    echo "  ✓ quill"
else
    echo "  ⚠ quill skipped (Quill not installed)"
fi

# --- Work MCPs (opt-in) ---

if [ "$1" = "--work" ]; then
    claude mcp add context-a8c -- npx -y @automattic/mcp-context-a8c
    echo "  ✓ context-a8c"
else
    echo ""
    echo "Skipping work MCPs. Run with --work to include context-a8c."
fi

echo ""
echo "MCP setup complete! Run 'claude mcp list' to verify."
