# Auto-start tmux on SSH connections (skip for Mosh — Moshi handles tmux itself)
if [[ -n "$SSH_CONNECTION" ]] && [[ -z "$TMUX" ]] && [[ "$(ps -o comm= -p $PPID 2>/dev/null)" != "mosh-server" ]]; then
  tmux new-session -A -s main
fi

# Show system info with Rocket on shell open (ASCII art in tmux, image outside)
if [[ -n "$TMUX" ]]; then
  fastfetch --config ~/dotfiles/fastfetch/config-tmux.jsonc
else
  fastfetch
fi

# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Disable oh-my-zsh theme (Starship handles the prompt)
ZSH_THEME=""

# Auto-update behavior
zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# History timestamp format
HIST_STAMPS="yyyy-mm-dd"

# Plugins
plugins=(git ssh z)

# Load Oh My Zsh (this loads spaceship with the above config)
source $ZSH/oh-my-zsh.sh

# === ENVIRONMENT SETUP ===
# Language
export LANG=en_US.UTF-8

# PATH additions
path+=(
  "$HOME/bin"
  "$HOME/.bun/bin"
  "$HOME/.lmstudio/bin"
  "$HOME/.codeium/windsurf/bin"
  "$HOME/.npm-global/bin"
  "$HOME/.local/bin"
)

# Bun
export BUN_INSTALL="$HOME/.bun"

# === ALIASES ===
alias brewdump="cd \"$HOME/Library/Mobile Documents/com~apple~CloudDocs/eT3_Dotfiles\""
alias dotfiles="cd ~/dotfiles"
alias dev="cd ~/Development"
alias jiggybrain="cd ~/Obsidian/JiggyBrain"
alias cc='tmux new-window -n claude-code -c ~/Claude "claude"'
alias ccdanger='tmux new-window -n claude-code -c ~/Claude "claude --dangerously-skip-permissions"'

# === ADDITIONAL TOOLS ===
# Bun completions
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# Zsh autosuggestions
source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh

# Zsh syntax highlighting (must be near end of .zshrc)
source $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# iTerm2 shell integration (only inside iTerm2)
if [[ "$TERM_PROGRAM" == "iTerm.app" ]]; then
  test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"
fi

# Kiro code nonsense
[[ "$TERM_PROGRAM" == "kiro" ]] && . "$(kiro --locate-shell-integration-path zsh)"

# Added by LM Studio CLI (lms)
export PATH="$PATH:/Users/edequalsawesome/.lmstudio/bin"
# End of LM Studio CLI section

# Use Secretive for SSH
export SSH_AUTH_SOCK=/Users/edequalsawesome/Library/Containers/com.maxgoedjen.Secretive.SecretAgent/Data/socket.ssh

# tabtab source for packages
# uninstall by removing these lines
[[ -f ~/.config/tabtab/zsh/__tabtab.zsh ]] && . ~/.config/tabtab/zsh/__tabtab.zsh || true

# Initialize Starship prompt (must be at the end)
eval "$(starship init zsh)"
