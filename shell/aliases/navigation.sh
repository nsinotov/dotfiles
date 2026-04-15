# ===========================================
# Navigation Aliases
# ===========================================
# Paths are configured via environment variables in ~/.config/dotfiles/.secrets

if [ -n "$OBSIDIAN_VAULT_PATH" ]; then
  # desc: Jump to the Obsidian vault ($OBSIDIAN_VAULT_PATH)
  alias cd-to-obsidian="cd \"$OBSIDIAN_VAULT_PATH\""
fi
