# eD!'s Super-Fancy Dotfile Repo

Behold, my `dotfiles`, because keeping them in iCloud was stupid and keeping them here is easier. Ta-da.

## What's In Here

- **ZSH config** with Oh My Zsh and Spaceship theme
- **Ghostty terminal** config with decent padding so text doesn't assault my eyeballs, and fonts, and all sorts of other color/font tweaks
- **Setup script** that does all the boring stuff automatically, ya boi ain't got time for manual setups (there's dogs to be snuggled, after all)

Runs on macOS and Arch/Omarchy now. `setup.sh` at the top level just figures out which OS you're on and hands off:

```
setup.sh              # detects OS, dispatches below
macos/setup-macos.sh   # full bootstrap: Xcode CLT, Homebrew, Brewfiles, aerospace, Sublime, the works
arch/setup-arch.sh     # symlinks only, no package installs (see Arch/Omarchy note below)
lib/                    # symlink logic shared by both OS scripts
```

Everything at the top level (`zsh/`, `tmux/`, `ghostty/`, `starship/`, `zellij/`, `cmux/`, `git/`, `claude/`, `fastfetch/`, `bin/`) is cross-platform and gets linked the same way regardless of OS. Anything genuinely macOS-only (`aerospace/`, `sublime/`, the Brewfiles, `awesomux/`, `brewfile-sync`) lives under `macos/`.

## Quick Start

Fresh machine? Run this and have a li'l treat while you wait, you deserve it

```bash
curl -L https://raw.githubusercontent.com/edequalsawesome/dotfiles/main/setup.sh | bash
```

## What It Does

**macOS:**
1. Clones this repo to ~/dotfiles
2. Installs Homebrew (if you don't have it)
3. Symlinks configs to the right places
4. Installs my apps from my private Brewfile (which remains stored in iCloud because I'm paranoid but also lazy)

**Arch/Omarchy:**
1. Clones this repo to ~/dotfiles
2. Symlinks the cross-platform configs
3. Installs the framework bits those configs need (Oh My Zsh, Spaceship, TPM, Catppuccin tmux theme)
4. That's it — no pacman/AUR installs yet. It prints what's still manual (starship, the zsh plugins, Claude Code, npm globals) so I can add packages deliberately with `omarchy pkg add` as I actually need them, instead of dumping a pile of stuff on a machine I'm still getting a feel for.

## Manual Setup
If you don't trust random curl pipes (smart):
```bash
git clone https://github.com/edequalsawesome/dotfiles.git ~/dotfiles
cd ~/dotfiles
./setup.sh
```

## Notes

* The Brewfile lives in iCloud, not here (I'm overthinking it, but whatever, that's how I live my life)
* Some paths might be weird if your username isn't "edequalsawesome" but the script should handle it

## License
Don't ask me for help, but otherwise go nuts, homies.