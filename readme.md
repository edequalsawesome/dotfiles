# eD!'s Super-Fancy Dotfile Repo

Behold, my `dotfiles`, because keeping them in iCloud was stupid and keeping them here is easier. Ta-da.

## What's In Here

- **ZSH config** with Oh My Zsh and Spaceship theme
- **Ghostty terminal** config with decent padding so text doesn't assault my eyeballs, and fonts, and all sorts of other color/font tweaks
- **Setup script** that does all the boring stuff automatically, ya boi ain't got time for manual setups (there's dogs to be snuggled, after all)

## Quick Start

Fresh machine? Run this and have a li'l treat while you wait, you deserve it

```bash
curl -L https://raw.githubusercontent.com/edequalsawesome/dotfiles/main/setup.sh | bash
```

## What It Does

1. Clones this repo to ~/dotfiles
2. Installs Homebrew (if you don't have it)
3. Symlinks configs to the right places
4. Installs my apps from my private Brewfile (which remains stored in iCloud because I'm paranoid but also lazy)

## Manual Setup
If you don't trust random curl pipes (smart):
```bash
git clone https://github.com/edequalsawesome/dotfiles.git ~/dotfiles
cd ~/dotfiles
./setup.sh
```

## Notes

* The Brewfile lives in iCloud, not here (I'm overthinking it, but whatever, that's how I live my life)
* This assumes macOS because that's what I use
* Some paths might be weird if your username isn't "edequalsawesome" but the script should handle it

## License
Don't ask me for help, but otherwise go nuts, homies.