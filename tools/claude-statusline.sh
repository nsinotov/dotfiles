#!/usr/bin/env bash
# Claude Code status line:
#   [model · account] 📁 dir | 🌿 branch     ◑ 42% · 5h ○ 12% · 7d ◔ 30%
#   (right part is right-aligned on the same line when the terminal is wide
#   enough, otherwise it wraps to a second line; 5h/7d limits only for
#   claude.ai Pro/Max logins)
# Reads session JSON on stdin (see https://code.claude.com/docs/en/statusline).
# Requires jq.

input="$(cat)"

# ----------------------------------------
# Colors
# ----------------------------------------
CYAN=$'\033[36m'; YELLOW=$'\033[33m'; GREEN=$'\033[32m'; RED=$'\033[31m'
DIM=$'\033[2m'; RESET=$'\033[0m'

# pie <percent> — colored quarter-pie glyph rounded to the nearest 25%
# (green <70%, yellow <90%, red above)
pie() {
  local pct=$1 color idx glyphs=(○ ◔ ◑ ◕ ●)
  if   [ "$pct" -ge 90 ]; then color="$RED"
  elif [ "$pct" -ge 70 ]; then color="$YELLOW"
  else                         color="$GREEN"; fi
  idx=$(( (pct + 12) / 25 ))
  [ "$idx" -gt 4 ] && idx=4
  printf '%s%s%s' "$color" "${glyphs[$idx]}" "$RESET"
}

# ----------------------------------------
# Account name — derived from CLAUDE_CONFIG_DIR set by the claude-* functions
# (~/.claude-<name> → <name>); falls back to "default" for plain ~/.claude.
# ----------------------------------------
account="${CLAUDE_CONFIG_DIR##*/}"
account="${account#.claude-}"
case "$account" in ""|.claude) account="default" ;; esac

# ----------------------------------------
# Session data (one jq call; tab-separated, "-" marks an absent value because
# consecutive tabs would collapse in `read`)
# ----------------------------------------
IFS=$'\t' read -r model dir pct lim5 lim7 < <(
  jq -r '[
    (.model.display_name // "?"),
    (.workspace.current_dir // .cwd // "."),
    ((.context_window.used_percentage // 0) | floor),
    ((.rate_limits.five_hour.used_percentage // "-") | if type == "number" then floor else . end),
    ((.rate_limits.seven_day.used_percentage // "-") | if type == "number" then floor else . end)
  ] | @tsv' <<<"$input"
)

branch="$(git -C "$dir" symbolic-ref --short HEAD 2>/dev/null)"

# ----------------------------------------
# Left part: model/account, folder, branch
# ----------------------------------------
left="$(printf '%s[%s · %s]%s 📁 %s' "$CYAN" "$model" "$account" "$RESET" "${dir##*/}")"
[ -n "$branch" ] && left+=" | 🌿 $branch"

# ----------------------------------------
# Right part: context bar and subscription rate limits (5-hour and weekly
# windows, only when present)
# ----------------------------------------
right="$(pie "$pct") ${pct}%"
[ "$lim5" != "-" ] && right+=" · 5h $(pie "$lim5") ${lim5}%"
[ "$lim7" != "-" ] && right+=" · 7d $(pie "$lim7") ${lim7}%"

# ----------------------------------------
# Layout: one line with the right part right-aligned when it fits, else two
# lines. Width is read from the controlling tty because Claude Code pipes
# stdin/stdout (tput would just report 80); unknown width → two lines.
# ----------------------------------------
# UTF-8 locale so ${#var} counts characters, not bytes. Assigned explicitly:
# bash ignores an inherited LANG for ${#var}, only an in-script assignment works.
LC_ALL=en_US.UTF-8

# vwidth <string> — visible columns: strips ANSI codes, counts 📁/🌿 as 2 wide
# (⏱️ is already 2 code points, so it counts as 2 on its own)
vwidth() {
  local s t
  s="$(sed $'s/\033\\[[0-9;]*m//g' <<<"$1")"
  # Delete the emojis and diff lengths ([^📁🌿] is broken in macOS bash 3.2)
  t="${s//📁/}"; t="${t//🌿/}"
  echo $(( ${#s} * 2 - ${#t} ))
}

# Columns reserved for Claude Code's own status-line padding
MARGIN=4
cols="$({ stty size </dev/tty; } 2>/dev/null | cut -d' ' -f2)"
cols="${cols:-${COLUMNS:-0}}"
gap=$(( cols - MARGIN - $(vwidth "$left") - $(vwidth "$right") ))

if [ "$cols" -gt 0 ] && [ "$gap" -ge 2 ]; then
  printf '%s%*s%s\n' "$left" "$gap" '' "$right"
else
  printf '%s\n%s\n' "$left" "$right"
fi
