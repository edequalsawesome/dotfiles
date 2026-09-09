#!/bin/bash
#
# macOS bootstrap: Xcode CLT, Homebrew, and everything Homebrew-flavored.
# Repo cloning/updating and OS dispatch live in the top-level setup.sh.

DOTFILES_DIR="$HOME/dotfiles"

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

# Map LocalHostName -> friendly Brewfile suffix. Keep in sync with macos/bin/brewfile-sync.
host_to_friendly() {
    case "$(echo "$1" | tr '[:upper:]' '[:lower:]')" in
        jiggymini)      echo "jiggymini" ;;
        jiggybook-dev*) echo "jiggydev"  ;;
        jiggybook-pro*) echo "jiggybook" ;;
        jiggybook-air*) echo "jiggyair"  ;;
        *)              echo ""          ;;
    esac
}

echo "Setting up dotfiles from $DOTFILES_DIR..."

# Install Homebrew if not present
if ! command -v brew &> /dev/null; then
    echo "Homebrew not found. Installing Homebrew..."
    # </dev/tty so this works under `curl | bash`: stdin there is the pipe,
    # which makes Homebrew go non-interactive and fail its sudo check.
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" < /dev/tty

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

# Shared symlinks: zsh, ghostty, tmux, fastfetch, starship, zellij, cmux,
# git, claude settings template, bin/ — same on every OS.
source "$DOTFILES_DIR/lib/link-configs.sh"

# macOS-only symlinks
ln -sf "$DOTFILES_DIR/macos/aerospace/.aerospace.toml" ~/.aerospace.toml
mkdir -p ~/.config/awesomux
ln -sf "$DOTFILES_DIR/macos/awesomux/config.toml" ~/.config/awesomux/config.toml
mkdir -p "$HOME/Library/Application Support/Sublime Text/Packages/User"
ln -sf "$DOTFILES_DIR/macos/sublime/Preferences.sublime-settings" "$HOME/Library/Application Support/Sublime Text/Packages/User/Preferences.sublime-settings"
ln -sf "$DOTFILES_DIR/macos/sublime/Package Control.sublime-settings" "$HOME/Library/Application Support/Sublime Text/Packages/User/Package Control.sublime-settings"

# macOS-only bin scripts (Homebrew-flavored — not part of the shared bin/ loop)
mkdir -p ~/bin
for script in "$DOTFILES_DIR/macos/bin/"*; do
    [ -f "$script" ] && ln -sf "$script" ~/bin/$(basename "$script")
done

# Machine role (server = always use tmux, desktop = tmux only on SSH)
source "$DOTFILES_DIR/lib/machine-role.sh"

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

# Newer Homebrew refuses casks/formulae from untrusted third-party taps and
# aborts the whole `brew bundle` run. Trust every tap our Brewfiles use first.
# `brew trust` doesn't exist on older Homebrew — the `|| true` covers that.
grep -h '^tap ' "$DOTFILES_DIR"/macos/Brewfile* 2>/dev/null | cut -d'"' -f2 | sort -u | while read -r t; do
    brew trust --tap "$t" 2>/dev/null || true
done

# Install Homebrew packages: always install base, then optional host overlay.
if [ -f "$DOTFILES_DIR/macos/Brewfile" ]; then
    echo "Installing base Homebrew packages..."
    brew bundle install --file="$DOTFILES_DIR/macos/Brewfile"
else
    echo "Base Brewfile not found at $DOTFILES_DIR/macos/Brewfile - skipping base"
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

if [ -n "$FRIENDLY" ] && [ -f "$DOTFILES_DIR/macos/Brewfile.$FRIENDLY" ]; then
    echo "Installing host overlay: $FRIENDLY..."
    brew bundle install --file="$DOTFILES_DIR/macos/Brewfile.$FRIENDLY"
elif [ -n "$FRIENDLY" ]; then
    echo "No host overlay at $DOTFILES_DIR/macos/Brewfile.$FRIENDLY - skipping"
else
    echo "No host overlay mapping for $LOCAL_HOST - skipping"
    echo "  (edit host_to_friendly() in setup-macos.sh + macos/bin/brewfile-sync to add this machine)"
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