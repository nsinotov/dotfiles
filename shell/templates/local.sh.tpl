# ===========================================
# Local Extensions Template
# ===========================================
# Machine- or company-specific shell code that must not live in this repo.
# Copy into a local extensions dir (default ~/.config/dotfiles/local/, more via
# DOTFILES_LOCAL_DIRS in config.sh — e.g. a checkout of a private repo):
#
#   <dir>/*.sh        sourced by .zshrc on every shell start (no install step)
#   <dir>/bin/        added to PATH — put standalone scripts here
#   <dir>/install.sh  executable hook run at the end of install.sh
#
# Settings and tokens come from config.sh / .secrets (shell variables, already
# loaded). Document commands with markers so `dotfiles` lists them (section
# "Local extensions" unless "# section:" says otherwise):
#
#   # desc: <one line>       required to be listed
#   # usage: <arguments>     synopsis without the command name
#   # arg: <name>  <text>    one line per argument
#   # detail: <text>         extra lines
#   # example: <command>     one line per example
#   # help                   the command also handles -h/--help
#
# Scripts in bin/ use the same markers near the top, ending with
# "# command: <name>".
#
# ------------------------------------
# Example: proxy started before a Claude account (CLAUDE_ACCOUNT_<N>_PRE_CMD)
# ------------------------------------
#
# # ~/.config/dotfiles/local/proxy.sh
# # Internal helper: start the company proxy if it isn't listening yet
# proxy_start() {
#   lsof -i :8080 -sTCP:LISTEN -t > /dev/null 2>&1 && return 0
#   echo "proxy is down — starting..."
#   launchctl bootstrap "gui/$(id -u)" "$HOME/Library/LaunchAgents/com.example.proxy.plist" 2>/dev/null
#   local i=0
#   until lsof -i :8080 -sTCP:LISTEN -t > /dev/null 2>&1; do
#     sleep 0.5; i=$((i + 1))
#     [ "$i" -ge 20 ] && { echo "error: proxy failed to start" >&2; return 1; }
#   done
# }
#
# ------------------------------------
# Example: tool initialization that used to be hardcoded in .zshrc
# ------------------------------------
#
# # ~/.config/dotfiles/local/tools.sh
# export NVM_DIR="$HOME/.nvm"
# [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
# [ -f /opt/anaconda3/etc/profile.d/conda.sh ] && . /opt/anaconda3/etc/profile.d/conda.sh
#
# (Plain PATH additions go to DOTFILES_PATH in config.sh instead.)
#
# ------------------------------------
# Example: project command using a token from .secrets
# ------------------------------------
#
# # ~/.config/dotfiles/local/acme.sh
# # section: Acme
# # desc: Open an Acme dashboard in the browser
# # usage: [env]
# # arg: [env]  staging (default) or production
# # example: acme-dash
# # example: acme-dash production
# # help
# acme-dash() {
#   if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
#     printf 'Usage: acme-dash [env]\n\nOpen an Acme dashboard (staging or production).\n'
#     return 0
#   fi
#   ACME_API_TOKEN="$ACME_API_TOKEN" acme-cli login && open "https://${1:-staging}.acme.example"
# }
#
# ------------------------------------
# Example: install hook (<dir>/install.sh, chmod +x)
# ------------------------------------
#
# #!/usr/bin/env bash
# # Link personal CLAUDE.local.md files kept in this private repo
# here="$(cd "$(dirname "$0")" && pwd)"
# ln -sfn "$here/claude/acme.md" "$HOME/projects/acme/repo/CLAUDE.local.md"
