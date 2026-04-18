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

# Map LocalHostName -> friendly Brewfile suffix. Keep in sync with bin/brewfile-sync.
host_to_friendly() {
    case "$(echo "$1" | tr '[:upper:]' '[:lower:]')" in
        jiggymini)     echo "jiggymini" ;;
        jiggybook-pro) echo "jiggybook" ;;
        jiggybook-air) echo "jiggyair"  ;;
        *)             echo ""          ;;
    esac
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

    # Verify Homebrew installed successfully
    if ! command -v brew &> /dev/null; then
        echo ""
        echo "ERROR: Homebrew installation failed."
        echo "If you piped this script from curl, download and run it directly instead:"
        echo "  curl -L https://raw.githubusercontent.com/edequalsawesome/dotfiles/main/setup.sh -o /tmp/setup.sh && bash /tmp/setup.sh"
        exit 1
    fi
else
    echo "Homebrew already installed."
fi

# Create symlinks for config files
ln -sf "$DOTFILES_DIR/zsh/.zshrc" ~/.zshrc
ln -sf "$DOTFILES_DIR/zsh/.zprofile" ~/.zprofile
ln -sf "$DOTFILES_DIR/zsh/.zshenv" ~/.zshenv
mkdir -p ~/.config/ghostty
ln -sf "$DOTFILES_DIR/ghostty/config" ~/.config/ghostty/config
ln -sf "$DOTFILES_DIR/tmux/.tmux.conf" ~/.tmux.conf
mkdir -p ~/.config/fastfetch
ln -sf "$DOTFILES_DIR/fastfetch/config.jsonc" ~/.config/fastfetch/config.jsonc
mkdir -p ~/.config
ln -sf "$DOTFILES_DIR/starship/starship.toml" ~/.config/starship.toml
ln -sf "$DOTFILES_DIR/aerospace/.aerospace.toml" ~/.aerospace.toml
mkdir -p ~/.config/zellij/layouts
ln -sf "$DOTFILES_DIR/zellij/config.kdl" ~/.config/zellij/config.kdl
for layout in "$DOTFILES_DIR/zellij/layouts/"*.kdl; do
    [ -f "$layout" ] && ln -sf "$layout" ~/.config/zellij/layouts/$(basename "$layout")
done
mkdir -p ~/.config/cmux
ln -sf "$DOTFILES_DIR/cmux/settings.json" ~/.config/cmux/settings.json
mkdir -p ~/.claude

# Claude Code runtime config (CLAUDE.md, skills, hooks, settings)
# is managed by jiggyclaude/setup-workspace.sh — not dotfiles.
# Only the settings template lives here for bootstrapping new machines.

# Set up Claude Code settings (contains API keys - not in repo)
if [ ! -f ~/.claude/settings.json ]; then
    if [ -f "$DOTFILES_DIR/claude/settings.json.template" ]; then
        cp "$DOTFILES_DIR/claude/settings.json.template" ~/.claude/settings.json
        echo "Claude Code settings.json created from template."
        echo "NOTE: Edit ~/.claude/settings.json to add your API keys."
    fi
else
    echo "Claude Code settings.json already exists (not overwriting)."
fi

# Set machine role (server = always use tmux, desktop = tmux only on SSH)
if [ ! -f "$HOME/.machine-role" ]; then
    echo ""
    echo "What role does this machine serve?"
    echo "  1) desktop  - tmux only on SSH connections (default)"
    echo "  2) server   - always start tmux (for machines accessed remotely)"
    printf "Choice [1]: "
    read -r role_choice
    case "$role_choice" in
        2|server) echo "server" > "$HOME/.machine-role" && echo "Machine role set to: server" ;;
        *)        echo "desktop" > "$HOME/.machine-role" && echo "Machine role set to: desktop" ;;
    esac
else
    echo "Machine role already set to: $(cat "$HOME/.machine-role")"
fi

# Set up ~/bin and scripts
mkdir -p ~/bin
for script in "$DOTFILES_DIR/bin/"*; do
    [ -f "$script" ] && ln -sf "$script" ~/bin/$(basename "$script")
done

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

