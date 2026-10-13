# shellcheck shell=bash
# Sourced by install.sh — install the UA-RU keyboard layout

# ===========================================
# Phase 6: Keyboard layout — UA-RU (macOS only)
# ===========================================
# Copies (does NOT symlink) the bundled UA-RU keyboard layout into
# ~/Library/Keyboard Layouts/. Every other config in this repo is symlinked
# (see link_file), but keyboard layouts are read by sandboxed processes —
# System Settings' KeyboardSettings pane, the talagentd input-source daemon,
# and sandboxed apps like Slack — that only have read entitlements for
# ~/Library/Keyboard Layouts/ itself, not for arbitrary paths like
# ~/.dotfiles/. A symlink resolving outside that directory gets a silent
# Sandbox file-read-data denial: the layout can look "enabled" while never
# actually working, and it disappears from the Input Sources "+" picker.
# A real copy avoids this. Re-run install.sh after editing the bundle to
# pick up changes — edits are NOT picked up automatically.
# Layout source: keyboards/UA-RU-layout.bundle (created with Ukelele)

if [ "$OS" = "Darwin" ] && module_enabled keyboard-ua-ru; then
  echo ""
  echo "Checking keyboard layout..."
  echo ""

  KBD_BUNDLE_SRC="$DOTFILES_DIR/keyboards/UA-RU-layout.bundle"
  KBD_BUNDLE_DST="$(target_path "$HOME/Library/Keyboard Layouts/UA-RU-layout.bundle")"
  _kbd_first_install=true
  { [ -e "$KBD_BUNDLE_DST" ] || [ -L "$KBD_BUNDLE_DST" ]; } && _kbd_first_install=false

  if [ -L "$KBD_BUNDLE_DST" ] || [ -e "$KBD_BUNDLE_DST" ]; then
    rm -rf "$KBD_BUNDLE_DST"
  fi
  mkdir -p "$(dirname "$KBD_BUNDLE_DST")"
  cp -R "$KBD_BUNDLE_SRC" "$KBD_BUNDLE_DST"
  success "$KBD_BUNDLE_DST" "(copied)"

  if [ "$_kbd_first_install" = true ] && [ "$TEST_MODE" = false ]; then
    echo ""
    info "  Action required" "Log out and back in, then:"
    info "  System Settings > Keyboard > Input Sources > +" "enable 'UA-RU-layout'"
  fi
  unset _kbd_first_install KBD_BUNDLE_SRC
fi
