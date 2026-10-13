# shellcheck shell=bash
# Sourced by install.sh — install packages and frameworks

# ===========================================
# Phase 1: Check dependencies
# ===========================================

echo ""
echo "Checking dependencies..."
echo ""

# Fresh macOS ships git and clang only as stubs until Command Line Tools are installed
if [ "$OS" = "Darwin" ] && ! xcode-select -p > /dev/null 2>&1; then
  fail "Xcode Command Line Tools" "not installed"
  [ "$TEST_MODE" = false ] && xcode-select --install 2> /dev/null || true
  echo "  Finish the Command Line Tools installer, then re-run ./install.sh"
  exit 1
fi

# Homebrew is the package manager for everything below on macOS
if [ "$OS" = "Darwin" ] && ! have brew; then
  for _brew in /opt/homebrew/bin/brew /usr/local/bin/brew; do
    [ -x "$_brew" ] && eval "$("$_brew" shellenv)" && break
  done
  unset _brew
fi
if [ "$OS" = "Darwin" ] && ! have brew && [ "$TEST_MODE" = false ]; then
  info "brew" "not found"
  if confirm "Install Homebrew (official installer from brew.sh)?"; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    for _brew in /opt/homebrew/bin/brew /usr/local/bin/brew; do
      [ -x "$_brew" ] && eval "$("$_brew" shellenv)" && break
    done
    unset _brew
  fi
fi

# git is needed by install.sh itself (cloning Oh My Zsh, TPM)
if ! have git; then
  fail "git" "REQUIRED — not found"
  exit 1
fi
success "git" ""

# Packages per module, offered only when the module is enabled.
# Format: "module:detect:brew:apt"
#   detect  "|"-separated commands or absolute paths; empty = ask brew (macOS only)
#   brew    formula, or cask/<name> for a cask; empty = not available via brew
#   apt     package name; empty = not available via apt (install manually)
DEPS=(
  "zsh:zsh:zsh:zsh"
  "cli:fzf:fzf:fzf"
  "cli:fd|fdfind:fd:fd-find"
  "cli:rg:ripgrep:ripgrep"
  "cli:jq:jq:jq"
  "cli:gh:gh:gh"
  "nvim:nvim:neovim:neovim"
  "nvim:rg:ripgrep:ripgrep"
  "nvim:fd|fdfind:fd:fd-find"
  "nvim:lazygit:lazygit:"
  "nvim:cc|gcc|clang::build-essential"
  "tmux:tmux:tmux:tmux"
  "starship:starship:starship:"
  "sesh:sesh:sesh:"
  "sesh:zoxide:zoxide:zoxide"
  "sesh:fzf:fzf:fzf"
  "ghostty:ghostty|/Applications/Ghostty.app:cask/ghostty:"
  "ghostty::cask/font-monaspice-nerd-font:"
  "aerospace:/Applications/AeroSpace.app:cask/nikitabobko/tap/aerospace:"
  "aerospace:borders:felixkratz/formulae/borders:"
  "vpn:openvpn|/opt/homebrew/opt/openvpn/sbin/openvpn|/usr/local/opt/openvpn/sbin/openvpn:openvpn:openvpn"
  "vpn:fzf:fzf:fzf"
  "media:ffmpeg:ffmpeg:ffmpeg"
  "media:gs:ghostscript:ghostscript"
  "claude:claude:cask/claude-code:"
  "claude:jq:jq:jq"
  "keyboard-ua-ru:macism:laishulu/homebrew/macism:"
)

# Modules that only exist on macOS
MACOS_ONLY_MODULES="aerospace keyboard-ua-ru"

# dep_label <detect> <brew> <apt> — short name for messages
dep_label() {
  local name="${2##*/}"
  [ -z "$name" ] && name="${1%%|*}"
  [ -z "$name" ] && name="$3"
  printf '%s' "$name"
}

# dep_present <detect> <brew> — installed check (empty detect: ask brew)
dep_present() {
  if [ -n "$1" ]; then
    have "$1"
  elif [ "$OS" = "Darwin" ] && have brew; then
    brew list --cask "${2##*/}" > /dev/null 2>&1 || brew list "${2##*/}" > /dev/null 2>&1
  else
    return 1
  fi
}

