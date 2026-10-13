# shellcheck shell=bash
# Sourced by install.sh — snapshot untracked configs

# ===========================================
# Phase 0: Backup non-tracked config files
# ===========================================
# Snapshots secrets, local alias files, and external tool configs that are
# part of the dotfiles setup but not managed by git. Runs before any changes.

if [ "$TEST_MODE" = false ]; then
  _BACKUP_TS="$(date +%Y%m%d%H%M%S)"
  _BACKUP_DIR="$DOTFILES_CONFIG_HOME/backups/$_BACKUP_TS"
  mkdir -p "$_BACKUP_DIR"
  # Snapshots hold secrets and auth configs — owner-only access to the whole tree
  chmod 700 "$DOTFILES_CONFIG_HOME" "$(dirname "$_BACKUP_DIR")"

  _backup_file() {
    local src="$1" rel="$2"
    [ -f "$src" ] || return 0
    mkdir -p "$_BACKUP_DIR/$(dirname "$rel")"
    cp "$src" "$_BACKUP_DIR/$rel"
    success "  $rel" "backed up"
  }

  _backup_dir() {
    local src="$1" rel="$2"
    [ -d "$src" ] || return 0
    cp -R "$src" "$_BACKUP_DIR/$rel"
    success "  $rel/" "backed up"
  }

  echo ""
  echo "Backing up non-tracked configs..."
  echo ""

  _backup_file "$CONFIG_FILE"                                           "config.sh"
  _backup_file "$SECRETS_FILE"                                          ".secrets"
  _backup_dir  "$DOTFILES_CONFIG_HOME/local"                           "local"
  _backup_dir  "$DOTFILES_CONFIG_HOME/aliases.d"                       "aliases.d"
  _backup_file "$DOTFILES_CONFIG_HOME/aerospace.local.toml"            "aerospace.local.toml"

  if module_enabled claude; then
    _backup_file "$HOME/.claude/settings.json"                         "claude/settings.json"
    for i in $(seq 1 99); do
      _acc_name="$(claude_account "$i" NAME)"
      [ -z "$_acc_name" ] && break
      _backup_file "$(claude_config_dir "$i")/settings.json"           "claude-${_acc_name}/settings.json"
    done
    unset _acc_name

    if [ "$OS" = "Darwin" ]; then
      _CLAUDE_DESKTOP="$HOME/Library/Application Support/Claude"
      _backup_file "$_CLAUDE_DESKTOP/claude_desktop_config.json"       "claude-desktop/claude_desktop_config.json"
      _backup_file "$_CLAUDE_DESKTOP/config.json"                      "claude-desktop/config.json"
    fi
  fi

  echo ""
  success "Backup saved to $_BACKUP_DIR" ""

  # Keep only the newest backups; timestamped names sort chronologically
  _BACKUP_KEEP=5
  ls -1d "$(dirname "$_BACKUP_DIR")"/[0-9]* 2>/dev/null | sort -r | tail -n +$((_BACKUP_KEEP + 1)) |
    while IFS= read -r _old; do rm -rf "$_old"; done
  unset _BACKUP_TS _BACKUP_DIR _BACKUP_KEEP _CLAUDE_DESKTOP
  unset -f _backup_file _backup_dir
fi
