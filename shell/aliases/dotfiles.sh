# ===========================================
# dotfiles — list and document every custom command
# ===========================================
# Reads doc markers at runtime, so new commands show up without reinstalling.
# Sources: shell/aliases/*.sh, ~/.aliases.d/*.sh (generated), local extension
# *.sh files, and scripts in ~/bin and local bin/ dirs.
#
# Markers, in a comment block directly above an alias or function (scripts
# end the block with "# command: <name>" instead):
#   # section: <title>      starts a section for the following commands
#   # desc: <one line>       required — the command is listed only with it
#   # usage: <arguments>     argument synopsis, without the command name
#   # arg: <name>  <text>    one line per argument or option
#   # detail: <text>         extra paragraph lines
#   # example: <command>     one line per example
#   # help                   the command also prints this via -h/--help
# A file-level "# module: <name>" hides its commands unless the module is enabled.

# _dotfiles_sources — every file that may contain doc markers
_dotfiles_sources() {
  local f dir
  # zsh aborts on globs without matches unless null_glob is set
  [ -n "${ZSH_VERSION:-}" ] && setopt local_options null_glob
  for f in "$DOTFILES_DIR"/shell/aliases/*.sh "$HOME"/.aliases.d/*.sh; do
    [ -f "$f" ] && printf '%s\n' "$f"
  done
  for dir in $(echo "${DOTFILES_LOCAL_DIRS:-${XDG_CONFIG_HOME:-$HOME/.config}/dotfiles/local}"); do
    for f in "$dir"/*.sh; do
      [ -f "$f" ] && [ "${f##*/}" != install.sh ] && printf '%s\n' "$f"
    done
  done
  # Scripts carry a "# command:" marker near the top
  for dir in "$HOME/bin" $(echo "${DOTFILES_LOCAL_DIRS:-}" | sed 's|\([^ ]*\)|\1/bin|g'); do
    for f in "$dir"/*; do
      [ -f "$f" ] && head -n 40 "$f" 2>/dev/null | grep -q '^# command:' && printf '%s\n' "$f"
    done
  done
  return 0
}

# _dotfiles_records — one record per documented command, fields separated by
# \037 and list items by \036:
#   section name usage help desc args details examples file
_dotfiles_records() {
  local default
  _dotfiles_sources | while IFS= read -r f; do
    # Commands without a "# section:" marker: local files get their own group
    case "$f" in
      "$DOTFILES_DIR"/*|"$HOME"/.aliases.d/*|"$HOME"/bin/*) default="Other" ;;
      *) default="Local extensions" ;;
    esac
    awk -v file="$f" -v default="$default" -v modules=" ${DOTFILES_MODULES:-} " '
      function reset() { desc=""; usage=""; help=0; args=""; details=""; examples="" }
      function add(list, item) { return list == "" ? item : list "\036" item }
      function emit(name) {
        if (desc != "" && (module == "" || index(modules, " " module " ") > 0))
          printf "%s\037%s\037%s\037%d\037%s\037%s\037%s\037%s\037%s\n",
            section, name, usage, help, desc, args, details, examples, file
        reset()
      }
      function value(line) { sub(/^[[:space:]]*#[[:space:]]*[a-z]+:[[:space:]]?/, "", line); return line }
      BEGIN { section = default; reset() }
      /^[[:space:]]*#[[:space:]]*section:/ { section = value($0); reset(); next }
      /^[[:space:]]*#[[:space:]]*module:/  { module = value($0); reset(); next }
      /^[[:space:]]*#[[:space:]]*desc:/    { desc = value($0); next }
      /^[[:space:]]*#[[:space:]]*usage:/   { usage = value($0); next }
      /^[[:space:]]*#[[:space:]]*arg:/     { args = add(args, value($0)); next }
      /^[[:space:]]*#[[:space:]]*detail:/  { details = add(details, value($0)); next }
      /^[[:space:]]*#[[:space:]]*example:/ { examples = add(examples, value($0)); next }
      /^[[:space:]]*#[[:space:]]*help[[:space:]]*$/ { help = 1; next }
      /^[[:space:]]*#[[:space:]]*command:/ { emit(value($0)); next }
      /^[[:space:]]*#/ { next }
      /^[[:space:]]*$/ { next }
      /^[[:space:]]*alias[[:space:]]+[A-Za-z0-9_-]+=/ {
        n = $0; sub(/^[[:space:]]*alias[[:space:]]+/, "", n); sub(/=.*/, "", n); emit(n); next
      }
      /^[[:space:]]*[A-Za-z0-9_-]+\(\)/ {
        n = $0; sub(/^[[:space:]]+/, "", n); sub(/\(.*/, "", n); emit(n); next
      }
      { reset() }
    ' "$f"
  done
}

