# ===========================================
# Local Aliases Template
# ===========================================
# Drop a copy of this file (renamed) into ~/.config/dotfiles/aliases.d/
# to define extra aliases and functions that are sourced by .zshrc but
# never committed to the repo.
#
# Naming convention: <project>.sh  (e.g. voxia.sh, personal.sh)
#
# Commands are picked up by `dotfiles` when annotated with # desc:.
# Add # help on the next line if the command also accepts -h/--help.
#
# Secrets and tokens referenced here should be defined in
# ~/.config/dotfiles/.secrets alongside the project's PROJECT_N_* block.
#
# ------------------------------------
# Annotation format
# ------------------------------------
#
# # desc: One-line description shown in `dotfiles` listing
# # help
# my-command() { ... }
#
# # desc: An alias example
# alias my-alias='...'
#
# ------------------------------------
# Example: project dev tool with credentials from .secrets
# ------------------------------------
#
# # desc: Start Twilio dev phone
# voxia-dev-phones() {
#   TWILIO_AUTH_TOKEN="$TWILIO_AUTH_TOKEN" \
#   TWILIO_ACCOUNT_SID="$TWILIO_ACCOUNT_SID" \
#   twilio dev-phone
# }
#
# ------------------------------------
# Example: shortcut with --help support
# ------------------------------------
#
# # desc: Open the staging dashboard in the browser
# # help
# voxia-staging() {
#   if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
#     echo "Usage: voxia-staging"
#     echo "Open the staging dashboard in the default browser."
#     return 0
#   fi
#   open "https://staging.example.com"
# }
