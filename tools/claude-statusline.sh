#!/usr/bin/env bash
# Claude Code status line:
#   [model · account] 📁 dir | 🌿 branch
#   <context bar> 42% | 5h <bar> 12% | 7d <bar> 30% | $0.02 | ⏱️ 0m 2s
#   (5h/7d limits only for claude.ai Pro/Max logins)
# Reads session JSON on stdin (see https://code.claude.com/docs/en/statusline).
# Requires jq.

input="$(cat)"

# ----------------------------------------
# Colors
# ----------------------------------------
CYAN=$'\033[36m'; YELLOW=$'\033[33m'; GREEN=$'\033[32m'; RED=$'\033[31m'
DIM=$'\033[2m'; RESET=$'\033[0m'

# bar <percent> <width> — colored progress bar (green <70%, yellow <90%, red above)
bar() {
  local pct=$1 width=$2 color filled
  if   [ "$pct" -ge 90 ]; then color="$RED"
  elif [ "$pct" -ge 70 ]; then color="$YELLOW"
  else                         color="$GREEN"; fi
  filled=$(( pct * width / 100 ))
  [ "$filled" -gt "$width" ] && filled=$width
  printf '%s%s%s%s%s' "$color" \
    "$(printf '%*s' "$filled" '' | tr ' ' '█')" "$DIM" \
    "$(printf '%*s' "$((width - filled))" '' | tr ' ' '░')" "$RESET"
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
IFS=$'\t' read -r model dir pct cost dur_ms lim5 lim7 < <(
  jq -r '[
    (.model.display_name // "?"),
    (.workspace.current_dir // .cwd // "."),
    ((.context_window.used_percentage // 0) | floor),
    (.cost.total_cost_usd // 0),
    (.cost.total_duration_ms // 0),
    ((.rate_limits.five_hour.used_percentage // "-") | if type == "number" then floor else . end),
    ((.rate_limits.seven_day.used_percentage // "-") | if type == "number" then floor else . end)
  ] | @tsv' <<<"$input"
)

branch="$(git -C "$dir" symbolic-ref --short HEAD 2>/dev/null)"

# ----------------------------------------
# Line 1: model/account, folder, branch
# ----------------------------------------
printf '%s[%s · %s]%s 📁 %s' "$CYAN" "$model" "$account" "$RESET" "${dir##*/}"
[ -n "$branch" ] && printf ' | 🌿 %s' "$branch"
printf '\n'

# ----------------------------------------
# Line 2: context bar, subscription rate limits (5-hour and weekly windows,
# only when present), cost, duration
# ----------------------------------------
secs=$(( dur_ms / 1000 ))
printf '%s %s%%' "$(bar "$pct" 10)" "$pct"
[ "$lim5" != "-" ] && printf ' | 5h %s %s%%' "$(bar "$lim5" 6)" "$lim5"
[ "$lim7" != "-" ] && printf ' | 7d %s %s%%' "$(bar "$lim7" 6)" "$lim7"
printf ' | %s$%.2f%s | ⏱️ %dm %ds\n' \
  "$YELLOW" "$cost" "$RESET" "$((secs / 60))" "$((secs % 60))"
