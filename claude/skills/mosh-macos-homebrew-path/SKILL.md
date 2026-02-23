---
name: mosh-macos-homebrew-path
description: |
  Fix "Failed to start Mosh on Server" or "mosh-server not found" errors on macOS with
  Homebrew-installed mosh. Use when: (1) Mosh client connects but server fails to start,
  (2) SSH works but Mosh doesn't, (3) mosh-server is installed via Homebrew but remote
  connections can't find it. The root cause is shell initialization: .zprofile only loads
  for login shells, but SSH commands run in non-login shells. Solution requires .zshenv.
author: Claude Code
version: 1.0.0
date: 2026-02-23
---

# Mosh macOS Homebrew PATH Fix

## Problem

When connecting to a Mac via Mosh (from iOS apps like Moshi, or other Mosh clients), the
connection fails with "Failed to start Mosh on Server" even though mosh-server is installed
via Homebrew and works locally.

## Context / Trigger Conditions

- Mosh client shows "Failed to start Mosh on Server" or similar
- SSH connections to the same host work fine
- `mosh-server` works when run locally in a terminal
- mosh-server is installed via Homebrew (`/opt/homebrew/bin/mosh-server`)
- The Mac is running zsh as the default shell
- Often occurs with Tailscale or other VPN setups, but the VPN isn't the issue

## Root Cause

When a Mosh client connects, it runs something like `ssh host mosh-server new` to start
the server. This SSH command invocation is a **non-login, non-interactive shell**.

The common advice to add Homebrew to PATH in `~/.zprofile` doesn't work because:
- `.zprofile` is only sourced for **login shells**
- SSH command execution (`ssh host command`) uses **non-login shells**
- `.zshenv` is sourced for **ALL zsh invocations** (login, non-login, interactive, non-interactive)

## Solution

### Step 1: Create ~/.zshenv with Homebrew PATH

```bash
# ~/.zshenv
# Ensure Homebrew is in PATH for ALL shell invocations
# Critical for non-interactive SSH commands like mosh-server
if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
fi
```

### Step 2: (Optional) Add mosh-server to macOS Firewall

If the macOS firewall is enabled, add mosh-server to the allowlist:

```bash
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --add /opt/homebrew/Cellar/mosh/*/bin/mosh-server
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --unblockapp /opt/homebrew/Cellar/mosh/*/bin/mosh-server
```

Note: If using Tailscale, firewall changes may not be necessary since traffic goes through
the Tailscale tunnel.

### Step 3: Verify PATH in Non-Login Shell

```bash
zsh -c 'which mosh-server'
# Should output: /opt/homebrew/bin/mosh-server
```

## Verification

1. Run `zsh -c 'which mosh-server'` - should find the binary
2. Connect from your Mosh client - should succeed
3. Check `zsh -l -c 'echo $PATH'` to verify PATH includes `/opt/homebrew/bin`

## Shell Initialization File Reference

| File | When Sourced | Use Case |
|------|--------------|----------|
| `.zshenv` | ALL invocations | PATH for non-interactive commands |
| `.zprofile` | Login shells only | Login-specific setup |
| `.zshrc` | Interactive shells | Aliases, prompts, completions |

## Example: Dotfiles Integration

For portable dotfiles, create both files:

```bash
# In your dotfiles repo
mkdir -p zsh
cat > zsh/.zshenv << 'EOF'
if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
fi
EOF

# Symlink during setup
ln -sf ~/dotfiles/zsh/.zshenv ~/.zshenv
```

## Notes

- This applies to ANY Homebrew-installed tool you want available via SSH commands, not just mosh
- The same issue affects `rsync`, `git`, or any other tool invoked via `ssh host command`
- Intel Macs use `/usr/local/bin/brew`, Apple Silicon uses `/opt/homebrew/bin/brew`
- If you have both `.zprofile` and `.zshenv` setting PATH, that's fine - redundancy is safe here
- OrbStack and similar tools that modify shell init files may also need entries in `.zshenv`

## Related

- Moshi iOS app: https://getmoshi.app
- Mosh project: https://mosh.org
- Zsh startup files: https://zsh.sourceforge.io/Intro/intro_3.html
