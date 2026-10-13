# ===========================================
# Zsh Configuration
# ===========================================
# Machine-specific setup belongs in config.sh (settings), .secrets (tokens),
# or a local extensions dir (shell code) — never hardcoded here.

# ------------------------------------
# Dotfiles location
# ------------------------------------

# Resolve the repo from this file's real path (~/.zshrc is a symlink into shell/)
export DOTFILES_DIR="${${(%):-%x}:A:h:h}"
DOTFILES_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}/dotfiles"

# ------------------------------------
# Homebrew (macOS) — Apple Silicon installs outside the default PATH
# ------------------------------------

if [ -x /opt/homebrew/bin/brew ] && ! command -v brew > /dev/null 2>&1; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# ------------------------------------
# Config and secrets (loaded first)
# ------------------------------------

# Loaded as shell variables only, so tokens don't leak into every child process.
# Names listed in DOTFILES_EXPORT (space-separated) are exported explicitly.
for _f in "$DOTFILES_CONFIG_HOME/config.sh" "$DOTFILES_CONFIG_HOME/.secrets"; do
  [ -f "$_f" ] && source "$_f"
done
for _var in ${=DOTFILES_EXPORT:-}; do
  export "$_var"
done
unset _f _var

# Local extensions dirs: *.sh files are sourced, bin/ is added to PATH
DOTFILES_LOCAL_DIRS="${DOTFILES_LOCAL_DIRS:-$DOTFILES_CONFIG_HOME/local}"

# ------------------------------------
# Oh My Zsh
# ------------------------------------

export ZSH="$HOME/.oh-my-zsh"

# Theme is overridden by Starship (see bottom of file)
ZSH_THEME="robbyrussell"

# Plugins (keep list short — each one slows startup)
plugins=(git zsh-autosuggestions zsh-syntax-highlighting)

# Skip silently when Oh My Zsh isn't installed yet (install.sh sets it up)
[ -f "$ZSH/oh-my-zsh.sh" ] && source "$ZSH/oh-my-zsh.sh"

# ------------------------------------
# Editor
# ------------------------------------

# Override with EDITOR=... in config.sh
export EDITOR="${EDITOR:-nvim}"

# ------------------------------------
# Key Bindings (tmux-compatible)
# ------------------------------------

bindkey '^[^?' backward-kill-word        # Option+Backspace: delete word
bindkey '^[[1;3D' backward-word          # Option+Left: move word left
bindkey '^[[1;3C' forward-word           # Option+Right: move word right
bindkey '^[[H' beginning-of-line         # Home: start of line
bindkey '^[[F' end-of-line               # End: end of line

# ------------------------------------
# PATH
# ------------------------------------

# Prepend in reverse so the first listed entry wins
_path_prepend() { [ -d "$1" ] && path=("$1" ${path:#$1}); }
for _dir in ${(Oa)${=DOTFILES_PATH:-}}; do
  _path_prepend "$_dir"
done
for _dir in ${(Oa)${=DOTFILES_LOCAL_DIRS}}; do
  _path_prepend "$_dir/bin"
done
_path_prepend "$HOME/bin"
_path_prepend "$HOME/.local/bin"
unset _dir
unfunction _path_prepend

# ------------------------------------
# Tool Initialization
# ------------------------------------

# zoxide — smarter cd (powers sesh's directory source)
command -v zoxide > /dev/null 2>&1 && eval "$(zoxide init zsh)"

# ------------------------------------
# Aliases — static (from dotfiles repo)
# ------------------------------------

for _f in "$DOTFILES_DIR/shell/aliases/"*.sh(N); do
  source "$_f"
done

# ------------------------------------
# Aliases — generated (projects, Claude accounts, `dotfiles`)
# ------------------------------------

for _f in "$HOME/.aliases.d/"*.sh(N); do
  source "$_f"
done

# ------------------------------------
# Local extensions (not tracked) — tool inits, private aliases, hooks
# ------------------------------------

for _dir in ${=DOTFILES_LOCAL_DIRS}; do
  for _f in "$_dir/"*.sh(N); do
    source "$_f"
  done
done
unset _dir _f

# ------------------------------------
# Cursor — beam at prompt, block during command execution
# ------------------------------------

_set_beam_cursor() { printf '\e[5 q'; }
precmd_functions+=(_set_beam_cursor)

# ------------------------------------
# Prompt — Starship (must be last)
# ------------------------------------

command -v starship > /dev/null 2>&1 && eval "$(starship init zsh)"

return 0
