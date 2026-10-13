# ===========================================
# Claude Code Account Template (module: claude)
# ===========================================
# Shows what install.sh generates into ~/.aliases.d/claude-accounts.sh from
# CLAUDE_ACCOUNT_<N>_* in ~/.config/dotfiles/config.sh.
#
#   CLAUDE_ACCOUNT_<N>_NAME        Function suffix (e.g. "proxy" → claude-proxy)
#   CLAUDE_ACCOUNT_<N>_CONFIG_DIR  (optional) Default ~/.claude-<name>
#   CLAUDE_ACCOUNT_<N>_ENV         (optional) Non-secret KEY=value pairs
#   CLAUDE_ACCOUNT_<N>_SECRET_ENV  (optional) KEY=SECRET_VAR pairs, value read
#                                  from $SECRET_VAR (.secrets) at launch
#   CLAUDE_ACCOUNT_<N>_PRE_CMD     (optional) Run before launch, abort on failure
#   CLAUDE_ACCOUNT_<N>_LINK_HOME   (optional) true → CONFIG_DIR symlinks to ~/.claude
#   CLAUDE_DEFAULT_ACCOUNT         (optional) Account plain `claude` runs (default: first)
#
# Example config.sh:
#
#   CLAUDE_ACCOUNT_1_NAME=proxy
#   CLAUDE_ACCOUNT_1_ENV="ANTHROPIC_BASE_URL=http://localhost:8080"
#   CLAUDE_ACCOUNT_1_SECRET_ENV="ANTHROPIC_AUTH_TOKEN=CLAUDE_PROXY_TOKEN"
#   CLAUDE_ACCOUNT_1_PRE_CMD="proxy_start"
#   CLAUDE_ACCOUNT_1_LINK_HOME=true
#   CLAUDE_ACCOUNT_2_NAME=personal
#   CLAUDE_DEFAULT_ACCOUNT=personal
#
# Example .secrets:
#
#   CLAUDE_PROXY_TOKEN=sk-...
#
# Generated output (the token itself never reaches this file):
#
#   claude-proxy() {
#     if [ -z "${CLAUDE_PROXY_TOKEN:-}" ]; then
#       echo "claude-proxy: CLAUDE_PROXY_TOKEN is not set in .secrets" >&2
#       return 1
#     fi
#     proxy_start || return 1
#     printf '\e]0;claude - proxy\a'
#     CLAUDE_CONFIG_DIR=/Users/jane/.claude-proxy \
#     ANTHROPIC_BASE_URL=http://localhost:8080 \
#     ANTHROPIC_AUTH_TOKEN="${CLAUDE_PROXY_TOKEN}" \
#     command claude "$@"
#   }
#
#   claude-personal() { ... CLAUDE_CONFIG_DIR=/Users/jane/.claude-personal command claude "$@"; }
#
#   claude() { claude-personal "$@"; }
#
# proxy_start is not part of this repo — define it in a local extensions file,
# e.g. ~/.config/dotfiles/local/proxy.sh (see local.sh.tpl).
