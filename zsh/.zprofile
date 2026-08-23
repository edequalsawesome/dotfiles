# Ensure Homebrew is in PATH for login shells (SSH, Mosh, etc.)
# This is critical for remote connections that need to find mosh-server.
# Guarded with -x (rather than an arch check) so this is also a silent
# no-op on non-Homebrew systems like Arch.
if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
fi

# OrbStack: command-line tools and integration
source ~/.orbstack/shell/init.zsh 2>/dev/null || :

# Obsidian
export PATH="$PATH:/Applications/Obsidian.app/Contents/MacOS"