# _dotfiles_doc <record> — full documentation for one command
_dotfiles_doc() {
  local section name usage help desc args details examples file item b="" r=""
  IFS=$'\037' read -r section name usage help desc args details examples file <<< "$1"
  [ -t 1 ] && b=$'\033[1m' r=$'\033[0m'
  printf '%s%s%s — %s\n\n' "$b" "$name" "$r" "$desc"
  printf '%sUsage%s\n  %s\n' "$b" "$r" "${name}${usage:+ $usage}"
  if [ -n "$args" ]; then
    printf '\n%sArguments%s\n' "$b" "$r"
    printf '%s\n' "$args" | tr '\036' '\n' | while IFS= read -r item; do printf '  %s\n' "$item"; done
  fi
  if [ -n "$details" ]; then
    printf '\n%sDetails%s\n' "$b" "$r"
    printf '%s\n' "$details" | tr '\036' '\n' | while IFS= read -r item; do printf '  %s\n' "$item"; done
  fi
  if [ -n "$examples" ]; then
    printf '\n%sExamples%s\n' "$b" "$r"
    printf '%s\n' "$examples" | tr '\036' '\n' | while IFS= read -r item; do printf '  %s\n' "$item"; done
  fi
  [[ "$file" == "$HOME"/* ]] && file="~${file#"$HOME"}"
  printf '\nSource: %s' "$file"
  [ "$help" = 1 ] && printf ' · also: %s --help' "$name"
  printf '\n'
}

# _dotfiles_list <verbose 0|1> [filter] — commands grouped by section
_dotfiles_list() {
  local verbose="$1" filter="${2:-}" last="" sig line b="" r="" d="" found=0
  local section name usage help desc args details examples file
  [ -t 1 ] && b=$'\033[1m' r=$'\033[0m' d=$'\033[2m'
  while IFS=$'\037' read -r section name usage help desc args details examples file; do
    [ -z "$name" ] && continue
    [ -n "$filter" ] && [[ "$name $desc" != *"$filter"* ]] && continue
    found=1
    if [ "$section" != "$last" ]; then
      printf '\n%s%s%s\n' "$b" "$section" "$r"
      last="$section"
    fi
    sig="${name}${usage:+ $usage}"
    if [ ${#sig} -le 34 ]; then
      printf '  %-34s %s\n' "$sig" "$desc"
    else
      printf '  %s\n  %-34s %s\n' "$sig" "" "$desc"
    fi
    if [ "$verbose" = 1 ] && [ -n "$examples" ]; then
      printf '%s\n' "$examples" | tr '\036' '\n' | while IFS= read -r line; do
        printf '  %-34s %s%s%s\n' "" "$d" "e.g. $line" "$r"
      done
    fi
  done <<< "$(_dotfiles_records)"
  [ "$found" = 0 ] && { echo "No commands match '$filter'." >&2; return 1; }
  return 0
}

# section: Help
# desc: List custom commands, or show the docs of one
# usage: [-v | <command> | <filter>]
# arg: -v, --verbose  List every command with its examples
# arg: <command>      Show full docs (usage, arguments, examples) for one command
# arg: <filter>       List only commands whose name or description contains the text
# example: dotfiles
# example: dotfiles tmux-session
# example: dotfiles wt
# example: dotfiles -v
# help
dotfiles() {
  local record
  case "${1:-}" in
    -h|--help)
      cat <<'HELP'
Usage: dotfiles [-v | <command> | <filter>]

List the custom commands provided by dotfiles, grouped by section.

Arguments:
  -v, --verbose  List every command with its examples
  <command>      Show full docs (usage, arguments, examples) for one command
  <filter>       List only commands whose name or description contains the text

Examples:
  dotfiles                  list all commands
  dotfiles tmux-session     full docs for tmux-session
  dotfiles wt               commands about worktrees
  dotfiles -v               everything, with examples
HELP
      return 0
      ;;
    "")
      echo "Custom commands from dotfiles — run 'dotfiles <command>' for details and examples"
      _dotfiles_list 0
      ;;
    -v|--verbose)
      echo "Custom commands from dotfiles, with examples"
      _dotfiles_list 1
      ;;
    *)
      record="$(_dotfiles_records | awk -F '\037' -v n="$1" '$2 == n { print; exit }')"
      if [ -n "$record" ]; then
        _dotfiles_doc "$record"
      else
        _dotfiles_list 0 "$1"
      fi
      ;;
  esac
}
