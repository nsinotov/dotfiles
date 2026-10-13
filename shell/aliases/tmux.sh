# ===========================================
# Tmux Aliases
# ===========================================
# module: tmux
# section: Tmux

[[ " ${DOTFILES_MODULES:-} " == *" tmux "* ]] || return 0

# ----
# Trigger a tmux-resurrect snapshot silently.
# Called after commands that create or remove sessions so the saved state
# (restored with prefix+R) stays in sync without a manual prefix+S.
_tmux_resurrect_save() {
  local save_script="$HOME/.tmux/plugins/tmux-resurrect/scripts/save.sh"
  # No-op when tmux isn't running or the plugin isn't installed.
  [ -x "$save_script" ] || return 0
  tmux has-session 2>/dev/null || return 0
  "$save_script" quiet >/dev/null 2>&1 || true
}

# ----
# desc: Create or attach to a tmux session for a directory
# usage: <directory> [windows-spec]
# arg: <directory>     Session root; offered to be created if missing
# arg: [windows-spec]  Space-separated "name:panes[:layout]" entries
# arg:                 (default: $TMUX_SESSION_WINDOWS or "bash:4:tiled agent:1 code:1")
# detail: The session is named after the directory; on a name clash the parent
# detail: folder is prepended. Switches to the session from inside tmux.
# example: tmux-session ~/projects/acme
# example: tmux-session . "editor:1 server:2:even-horizontal"
# help
tmux-session() {
  if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
    cat <<'HELP'
Usage: tmux-session <directory> [windows-spec]

Create or attach to a tmux session named after the directory. On a name clash
the parent folder is prepended. From inside tmux it switches to the session.

Arguments:
  <directory>     Session root; offered to be created if missing
  [windows-spec]  Space-separated "name:panes[:layout]" entries, one window each
                  (default: $TMUX_SESSION_WINDOWS or "bash:4:tiled agent:1 code:1")

Examples:
  tmux-session ~/projects/acme
  tmux-session . "editor:1 server:2:even-horizontal"
HELP
    return 0
  fi

  local dir="${1:-}"
  local windows="${2:-${TMUX_SESSION_WINDOWS:-bash:4:tiled agent:1 code:1}}"

  if [ -z "$dir" ]; then
    echo "Usage: tmux-session <directory> [windows-spec]" >&2
    return 1
  fi
  if [ ! -d "$dir" ]; then
    printf "Directory not found: %s\nCreate it? [y/N] " "$dir" >&2
    read -r reply
    if [ "$reply" = "y" ] || [ "$reply" = "Y" ]; then
      mkdir -p "$dir"
    else
      return 1
    fi
  fi

  local abs_dir
  abs_dir="$(cd "$dir" && pwd)"
  local name
  name="$(basename "$abs_dir")"

  # Collision: prepend parent folder, replacing any "/" with "-".
  if tmux has-session -t="$name" 2>/dev/null; then
    local parent
    parent="$(basename "$(dirname "$abs_dir")")"
    name="${parent}-${name}"
    name="${name//\//-}"
  fi

  if ! tmux has-session -t="$name" 2>/dev/null; then
    local first=true
    local win_spec win_name win_panes win_layout p
    # Split on whitespace in both zsh (no auto-split) and bash.
    local -a win_array
    if [ -n "${ZSH_VERSION:-}" ]; then
      win_array=(${=windows})
    else
      # shellcheck disable=SC2206
      win_array=($windows)
    fi
    for win_spec in "${win_array[@]}"; do
      IFS=':' read -r win_name win_panes win_layout <<< "$win_spec"
      win_panes="${win_panes:-1}"
      if [ "$first" = true ]; then
        tmux new-session -d -s "$name" -n "$win_name" -c "$abs_dir"
        first=false
      else
        tmux new-window -t "$name" -n "$win_name" -c "$abs_dir"
      fi
      for ((p=2; p<=win_panes; p++)); do
        tmux split-window -t "$name:$win_name" -c "$abs_dir"
      done
      if [ -n "${win_layout:-}" ]; then
        tmux select-layout -t "$name:$win_name" "$win_layout"
      fi
    done
    tmux select-window -t "$name:1"
    tmux select-pane -t "$name:1.1"
  fi

  _tmux_resurrect_save

  if [ -n "$TMUX" ]; then
    tmux switch-client -t "$name"
  else
    tmux attach -t "$name"
  fi
}
