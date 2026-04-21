# Detect Moshi-originated connection (SSH or mosh from the Moshi iOS app).
# Moshi runs its own session picker and sends an explicit tmux attach after
# the shell starts, so we must NOT auto-start tmux here (that would race the
# picker and nest tmux inside itself, leaving Moshi's attach command visible
# in the inner pane). Also: mosh can't transport kitty graphics, so avoid
# fastfetch's image logo when connected via Moshi's mosh transport.
if [[ -n "$MOSHI_SESSION" ]]; then
  _is_moshi=1
fi
if [[ "$(ps -o comm= -p $PPID 2>/dev/null)" == *mosh-server ]]; then
  _is_mosh=1
fi

# Auto-start tmux based on machine role (~/.machine-role)
# "server" = always start tmux (for machines accessed primarily via remote)
# anything else / missing = only start tmux on SSH connections
# Skips if already in tmux, a mosh session, or a Moshi-managed connection
if [[ -z "$TMUX" ]] && [[ -z "$_is_mosh" ]] && [[ -z "$_is_moshi" ]]; then
  _machine_role=$(cat ~/.machine-role 2>/dev/null)
  if [[ "$_machine_role" == "server" ]] || [[ -n "$SSH_CONNECTION" ]]; then
    tmux new-session -A -s main
  fi
  unset _machine_role
fi

# Show system info with Rocket on shell open
# - tmux, zellij, mosh, or Moshi: text logo (no graphics protocol passthrough)
# - otherwise: kitty-direct image logo
# Alias persists so manual `fastfetch` invocations also use the text logo
# instead of falling back to fastfetch's built-in Apple ASCII.
if [[ -n "$TMUX" ]] || [[ -n "$ZELLIJ" ]] || [[ -n "$_is_mosh" ]] || [[ -n "$_is_moshi" ]]; then
  alias fastfetch='fastfetch --config ~/dotfiles/fastfetch/config-tmux.jsonc'
fi
fastfetch
unset _is_mosh _is_moshi

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
alias dotpull='git -C ~/dotfiles pull & git -C ~/Development/jiggyclaude pull & wait'
alias dev="cd ~/Development"
alias jiggybrain="cd ~/Obsidian/JiggyBrain"
alias cc='claude'
alias claude-yolo='claude --dangerously-skip-permissions'
alias ccyolo='claude --dangerously-skip-permissions'

# Work mode (Automattic API key + yolo)
alias claude-a8c='ANTHROPIC_API_KEY=$ANTHROPIC_API_KEY_A8C claude --dangerously-skip-permissions'
alias cca8c='ANTHROPIC_API_KEY=$ANTHROPIC_API_KEY_A8C claude --dangerously-skip-permissions'

# tmux variants (for SSH/remote sessions)
alias cc-tmux='tmux new-window -n claude-code -c ~/Claude "claude"'
alias ccyolo-tmux='tmux new-window -n claude-yolo -c ~/Claude "claude --dangerously-skip-permissions"'
alias cca8c-tmux='tmux new-window -n claude-a8c -c ~/Claude "ANTHROPIC_API_KEY=$ANTHROPIC_API_KEY_A8C claude --dangerously-skip-permissions"'

# cmux variants
alias ccx='cmux new-split right && cmux send "cd ~/Claude && claude\n"'

# TUI tools
alias lg='lazygit'
alias lw='~/Development/linear-worktree/linear-worktree'

# === ADDITIONAL TOOLS ===
# Bun completions
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# Cache brew prefix (avoid repeated shell-outs)
_brew_prefix=$(brew --prefix)

# Zsh autosuggestions
source $_brew_prefix/share/zsh-autosuggestions/zsh-autosuggestions.zsh

# Zsh syntax highlighting (must be near end of .zshrc)
source $_brew_prefix/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# iTerm2 shell integration (only inside iTerm2)
if [[ "$TERM_PROGRAM" == "iTerm.app" ]]; then
  test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"
fi

# Kiro code nonsense
[[ "$TERM_PROGRAM" == "kiro" ]] && . "$(kiro --locate-shell-integration-path zsh)"

# Use Secretive for SSH
export SSH_AUTH_SOCK="$HOME/Library/Containers/com.maxgoedjen.Secretive.SecretAgent/Data/socket.ssh"

# tabtab source for packages
# uninstall by removing these lines
[[ -f ~/.config/tabtab/zsh/__tabtab.zsh ]] && . ~/.config/tabtab/zsh/__tabtab.zsh || true

