# shellcheck shell=bash
# Sourced by install.sh — load config.sh/.secrets and resolve modules

# shellcheck source=lib/dotfiles.sh
source "$DOTFILES_DIR/lib/dotfiles.sh"

# First run: create both files from the templates, then stop so the user can
# fill in the git identity and pick modules before anything is generated
if [ ! -f "$CONFIG_FILE" ] && [ ! -f "$SECRETS_FILE" ]; then
  mkdir -p "$DOTFILES_CONFIG_HOME"
  chmod 700 "$DOTFILES_CONFIG_HOME"
  cp "$DOTFILES_DIR/config.example.sh" "$CONFIG_FILE"
  cp "$DOTFILES_DIR/.secrets.example" "$SECRETS_FILE"
  chmod 600 "$SECRETS_FILE"
  info "Created $CONFIG_FILE" "from config.example.sh"
  info "Created $SECRETS_FILE" "from .secrets.example"
  echo ""
  echo "  Edit config.sh (at least GIT_USER_NAME, GIT_USER_EMAIL, DOTFILES_MODULES),"
  echo "  add tokens to .secrets if needed, then re-run ./install.sh"
  exit 0
fi

load_config
for f in "$CONFIG_FILE" "$SECRETS_FILE"; do
  [ -f "$f" ] && success "Loaded $f" ""
done

# Migration: the local extensions dir was called aliases.d in earlier versions
if [ "$TEST_MODE" = false ] && [ -d "$DOTFILES_CONFIG_HOME/aliases.d" ] &&
   [ ! -e "$DOTFILES_CONFIG_HOME/local" ]; then
  mv "$DOTFILES_CONFIG_HOME/aliases.d" "$DOTFILES_CONFIG_HOME/local"
  info "$DOTFILES_CONFIG_HOME/aliases.d" "moved to local/"
fi

if [ -z "$DOTFILES_MODULES" ]; then
  fail "No modules selected" "set DOTFILES_MODULES in $CONFIG_FILE (see config.example.sh)"
  exit 1
fi

# Modules needed by other modules or configured features: warn and offer to
# add them for this run (add them to config.sh to stop the prompt)
added_modules=""
while IFS='|' read -r required needed_by reason; do
  [ -z "$required" ] && continue
  printf "  \033[1;33m%-50s\033[0m %s\n" "$needed_by needs module '$required'" "$reason"
  if module_enabled "$required" || [ "$TEST_MODE" = true ]; then  # added for an earlier line
    continue
  elif confirm "Set up '$required' as well?"; then
    DOTFILES_MODULES="$DOTFILES_MODULES $required"
    added_modules="$added_modules $required"
  else
    info "  $needed_by" "will not work without '$required'"
  fi
done <<< "$(missing_requirements)"
if [ -n "$added_modules" ]; then
  info "  Added for this run:$added_modules" "add to DOTFILES_MODULES in config.sh"
fi
info "Modules" "$DOTFILES_MODULES"

if module_enabled git &&
   { [ -z "${GIT_USER_NAME:-}" ] || [ -z "${GIT_USER_EMAIL:-}" ] ||
     [ "$GIT_USER_EMAIL" = "your@email.com" ]; }; then
  fail "Git identity not set" "fill in GIT_USER_NAME / GIT_USER_EMAIL in $CONFIG_FILE"
  exit 1
fi
