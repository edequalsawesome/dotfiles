#!/bin/bash

# Check for Xcode Command Line Tools
if ! xcode-select -p &> /dev/null; then
    echo "Xcode Command Line Tools not found. Installing..."
    xcode-select --install
    echo ""
    echo "Please complete the Xcode Command Line Tools installation, then re-run this script."
    exit 1
else
    echo "Xcode Command Line Tools installed."
fi

# Set the dotfiles directory
DOTFILES_DIR="$HOME/dotfiles"

# Determine which Brewfile to use
select_brewfile() {
    local machine="$1"

    if [ -n "$machine" ] && [ -f "$DOTFILES_DIR/Brewfile.$machine" ]; then
        echo "$DOTFILES_DIR/Brewfile.$machine"
    elif [ -n "$machine" ] && [ "$machine" = "base" ]; then
        echo "$DOTFILES_DIR/Brewfile"
    elif [ -n "$machine" ]; then
        echo "Unknown machine profile: $machine" >&2
        echo "" >&2
        echo "Available machine profiles:" >&2
        echo "  base      - Base packages only" >&2
        for f in "$DOTFILES_DIR"/Brewfile.*; do
            [ -f "$f" ] && echo "  $(basename "$f" | sed 's/Brewfile\.//')      - $(basename "$f")" >&2
        done
        exit 1
    else
        # No argument provided - default to base
        echo "$DOTFILES_DIR/Brewfile"
    fi
}

echo "Downloading dotfiles from GitHub"

# Clone or update dotfiles repo
if [ ! -d "$DOTFILES_DIR" ]; then
    echo "Cloning dotfiles repository..."
    git clone https://github.com/edequalsawesome/dotfiles.git "$DOTFILES_DIR"
else
    echo "Updating dotfiles repository..."
    cd "$DOTFILES_DIR" && git pull
fi

echo "Setting up dotfiles from $DOTFILES_DIR..."

# Install Homebrew if not present
if ! command -v brew &> /dev/null; then
    echo "Homebrew not found. Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
    # Add Homebrew to PATH for Apple Silicon Macs
    if [[ $(uname -m) == "arm64" ]]; then
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
else
    echo "Homebrew already installed."
fi

# Create symlinks for config files
ln -sf "$DOTFILES_DIR/zsh/.zshrc" ~/.zshrc
mkdir -p ~/.config/ghostty
ln -sf "$DOTFILES_DIR/ghostty/config" ~/.config/ghostty/config

# Install Oh-My-Zsh
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "Installing Oh-My-Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
else
    echo "Oh-My-Zsh already installed."
fi

# Install Spaceship theme
if [ ! -d "$HOME/.oh-my-zsh/custom/themes/spaceship-prompt" ]; then
    echo "Installing Spaceship theme..."
    git clone https://github.com/spaceship-prompt/spaceship-prompt.git "$HOME/.oh-my-zsh/custom/themes/spaceship-prompt" --depth=1
    ln -s "$HOME/.oh-my-zsh/custom/themes/spaceship-prompt/spaceship.zsh-theme" "$HOME/.oh-my-zsh/custom/themes/spaceship.zsh-theme"
else
    echo "Spaceship theme already installed."
fi

# Install zsh-autosuggestions
if ! brew list zsh-autosuggestions &> /dev/null; then
    echo "Installing zsh-autosuggestions..."
    brew install zsh-autosuggestions
else
    echo "zsh-autosuggestions already installed."
fi

# Install Homebrew packages from local Brewfile
BREWFILE_PATH=$(select_brewfile "$1") || exit 1
if [ -f "$BREWFILE_PATH" ]; then
    echo "Installing Homebrew packages from $BREWFILE_PATH..."
    brew bundle install --file="$BREWFILE_PATH"
else
    echo "Brewfile not found at $BREWFILE_PATH - skipping package installation"
fi

# Install Claude Code via npm
if command -v npm &> /dev/null; then
    if npm list -g @anthropic-ai/claude-code &> /dev/null; then
        echo "Claude Code already installed."
    else
        echo "Installing Claude Code..."
        npm install -g @anthropic-ai/claude-code
    fi
else
    echo "npm not found - skipping Claude Code installation"
fi

echo "Dotfiles setup complete!"