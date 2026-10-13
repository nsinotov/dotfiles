# ===========================================
# Dotfiles configuration — settings, no secrets
# ===========================================
# install.sh copies this to ~/.config/dotfiles/config.sh on the first run.
# Sourced by .zshrc and install.sh (zsh/bash syntax). Re-run install.sh after
# changes. Tokens go to ~/.config/dotfiles/.secrets and are referenced by name.

# ------------------------------------
# Git identity (module: git)
# ------------------------------------

GIT_USER_NAME="Your Name"
GIT_USER_EMAIL="your@email.com"

# ------------------------------------
# Modules — what install.sh sets up (nothing unless listed)
# ------------------------------------
# Each module installs its own packages (Homebrew on macOS, apt on Linux):
#   zsh        .zshrc, zsh, Oh My Zsh + plugins; loads projects, Claude
#              accounts and local extensions
#   git        generated ~/.gitconfig (identity below) + global ignore
#   cli        fzf, ripgrep, fd, jq, gh
#   tmux       tmux config, TPM and plugins
#   nvim       Neovim (LazyVim) config, ripgrep, fd, lazygit, C compiler
#   starship   Starship prompt
#   sesh       sesh session picker, zoxide, fzf (needs tmux)
#   ghostty    Ghostty terminal + Monaspice Nerd Font
#   aerospace  AeroSpace tiling WM + JankyBorders (macOS only)
#   vpn        tools/vpn OpenVPN manager in ~/bin, openvpn, fzf
#   media      compress-pdf/-mov/-mp4 aliases, ghostscript, ffmpeg
#   claude     Claude Code + account functions (CLAUDE_ACCOUNT_<N>_*, needs zsh)
#   keyboard-ua-ru  UA-RU layout (macOS) + Cyrillic bindings for the enabled
#                   tmux / ghostty / nvim modules, macism
# When a module or feature needs another module (claude → zsh, sesh → tmux,
# projects → zsh), install.sh warns and asks before adding it. Removing a
# module removes its links on the next run.

DOTFILES_MODULES="zsh git cli tmux nvim starship sesh ghostty aerospace"

# ------------------------------------
# Shell
# ------------------------------------

# Extra PATH entries, space-separated, first wins (missing dirs are skipped)
# DOTFILES_PATH="$HOME/.cargo/bin $HOME/go/bin"

# Local extensions dirs, space-separated. In each dir, *.sh files are sourced
# by .zshrc, bin/ is added to PATH, and an executable install.sh runs at the
# end of install.sh. Default: ~/.config/dotfiles/local
# DOTFILES_LOCAL_DIRS="$HOME/.config/dotfiles/local $HOME/src/private-dotfiles"

# Names of variables (from this file or .secrets) to export to child processes.
# Everything else stays a shell variable.
# DOTFILES_EXPORT="NPM_TOKEN"

# Default layout for tmux-session (same format as PROJECT_<N>_TMUX_WINDOWS)
# TMUX_SESSION_WINDOWS="bash:4:tiled agent:1 code:1"

# EDITOR="nvim"

# ------------------------------------
# Tool options
# ------------------------------------

# Extra LazyVim extras (names after "lazyvim.plugins.extras.") and extra plugins
# (GitHub owner/repo, default settings) on top of the tracked nvim config
# NVIM_EXTRAS="ai.claudecode lang.prisma lang.tailwind"
# NVIM_PLUGINS="ThePrimeagen/vim-be-good"

# F12 toggles tmux key passthrough for a nested (SSH) session. Keep it on
# workstations; set false on servers so a double F12 can't lock both ends.
# TMUX_NESTED_TOGGLE=false

# Add tools/claude-statusline.sh to every Claude account's settings.json
# (an existing, different statusLine is never replaced)
# CLAUDE_STATUSLINE=false

# Per-machine additions appended to tracked configs (untracked files, only
# extra [tables] — top-level keys would land in the previous table):
#   ~/.config/dotfiles/starship.local.toml   e.g. [aws.profile_aliases]
#   ~/.config/dotfiles/aerospace.local.toml  e.g. [[on-window-detected]] rules

