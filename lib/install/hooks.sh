# shellcheck shell=bash
# Sourced by install.sh — run local install hooks

# ===========================================
# Phase 7: Local install hooks
# ===========================================
# Each dir in DOTFILES_LOCAL_DIRS may ship an executable install.sh for setup
# that doesn't belong in this repo (e.g. linking CLAUDE.local.md files from a
# private repo). DOTFILES_DIR is passed in; to read settings, the hook can
# source "$DOTFILES_DIR/lib/dotfiles.sh" and call load_config. Skipped in test mode.

for local_dir in $DOTFILES_LOCAL_DIRS; do
  hook="$local_dir/install.sh"
  [ -x "$hook" ] || continue
  if [ "$TEST_MODE" = true ]; then
    info "$hook" "skipped (test mode)"
    continue
  fi
  echo ""
  echo "Running local hook $hook..."
  echo ""
  if DOTFILES_DIR="$DOTFILES_DIR" "$hook"; then
    success "$hook" ""
  else
    fail "$hook" "failed (exit $?)"
  fi
done
