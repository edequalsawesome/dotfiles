---
name: nerd-font-unicode-dotfiles
description: |
  Fix Nerd Font glyphs and powerline characters being silently stripped when editing
  dotfiles (starship.toml, tmux.conf, shell configs, etc.) with Claude Code's Write
  and Edit tools. Use when: (1) Powerline segment separators render as empty rectangles
  or disappear after file edits, (2) Nerd Font icons (OS symbols, folder icons, git
  symbols) vanish from config files, (3) Edit tool reports "string not found" when
  matching lines containing Nerd Font characters. Covers starship, tmux, shell prompts,
  and any config using Unicode Private Use Area codepoints.
author: Claude Code
version: 1.0.0
date: 2026-02-27
---

# Nerd Font Unicode in Dotfiles

## Problem
Claude Code's Write and Edit tools silently strip or fail to match Unicode characters
in the Private Use Area (PUA) ranges used by Nerd Fonts. This includes powerline
separator glyphs, OS icons, folder icons, git symbols, and language icons commonly
used in terminal prompt configurations (Starship, Powerlevel10k, tmux status bars).

## Context / Trigger Conditions
- Editing config files that contain Nerd Font icons (starship.toml, .tmux.conf, etc.)
- Write tool saves the file but PUA characters are silently dropped, leaving empty
  strings like `Macos = ""` or `[](surface0)` instead of `[](surface0)`
- Edit tool can't find `old_string` when it contains Nerd Font characters, because the
  characters don't round-trip correctly through the tool
- The file looks correct in the Read tool output but characters are actually missing
- Prompt segments render as flat rectangles instead of arrows/rounded shapes

## Affected Unicode Ranges
- **Powerline glyphs**: U+E0A0-E0A3, U+E0B0-E0B7 (arrows, rounded separators)
- **Nerd Font icons**: U+F0000-U+F1AF0+ (OS logos, folder icons, language symbols, etc.)
- **Devicons / Seti**: U+E700-E7C5
- **Font Awesome**: U+F000-F2E0
- **Material Design Icons**: U+F0001-U+F1AF0 (5-digit codepoints like U+F02A0)

## Solution

### For new files or full rewrites:
1. Use the Write tool to create the file with placeholder text where glyphs should go
   (e.g., empty strings or ASCII markers)
2. Use Python via Bash to insert the actual Unicode characters:

```python
python3 << 'PYEOF'
with open('/path/to/config.toml', 'r') as f:
    content = f.read()

# Powerline rounded separators
LEFT_ROUND = '\ue0b6'   # left half circle
RIGHT_ROUND = '\ue0b4'  # right half circle

# Powerline sharp arrows
LEFT_ARROW = '\ue0b2'   # left-pointing triangle
RIGHT_ARROW = '\ue0b0'  # right-pointing triangle

# Nerd Font icons (examples)
GHOST = '\U000F02A0'    # nf-md-ghost (5-digit codepoint needs uppercase \U)
APPLE = '\uf179'        # nf-fa-apple

# Replace placeholders
content = content.replace('PLACEHOLDER', GHOST)

with open('/path/to/config.toml', 'w') as f:
    f.write(content)
PYEOF
```

### For targeted edits to existing files with glyphs:
1. Do NOT use the Edit tool on lines containing Nerd Font characters (it will fail
   to match them)
2. Use Python to make surgical replacements:

```python
python3 -c "
with open('/path/to/config.toml', 'r') as f:
    content = f.read()

# Make your edit using string operations
content = content.replace('old text', 'new text')

with open('/path/to/config.toml', 'w') as f:
    f.write(content)
"
```

### For verifying glyphs are present:
```python
python3 -c "
with open('/path/to/config.toml', 'r') as f:
    content = f.read()
for ch in set(content):
    if ord(ch) > 0x7F:
        print(f'U+{ord(ch):04X}: {ch}')
" | sort
```

## Verification
- Run the verification script above to confirm PUA codepoints are present
- Check for specific expected codepoints (e.g., U+E0B4 for rounded right separator)
- Open a new terminal tab/window to see the prompt render correctly
- `cat -v` on the file will show multi-byte sequences for non-ASCII characters

## Example
Starship config with Catppuccin powerline preset:
1. Write the toml file with Write tool (glyphs get stripped from `[](red)` etc.)
2. Use Python to insert powerline glyphs and Nerd Font OS icons after the fact
3. Verify with the codepoint checker script

## Notes
- The `\ue0b6` syntax works for 4-digit codepoints in Python
- 5+ digit codepoints (common in Material Design Icons) need `\U000XXXXX` format
  with uppercase U and zero-padded to 8 digits
- `cat -v` on macOS doesn't support `-A` flag; use `cat -v` instead
- The Read tool can display these characters but the Edit tool can't match them
- `sed` also struggles with these characters; Python is the most reliable approach
- This affects ANY file with PUA Unicode, not just prompt configs
