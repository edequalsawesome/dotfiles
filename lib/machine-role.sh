#!/bin/bash
#
# Prompts for and records this machine's role — same on every OS.
# Written to ~/.machine-role for the (currently disabled) tmux auto-start
# hook in .zshrc, which distinguishes desktop (SSH-only) from server (always).

if [ ! -f "$HOME/.machine-role" ]; then
    echo ""
    echo "What role does this machine serve?"
    echo "  1) desktop  - tmux only on SSH connections (default)"
    echo "  2) server   - always start tmux (for machines accessed remotely)"
    printf "Choice [1]: "
    read -r role_choice < /dev/tty || role_choice=1
    case "$role_choice" in
        2|server) echo "server" > "$HOME/.machine-role" && echo "Machine role set to: server" ;;
        *)        echo "desktop" > "$HOME/.machine-role" && echo "Machine role set to: desktop" ;;
    esac
else
    echo "Machine role already set to: $(cat "$HOME/.machine-role")"
fi