# ------------------------------------
# Projects
# ------------------------------------
# Each project generates <name>-app, -api, -stop, -test, -e2e, -storybook,
# -install, -reinstall and worktree commands. See shell/templates/project.sh.tpl.

# PROJECT_1_NAME=acme
# PROJECT_1_DIR="$HOME/projects/acme"            # with GIT_EMAIL: per-directory identity
# PROJECT_1_GIT_EMAIL="jane@acme.example"
# PROJECT_1_APP="yarn nx serve web"
# PROJECT_1_APP_PORT=3000                        # kill whatever listens here first
# PROJECT_1_API="yarn nx serve api"
# PROJECT_1_API_PORT=8080
# PROJECT_1_TEST="yarn nx affected --target=test"
# PROJECT_1_E2E="yarn nx e2e web-e2e"
# PROJECT_1_STORYBOOK="yarn storybook"
# PROJECT_1_INSTALL="yarn"
# PROJECT_1_REINSTALL="rm -rf node_modules && yarn"
# PROJECT_1_PRETEST="$HOME/.config/dotfiles/local/bin/preflight-check"
# PROJECT_1_ENV="NX_DAEMON=false"                # only for app/api/test/e2e/storybook
# PROJECT_1_WT_REPO="$HOME/projects/acme/repo"
# PROJECT_1_WT_BRANCH=main
# PROJECT_1_WT_ENV_FILES=".env apps/web/.env"
# PROJECT_1_WT_INSTALL="yarn"
# PROJECT_1_TMUX_WINDOWS="bash:4:tiled agent:1 code:1"

# ------------------------------------
# Claude Code accounts (module: claude)
# ------------------------------------
# Each account generates claude-<name>; `claude` runs CLAUDE_DEFAULT_ACCOUNT
# (default: the first account). See shell/templates/claude-account.sh.tpl.
#
#   NAME        required, function suffix
#   CONFIG_DIR  default ~/.claude-<name>
#   ENV         non-secret KEY=value pairs, space-separated
#   SECRET_ENV  KEY=SECRET_VAR pairs; the value is read from $SECRET_VAR
#               (defined in .secrets) at launch, never written to disk
#   PRE_CMD     command run before launch, aborts on failure — e.g. a function
#               from your local extensions that starts a proxy
#   LINK_HOME   true → CONFIG_DIR becomes a symlink to ~/.claude, for tools that
#               only manage ~/.claude (at most one account)

# Company proxy: token from .secrets, proxy started by a local function
# CLAUDE_ACCOUNT_1_NAME=proxy
# CLAUDE_ACCOUNT_1_ENV="ANTHROPIC_BASE_URL=http://localhost:8080"
# CLAUDE_ACCOUNT_1_SECRET_ENV="ANTHROPIC_AUTH_TOKEN=CLAUDE_PROXY_TOKEN"
# CLAUDE_ACCOUNT_1_PRE_CMD="proxy_start"
# CLAUDE_ACCOUNT_1_LINK_HOME=true

# Company subscription: plain /login on first launch
# CLAUDE_ACCOUNT_2_NAME=work

# Personal subscription
# CLAUDE_ACCOUNT_3_NAME=personal

# Google Vertex AI
# CLAUDE_ACCOUNT_4_NAME=vertex
# CLAUDE_ACCOUNT_4_ENV="CLAUDE_CODE_USE_VERTEX=1 CLOUD_ML_REGION=global ANTHROPIC_VERTEX_PROJECT_ID=my-gcp-project"

# CLAUDE_DEFAULT_ACCOUNT=personal

# ------------------------------------
# VPN (module: vpn)
# ------------------------------------

# VPN_CONFIG_PATH="$HOME/.config/vpn/profile.ovpn"
# VPN_OPENVPN_BIN="/opt/homebrew/opt/openvpn/sbin/openvpn"   # auto-detected if unset
