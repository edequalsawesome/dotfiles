#!/bin/bash
#
# Symlinks the cross-platform configs into place — same on macOS and Arch.
# Sourced by macos/setup-macos.sh and arch/setup-arch.sh; OS-specific bits
# (aerospace, sublime, Brewfiles, awesomux, etc.) are linked by those scripts
# directly since they don't apply everywhere.

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"

ln -sf "$DOTFILES_DIR/zsh/.zshrc" ~/.zshrc
ln -sf "$DOTFILES_DIR/zsh/.zprofile" ~/.zprofile
ln -sf "$DOTFILES_DIR/zsh/.zshenv" ~/.zshenv

mkdir -p ~/.config/ghostty
ln -sf "$DOTFILES_DIR/ghostty/config" ~/.config/ghostty/config

mkdir -p ~/.config/tmux
ln -sf "$DOTFILES_DIR/tmux/.tmux.conf" ~/.tmux.conf
# .tmux.conf calls this by that path on client-attach to swap the prefix.
ln -sf "$DOTFILES_DIR/tmux/prefix-swap.sh" ~/.config/tmux/prefix-swap.sh

mkdir -p ~/.config/fastfetch
ln -sf "$DOTFILES_DIR/fastfetch/config.jsonc" ~/.config/fastfetch/config.jsonc
ln -sf "$DOTFILES_DIR/fastfetch/config-tmux.jsonc" ~/.config/fastfetch/config-tmux.jsonc
ln -sf "$DOTFILES_DIR/fastfetch/rocket.png" ~/.config/fastfetch/rocket.png
ln -sf "$DOTFILES_DIR/fastfetch/rocket.txt" ~/.config/fastfetch/rocket.txt

mkdir -p ~/.config
ln -sf "$DOTFILES_DIR/starship/starship.toml" ~/.config/starship.toml

mkdir -p ~/.config/zellij/layouts
ln -sf "$DOTFILES_DIR/zellij/config.kdl" ~/.config/zellij/config.kdl
for layout in "$DOTFILES_DIR/zellij/layouts/"*.kdl; do
    [ -f "$layout" ] && ln -sf "$layout" ~/.config/zellij/layouts/$(basename "$layout")
done

mkdir -p ~/.config/cmux
ln -sf "$DOTFILES_DIR/cmux/settings.json" ~/.config/cmux/settings.json

ln -sf "$DOTFILES_DIR/git/.gitconfig" ~/.gitconfig
ln -sf "$DOTFILES_DIR/git/.gitconfig-a8c" ~/.gitconfig-a8c

# Claude Code runtime config (CLAUDE.md, skills, hooks, settings)
# is managed by jiggyclaude/setup-workspace.sh — not dotfiles.
# Only the settings template lives here for bootstrapping new machines.
mkdir -p ~/.claude
if [ ! -f ~/.claude/settings.json ]; then
    if [ -f "$DOTFILES_DIR/claude/settings.json.template" ]; then
        cp "$DOTFILES_DIR/claude/settings.json.template" ~/.claude/settings.json
        echo "Claude Code settings.json created from template."
        echo "NOTE: Edit ~/.claude/settings.json to add your API keys."
    fi
else
    echo "Claude Code settings.json already exists (not overwriting)."
fi

mkdir -p ~/bin
for script in "$DOTFILES_DIR/bin/"*; do
    [ -f "$script" ] && ln -sf "$script" ~/bin/$(basename "$script")
done
