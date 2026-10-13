#!/usr/bin/env bash
# ===========================================
# install.sh — Link dotfiles & generate configs
# ===========================================
# Idempotent: safe to run multiple times.
# Backs up existing configs before overwriting.
#
# Usage:
#   ./install.sh           Install to system (symlinks + generated files)
#   ./install.sh --test    Generate to build/ directory for review (alias: --dry-run)
#   ./install.sh --yes     Install missing tools without prompting

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
BACKUP_SUFFIX=".bak.$(date +%Y%m%d%H%M%S)"

# ------------------------------------
# Arguments
# ------------------------------------

TEST_MODE=false
ASSUME_YES=false
for arg in "$@"; do
  case "$arg" in
    --test|--dry-run) TEST_MODE=true ;;
    -y|--yes) ASSUME_YES=true ;;
    -h|--help)
      cat <<'HELP'
Usage: ./install.sh [--test|--dry-run] [--yes]

  --test, --dry-run  Generate everything into build/ for review; touch nothing else
  -y, --yes          Install missing tools and frameworks without prompting
  -h, --help         Show this help
HELP
      exit 0
      ;;
    *) echo "Unknown option: $arg (see --help)" >&2; exit 1 ;;
  esac
done

if [ "$TEST_MODE" = true ]; then
  BUILD_DIR="$DOTFILES_DIR/build"
  rm -rf "$BUILD_DIR"
  mkdir -p "$BUILD_DIR"
fi

# ------------------------------------
# Helpers
# ------------------------------------

# shellcheck source=lib/install/helpers.sh
source "$DOTFILES_DIR/lib/install/helpers.sh"

# ------------------------------------
# Detect OS
# ------------------------------------

OS="$(uname -s)"
info "Detected OS" "$OS"

if [ "$TEST_MODE" = true ]; then
  info "Mode" "TEST — output to $BUILD_DIR"
fi
echo ""

# ------------------------------------
# Phases (lib/install/, run in order; each returns early when not needed)
# ------------------------------------

# shellcheck source=lib/install/config.sh
source "$DOTFILES_DIR/lib/install/config.sh"
# shellcheck source=lib/install/backup.sh
source "$DOTFILES_DIR/lib/install/backup.sh"
# shellcheck source=lib/install/deps.sh
source "$DOTFILES_DIR/lib/install/deps.sh"
# shellcheck source=lib/install/links.sh
source "$DOTFILES_DIR/lib/install/links.sh"
# shellcheck source=lib/install/gitconfig.sh
source "$DOTFILES_DIR/lib/install/gitconfig.sh"
# shellcheck source=lib/install/projects.sh
source "$DOTFILES_DIR/lib/install/projects.sh"
# shellcheck source=lib/install/claude.sh
source "$DOTFILES_DIR/lib/install/claude.sh"
# shellcheck source=lib/install/keyboard.sh
source "$DOTFILES_DIR/lib/install/keyboard.sh"
# shellcheck source=lib/install/hooks.sh
source "$DOTFILES_DIR/lib/install/hooks.sh"

# ===========================================
# Done
# ===========================================

echo ""
if [ "$TEST_MODE" = true ]; then
  echo "Test complete. Review generated files in: $BUILD_DIR"
  echo ""
  find "$BUILD_DIR" -type f | sort | while read -r f; do
    echo "  $f"
  done
else
  echo "Installation complete. Restart your shell or run: source ~/.zshrc"
fi