missing_deps=()
seen_deps=" "
for entry in "${DEPS[@]}"; do
  IFS=':' read -r module detect brew_pkg apt_pkg <<< "$entry"
  module_enabled "$module" || continue
  [ "$OS" != "Darwin" ] && [[ " $MACOS_ONLY_MODULES " == *" $module "* ]] && continue
  # Detection-less entries (fonts) can only be checked through brew
  [ "$OS" != "Darwin" ] && [ -z "$detect" ] && continue
  label="$(dep_label "$detect" "$brew_pkg" "$apt_pkg")"
  [[ "$seen_deps" == *" $label "* ]] && continue  # shared by several modules
  seen_deps="$seen_deps$label "
  if dep_present "$detect" "$brew_pkg"; then
    success "$label" ""
  else
    info "$label" "not found ($module)"
    missing_deps+=("$entry")
  fi
done

if [ ${#missing_deps[@]} -gt 0 ] && [ "$TEST_MODE" = false ]; then
  echo ""
  if confirm "Install missing tools?"; then
    for entry in "${missing_deps[@]}"; do
      IFS=':' read -r module detect brew_pkg apt_pkg <<< "$entry"
      label="$(dep_label "$detect" "$brew_pkg" "$apt_pkg")"
      if [ "$OS" = "Darwin" ] && have brew; then
        if [ -z "$brew_pkg" ]; then
          info "$label" "not available via Homebrew — install manually"
        elif [[ "$brew_pkg" == cask/* ]]; then
          confirm "Install ${brew_pkg#cask/} (cask)?" && brew install --cask "${brew_pkg#cask/}" &&
            success "$label" "installed"
        else
          confirm "Install $brew_pkg?" && brew install "$brew_pkg" && success "$label" "installed"
        fi
      elif have apt-get; then
        if [ -z "$apt_pkg" ]; then
          info "$label" "not in apt — install manually"
        elif confirm "Install $apt_pkg?"; then
          # Package lists may be empty or stale on a fresh system; refresh once
          if [ "${_apt_updated:-false}" = false ]; then
            sudo apt-get update -qq && _apt_updated=true
          fi
          sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq "$apt_pkg" &&
            success "$label" "installed"
        fi
      else
        fail "No package manager found" "install $label manually"
      fi
    done
  fi
fi

# ---- Shell and tmux frameworks (cloned with git, no remote install scripts) ----

# clone_repo <url> <dir> <label> — shallow-clone if missing, after confirmation
clone_repo() {
  local url="$1" dir="$2" label="$3"
  if [ -d "$dir" ]; then
    success "$label" ""
  elif [ "$TEST_MODE" = true ]; then
    info "$label" "not found (skipped in test mode)"
  elif confirm "Install $label?"; then
    git clone --depth 1 "$url" "$dir" && success "$label" "installed"
  else
    info "$label" "skipped"
  fi
  return 0  # a declined prompt or failed clone must not trip set -e
}

if module_enabled zsh; then
  ZSH_DIR="$HOME/.oh-my-zsh"
  ZSH_CUSTOM_DIR="${ZSH_CUSTOM:-$ZSH_DIR/custom}"
  clone_repo "https://github.com/ohmyzsh/ohmyzsh.git" "$ZSH_DIR" "Oh My Zsh"
  if [ -d "$ZSH_DIR" ]; then
    clone_repo "https://github.com/zsh-users/zsh-autosuggestions.git" \
      "$ZSH_CUSTOM_DIR/plugins/zsh-autosuggestions" "zsh-autosuggestions"
    clone_repo "https://github.com/zsh-users/zsh-syntax-highlighting.git" \
      "$ZSH_CUSTOM_DIR/plugins/zsh-syntax-highlighting" "zsh-syntax-highlighting"
  fi

  # The configs only take effect in zsh; offer to make it the login shell
  zsh_path="$(command -v zsh || true)"
  login_shell="${SHELL:-}"
  if [ -n "$zsh_path" ] && [ "${login_shell##*/}" != zsh ] && [ "$TEST_MODE" = false ]; then
    info "Login shell" "${login_shell:-unknown}"
    if confirm "Make zsh ($zsh_path) your login shell?"; then
      if have sudo && [ "$OS" != "Darwin" ]; then
        sudo chsh -s "$zsh_path" "$(id -un)" && success "Login shell" "zsh"
      else
        chsh -s "$zsh_path" && success "Login shell" "zsh"
      fi
    fi
  fi
fi

TPM_DIR="$HOME/.tmux/plugins/tpm"
TPM_FRESH=false
if module_enabled tmux; then
  [ -d "$TPM_DIR" ] || TPM_FRESH=true
  clone_repo "https://github.com/tmux-plugins/tpm.git" "$TPM_DIR" "TPM (tmux plugin manager)"
fi
