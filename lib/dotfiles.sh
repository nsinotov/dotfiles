# shellcheck shell=bash
# ===========================================
# lib/dotfiles.sh — shared by install.sh and check.sh (bash)
# ===========================================
# Settings live in two untracked files:
#   config.sh  — identity, modules, projects, Claude accounts, paths (no secrets)
#   .secrets   — tokens only (chmod 600), referenced by name from config.sh

DOTFILES_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}/dotfiles"
CONFIG_FILE="$DOTFILES_CONFIG_HOME/config.sh"
SECRETS_FILE="$DOTFILES_CONFIG_HOME/.secrets"

# Every tool is a module; nothing is set up unless listed in DOTFILES_MODULES:
#   zsh git cli tmux nvim starship sesh ghostty aerospace vpn claude keyboard-ua-ru

# load_config — source config.sh, then .secrets (both optional; later wins)
load_config() {
  local f
  for f in "$CONFIG_FILE" "$SECRETS_FILE"; do
    # shellcheck disable=SC1090
    [ -f "$f" ] && source "$f"
  done
  DOTFILES_MODULES="${DOTFILES_MODULES:-}"
  DOTFILES_LOCAL_DIRS="${DOTFILES_LOCAL_DIRS:-$DOTFILES_CONFIG_HOME/local}"
  return 0
}

# module_enabled <name> — true when the module is listed in DOTFILES_MODULES
module_enabled() {
  [[ " $DOTFILES_MODULES " == *" $1 "* ]]
}

# missing_requirements — one "required|needed-by|reason" line per module that
# the enabled modules or the configured features need but that isn't enabled
missing_requirements() {
  local i dir f has_projects=false has_tmux_windows=false has_git_emails=false has_local_sh=false
  for i in $(seq 1 99); do
    local name_var="PROJECT_${i}_NAME" tmux_var="PROJECT_${i}_TMUX_WINDOWS" email_var="PROJECT_${i}_GIT_EMAIL"
    [ -z "${!name_var:-}" ] && break
    has_projects=true
    [ -n "${!tmux_var:-}" ] && has_tmux_windows=true
    [ -n "${!email_var:-}" ] && has_git_emails=true
  done
  for dir in $DOTFILES_LOCAL_DIRS; do
    for f in "$dir"/*.sh; do
      [ -f "$f" ] && [ "${f##*/}" != install.sh ] && has_local_sh=true
    done
  done

  if ! module_enabled zsh; then
    module_enabled claude && echo "zsh|claude|Claude account functions are loaded by .zshrc"
    [ "$has_projects" = true ] && echo "zsh|projects|PROJECT_<N>_* commands are loaded by .zshrc"
    [ "$has_local_sh" = true ] && echo "zsh|local extensions|local *.sh files are sourced by .zshrc"
  fi
  if ! module_enabled tmux; then
    module_enabled sesh && echo "tmux|sesh|the sesh picker is a tmux binding (prefix+t)"
    [ "$has_tmux_windows" = true ] && echo "tmux|projects|PROJECT_<N>_TMUX_WINDOWS creates tmux sessions"
  fi
  if ! module_enabled git && [ "$has_git_emails" = true ]; then
    echo "git|projects|PROJECT_<N>_GIT_EMAIL is applied through the generated ~/.gitconfig"
  fi
  return 0
}

# claude_account <N> <FIELD> — value of CLAUDE_ACCOUNT_<N>_<FIELD> (empty if unset)
claude_account() {
  local var="CLAUDE_ACCOUNT_${1}_${2}"
  printf '%s' "${!var:-}"
}

# claude_config_dir <N> — account config dir, defaulting to ~/.claude-<name>
claude_config_dir() {
  local dir
  dir="$(claude_account "$1" CONFIG_DIR)"
  printf '%s' "${dir:-$HOME/.claude-$(claude_account "$1" NAME)}"
}
