# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set the theme to spaceship
ZSH_THEME="spaceship"

# === SPACESHIP THEME CONFIGURATION ===
# Configure what sections to show and in what order
SPACESHIP_PROMPT_ORDER=(
  user              # Username section
  host              # Hostname section (when useful)
  dir               # Current directory section
  git               # Git section (git_branch + git_status)
  package           # Package version (package.json, etc.)
  node              # Node.js section
  bun               # Bun section
  python            # Python section
  ruby              # Ruby section
  rust              # Rust section
  golang            # Go section
  php               # PHP section
  docker            # Docker section
  aws               # AWS section
  gcloud            # Google Cloud section
  exec_time         # Execution time
  char              # Prompt character
)

# Configure individual sections
SPACESHIP_PROMPT_ADD_NEWLINE=true
SPACESHIP_CHAR_SYMBOL="🚀 "
SPACESHIP_CHAR_SUFFIX=" "

# Show user@host always (so you always see the username)
SPACESHIP_USER_SHOW=always
SPACESHIP_HOST_SHOW=always

# Configure directory display
SPACESHIP_DIR_TRUNC=2
SPACESHIP_DIR_TRUNC_REPO=false

# Configure git info
SPACESHIP_GIT_BRANCH_PREFIX=""
SPACESHIP_GIT_STATUS_SHOW=true
SPACESHIP_GIT_STATUS_PREFIX="["
SPACESHIP_GIT_STATUS_SUFFIX="]"

# Configure package info
SPACESHIP_PACKAGE_SHOW=true
SPACESHIP_PACKAGE_PREFIX="is "
SPACESHIP_PACKAGE_SYMBOL="📦 "

# Configure Node.js
SPACESHIP_NODE_SHOW=true
SPACESHIP_NODE_PREFIX="via "
SPACESHIP_NODE_SYMBOL="⬢ "

# Configure execution time
SPACESHIP_EXEC_TIME_SHOW=true
SPACESHIP_EXEC_TIME_PREFIX="took "
SPACESHIP_EXEC_TIME_ELAPSED=2

# Configure Docker display
SPACESHIP_DOCKER_SHOW=false
SPACESHIP_DOCKER_CONTEXT_SHOW=false

# Auto-update behavior
zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# History timestamp format
HIST_STAMPS="yyyy-mm-dd"

# Plugins
plugins=(git ssh)

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
)

# Bun
export BUN_INSTALL="$HOME/.bun"

# === ALIASES ===
alias claude="$HOME/.claude/local/claude"
alias brewdump="cd ~/Library/Mobile Documents/com~apple~CloudDocs/eT3_Dotfiles"
alias dotfiles="cd ~/dotfiles"

# === ADDITIONAL TOOLS ===
# Bun completions
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# Zsh autosuggestions
source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh

# iTerm2 shell integration (if exists)
test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

# Kiro code nonsense
[[ "$TERM_PROGRAM" == "kiro" ]] && . "$(kiro --locate-shell-integration-path zsh)"
