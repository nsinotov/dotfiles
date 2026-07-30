# ------------------------------------
# anyray — work proxy manager
# ------------------------------------
# anyray routes Claude/OpenAI API traffic through a company proxy.
# Only relevant when a work account is configured (CLAUDE_SYMLINK_ACCOUNT in .secrets).
# Adds anyray bin to PATH so anyray-connect is accessible when installed.

if [ -n "${CLAUDE_SYMLINK_ACCOUNT:-}" ] && [ -d "$HOME/.anyray/bin" ]; then
  case ":$PATH:" in
    *:"$HOME/.anyray/bin":*) ;;
    *) export PATH="$HOME/.anyray/bin:$PATH" ;;
  esac
fi
