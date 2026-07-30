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

# desc: Start the anyray proxy if it is not running
# help
anyray-start() {
  if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
    echo "Usage: anyray-start"
    echo "Ensures the anyray proxy is running at 127.0.0.1:8785."
    echo "Starts the LaunchAgent if the proxy is not responding."
    return 0
  fi

  local plist="$HOME/Library/LaunchAgents/ai.anyray.connect.fallback.plist"

  if lsof -i :8785 -sTCP:LISTEN -t > /dev/null 2>&1; then
    echo "anyray proxy is already running"
    return 0
  fi

  if [ ! -f "$plist" ]; then
    echo "error: anyray is not installed (plist not found)" >&2
    return 1
  fi

  echo "anyray proxy is down — starting..."
  launchctl bootstrap "gui/$(id -u)" "$plist" 2>/dev/null \
    || launchctl load "$plist" 2>/dev/null \
    || true

  local i=0
  while ! lsof -i :8785 -sTCP:LISTEN -t > /dev/null 2>&1 && [ "$i" -lt 20 ]; do
    sleep 0.5
    i=$((i + 1))
  done

  if lsof -i :8785 -sTCP:LISTEN -t > /dev/null 2>&1; then
    echo "anyray proxy started"
  else
    echo "error: anyray proxy failed to start" >&2
    return 1
  fi
}