# Install zsh-syntax-highlighting
if ! brew list zsh-syntax-highlighting &> /dev/null; then
    echo "Installing zsh-syntax-highlighting..."
    brew install zsh-syntax-highlighting
else
    echo "zsh-syntax-highlighting already installed."
fi

# Install starship prompt
if ! command -v starship &> /dev/null; then
    echo "Installing starship..."
    brew install starship
else
    echo "starship already installed."
fi

# Install Homebrew packages: always install base, then optional host overlay.
if [ -f "$DOTFILES_DIR/Brewfile" ]; then
    echo "Installing base Homebrew packages..."
    brew bundle install --file="$DOTFILES_DIR/Brewfile"
else
    echo "Base Brewfile not found at $DOTFILES_DIR/Brewfile - skipping base"
fi

LOCAL_HOST="$(scutil --get LocalHostName 2>/dev/null || echo '')"
if [ -n "${1-}" ]; then
    FRIENDLY="$1"
else
    FRIENDLY=$(host_to_friendly "$LOCAL_HOST")
fi

# Validate friendly name is a safe path component — it becomes Brewfile.$FRIENDLY.
if [ -n "$FRIENDLY" ] && ! echo "$FRIENDLY" | grep -Eq '^[A-Za-z0-9._-]+$'; then
    echo "ERROR: invalid friendly name '$FRIENDLY' (allowed: A-Za-z0-9._-)" >&2
    exit 1
fi

if [ -n "$FRIENDLY" ] && [ -f "$DOTFILES_DIR/Brewfile.$FRIENDLY" ]; then
    echo "Installing host overlay: $FRIENDLY..."
    brew bundle install --file="$DOTFILES_DIR/Brewfile.$FRIENDLY"
elif [ -n "$FRIENDLY" ]; then
    echo "No host overlay at $DOTFILES_DIR/Brewfile.$FRIENDLY - skipping"
else
    echo "No host overlay mapping for $LOCAL_HOST - skipping"
    echo "  (edit host_to_friendly() in setup.sh + bin/brewfile-sync to add this machine)"
fi

# Install global npm packages
if command -v npm &> /dev/null; then
    if [ -f "$DOTFILES_DIR/npm-globals.txt" ]; then
        echo "Installing global npm packages..."
        cat "$DOTFILES_DIR/npm-globals.txt" | xargs npm install -g
    fi
else
    echo "npm not found - skipping global npm packages"
fi

# Install TPM (Tmux Plugin Manager)
if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
    echo "Installing Tmux Plugin Manager..."
    git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
    echo "TPM installed. Start tmux and press prefix + I to install plugins."
else
    echo "TPM already installed."
fi

# Install Catppuccin tmux theme
if [ ! -d "$HOME/.config/tmux/plugins/catppuccin/tmux" ]; then
    echo "Installing Catppuccin tmux theme..."
    mkdir -p "$HOME/.config/tmux/plugins/catppuccin"
    git clone https://github.com/catppuccin/tmux.git "$HOME/.config/tmux/plugins/catppuccin/tmux"
else
    echo "Catppuccin tmux theme already installed."
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

# Set up Claude Code MCP servers
echo ""
echo "To set up Claude Code MCP servers, run:"
echo "  ~/dotfiles/claude/setup-mcps.sh          # shared MCPs only"
echo "  ~/dotfiles/claude/setup-mcps.sh --work    # include work MCPs (context-a8c)"
echo ""

# Fix Tailscale MagicDNS CDN misrouting on macOS
# The Tailscale GUI app registers MagicDNS as a catch-all DNS resolver,
# which breaks CDN geolocation and tanks download speeds.
# This creates a domain-scoped resolver so only tailnet queries use MagicDNS.
TAILNET_DOMAIN="sungrazer-allosaurus.ts.net"
if command -v tailscale &> /dev/null; then
    tailscale set --accept-dns=false 2>/dev/null
    sudo mkdir -p /etc/resolver
    echo "nameserver 100.100.100.100" | sudo tee /etc/resolver/"$TAILNET_DOMAIN" > /dev/null
    echo "Tailscale DNS fix applied (split DNS via /etc/resolver/)."
else
    echo "Tailscale not found - skipping DNS fix."
fi

echo "Dotfiles setup complete!"