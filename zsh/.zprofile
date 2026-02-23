# Ensure Homebrew is in PATH for login shells (SSH, Mosh, etc.)
# This is critical for remote connections that need to find mosh-server
if [[ $(uname -m) == "arm64" ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
else
    eval "$(/usr/local/bin/brew shellenv)"
fi

# OrbStack: command-line tools and integration
source ~/.orbstack/shell/init.zsh 2>/dev/null || :