# fzf shell integration (fuzzy Ctrl+R history, Ctrl+T file finder)
source <(fzf --zsh)

# === CMUX WORKTREE FUNCTIONS ===
# Create git worktrees that auto-open as cmux split panes
wtree() {
  local branch="$1"
  local base="${2:-$(git rev-parse --abbrev-ref HEAD)}"

  if [[ -z "$branch" ]]; then
    echo "Usage: wtree <branch-name> [base-branch]"
    return 1
  fi

  local repo
  repo=$(basename "$(git rev-parse --show-toplevel 2>/dev/null)") || {
    echo "wtree: not inside a git repository"
    return 1
  }

  local wt_path="$HOME/Development/.worktrees/$repo/$branch"

  if [[ -d "$wt_path" ]]; then
    echo "Worktree already exists at $wt_path"
  elif git show-ref --verify --quiet "refs/heads/$branch" 2>/dev/null || \
       git show-ref --verify --quiet "refs/remotes/origin/$branch" 2>/dev/null; then
    git worktree add "$wt_path" "$branch"
  else
    git worktree add "$wt_path" -b "$branch" "$base"
  fi

  if [[ -n "$CMUX_WORKSPACE_ID" ]]; then
    local output
    output=$(cmux new-split right 2>&1)
    local surface
    surface=$(echo "$output" | grep -o 'surface:[0-9]*')
    if [[ -n "$surface" ]]; then
      cmux send --surface "$surface" "cd $wt_path\n"
      cmux rename-tab --surface "$surface" "$branch"
    else
      echo "wtree: cmux split failed: $output"
      cd "$wt_path"
    fi
  else
    cd "$wt_path"
  fi
}

wtree-list() {
  git worktree list
}

wtree-rm() {
  local branch="$1"
  if [[ -z "$branch" ]]; then
    echo "Usage: wtree-rm <branch-name>"
    return 1
  fi

  local repo
  repo=$(basename "$(git rev-parse --show-toplevel 2>/dev/null)") || {
    echo "wtree-rm: not inside a git repository"
    return 1
  }

  local wt_path="$HOME/Development/.worktrees/$repo/$branch"

  if [[ ! -d "$wt_path" ]]; then
    echo "wtree-rm: no worktree at $wt_path"
    return 1
  fi

  git worktree remove "$wt_path" && git worktree prune
  echo "Removed worktree: $branch ($wt_path)"
}

# moshi DIR — create/attach a tmux session rooted at a directory
moshi() {
  local dir="${1:-$PWD}"
  if [[ ! -d "$dir" ]]; then
    echo "Directory not found: $dir" >&2
    return 1
  fi

  local abs
  abs="$(cd "$dir" && pwd)"

  local session
  session="$(basename "$abs" | tr -cs '[:alnum:]_-' '-')"
  session="${session#-}"
  session="${session%-}"
  [[ -n "$session" ]] || session="main"

  if ! tmux has-session -t "$session" 2>/dev/null; then
    tmux new-session -d -s "$session" -c "$abs" -n agent
    tmux new-window -t "$session":2 -c "$abs" -n review
    tmux new-window -t "$session":3 -c "$abs" -n tests
    tmux new-window -t "$session":4 -c "$abs" -n servers
    tmux new-window -t "$session":5 -c "$abs" -n misc
  fi

  tmux attach -t "$session"
}

# Auto-label Zellij panes and tabs from the shell cwd:
# - Pane name  = cwd basename (per-pane; each pane labels itself)
# - Tab name   = git repo root basename, falling back to cwd basename
#   (stable across subdirs of the same project; override with Ctrl+t r)
if [[ -n "$ZELLIJ" ]]; then
  _zellij_rename_pane_and_tab() {
    local pane_name="${PWD##*/}"
    [[ "$PWD" == "$HOME" ]] && pane_name="~"
    command zellij action rename-pane "$pane_name" 2>/dev/null

    local repo tab_name
    repo=$(git rev-parse --show-toplevel 2>/dev/null)
    if [[ -n "$repo" ]]; then
      tab_name="${repo##*/}"
    else
      tab_name="$pane_name"
    fi
    command zellij action rename-tab "$tab_name" 2>/dev/null
  }
  autoload -Uz add-zsh-hook
  add-zsh-hook chpwd _zellij_rename_pane_and_tab
  _zellij_rename_pane_and_tab
fi

# Initialize Starship prompt (must be at the end)
eval "$(starship init zsh)"

# Mole shell completion
if output="$(mole completion zsh 2>/dev/null)"; then eval "$output"; fi
