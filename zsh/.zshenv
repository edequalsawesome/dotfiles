# Ensure Homebrew is in PATH for ALL shell invocations
# This is critical for non-interactive SSH commands like mosh-server
if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
fi

# Source local secrets (not in dotfiles repo)
[[ -f ~/.secrets ]] && source ~/.secrets
