#!/bin/bash
#
# Arch/Omarchy bootstrap. Deliberately minimal right now: just symlinks the
# shared configs and the dotfiles-framework installs those configs need to
# not error on startup (Oh My Zsh, Spaceship, TPM, Catppuccin tmux theme).
#
# No pacman/AUR package installs here yet — see the printed TODO at the end
# for what's still manual while getting a feel for what this machine needs.

set -e

DOTFILES_DIR="$HOME/dotfiles"

echo "Setting up dotfiles from $DOTFILES_DIR..."

# Shared symlinks: zsh, ghostty, tmux, fastfetch, starship, zellij, cmux,
# git, claude settings template, bin/ — same on every OS.
source "$DOTFILES_DIR/lib/link-configs.sh"

# Machine role (server = always use tmux, desktop = tmux only on SSH)
source "$DOTFILES_DIR/lib/machine-role.sh"

# Oh My Zsh — .zshrc sources this unconditionally, so it has to exist.
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "Installing Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
else
    echo "Oh My Zsh already installed."
fi

# Spaceship theme
if [ ! -d "$HOME/.oh-my-zsh/custom/themes/spaceship-prompt" ]; then
    echo "Installing Spaceship theme..."
    git clone https://github.com/spaceship-prompt/spaceship-prompt.git "$HOME/.oh-my-zsh/custom/themes/spaceship-prompt" --depth=1
    ln -sf "$HOME/.oh-my-zsh/custom/themes/spaceship-prompt/spaceship.zsh-theme" "$HOME/.oh-my-zsh/custom/themes/spaceship.zsh-theme"
else
    echo "Spaceship theme already installed."
fi

# TPM (Tmux Plugin Manager)
if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
    echo "Installing Tmux Plugin Manager..."
    git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
    echo "TPM installed. Start tmux and press prefix + I to install plugins."
else
    echo "TPM already installed."
fi

# Catppuccin tmux theme
if [ ! -d "$HOME/.config/tmux/plugins/catppuccin/tmux" ]; then
    echo "Installing Catppuccin tmux theme..."
    mkdir -p "$HOME/.config/tmux/plugins/catppuccin"
    git clone https://github.com/catppuccin/tmux.git "$HOME/.config/tmux/plugins/catppuccin/tmux"
else
    echo "Catppuccin tmux theme already installed."
fi

echo ""
echo "Dotfiles setup complete!"
echo ""
echo "Not installed (the configs degrade gracefully without these — add"
echo "whichever ones you actually want with 'omarchy pkg add <name>'):"
echo "  - starship                                   (pacman: starship)"
echo "  - zsh-autosuggestions / zsh-syntax-highlighting  (pacman, both in [extra])"
echo "  - Claude Code CLI                             (npm install -g @anthropic-ai/claude-code)"
echo "  - npm globals from npm-globals.txt            (xargs npm install -g < \"$DOTFILES_DIR/npm-globals.txt\")"
echo ""
echo "Once Claude Code is installed, set up MCP servers with:"
echo "  $DOTFILES_DIR/claude/setup-mcps.sh"
