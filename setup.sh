#!/bin/bash

# Set the dotfiles directory
DOTFILES_DIR="$HOME/dotfiles"
BREWFILE_PATH="$HOME/Library/Mobile Documents/com~apple~CloudDocs/eT3_Dotfiles/Brewfile"

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

# Install Homebrew packages from iCloud
if [ -f "$BREWFILE_PATH" ]; then
    echo "Installing Homebrew packages..."
    brew bundle install --file="$BREWFILE_PATH"
else
    echo "Brewfile not found at $BREWFILE_PATH - skipping package installation"
fi

echo "Dotfiles setup complete!"