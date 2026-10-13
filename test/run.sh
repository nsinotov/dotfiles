#!/usr/bin/env bash
# ===========================================
# run.sh — Fresh-install test (runs inside test/Dockerfile)
# ===========================================
# Walks through the README Quick Start on a clean Ubuntu user and asserts the
# result. Stops with a non-zero exit on the first failed check.

# shellcheck disable=SC2088  # "~" in messages is display text, not a path

set -euo pipefail

REPO="$HOME/.dotfiles"
CONF_HOME="$HOME/.config/dotfiles"
CONFIG="$CONF_HOME/config.sh"
SECRETS="$CONF_HOME/.secrets"
LOCAL="$CONF_HOME/local"
SETTINGS="$HOME/.local/state/dotfiles/settings.lua"

step() { printf '\n\033[1;34m== %s ==\033[0m\n' "$1"; }
pass() { printf '\033[1;32m✓ %s\033[0m\n' "$1"; }
die()  { printf '\033[1;31m✗ %s\033[0m\n' "$1" >&2; exit 1; }

# set_modules "<list>" — rewrite DOTFILES_MODULES in config.sh
set_modules() {
  sed -i "s/^DOTFILES_MODULES=.*/DOTFILES_MODULES=\"$1\"/" "$CONFIG"
}

# ------------------------------------
# Config bootstrap
# ------------------------------------

step "First run creates config.sh and .secrets, then stops"
"$REPO/install.sh"
[ -f "$CONFIG" ] || die "config.sh was not created"
[ -f "$SECRETS" ] || die ".secrets was not created"
[ "$(stat -c %a "$SECRETS")" = 600 ] || die ".secrets is not chmod 600"
pass "config.sh and .secrets (600) created"

step "Placeholder git identity is rejected"
if "$REPO/install.sh" --yes > /dev/null 2>&1; then
  die "install.sh accepted the placeholder git identity"
fi
pass "placeholder identity rejected"

step "Fill in config, secrets and a local extensions dir"
sed -i \
  -e 's/^GIT_USER_NAME=.*/GIT_USER_NAME="CI Tester"/' \
  -e 's/^GIT_USER_EMAIL=.*/GIT_USER_EMAIL="ci@example.com"/' \
  "$CONFIG"
set_modules "zsh git cli tmux nvim starship sesh ghostty vpn claude"
mkdir -p "$HOME/ci-path"
cat >> "$CONFIG" <<'EOF'
CI_PUBLIC_VAR=exported
DOTFILES_EXPORT="CI_PUBLIC_VAR"
DOTFILES_PATH="$HOME/ci-path"
CLAUDE_ACCOUNT_1_NAME=ci
CLAUDE_ACCOUNT_1_ENV="CI_ACCOUNT_ENV=plain"
CLAUDE_ACCOUNT_1_SECRET_ENV="CI_ACCOUNT_TOKEN=CI_CLAUDE_TOKEN"
CLAUDE_ACCOUNT_1_PRE_CMD="ci_pre"
CLAUDE_ACCOUNT_2_NAME=other
CLAUDE_DEFAULT_ACCOUNT=ci
PROJECT_1_NAME=acme
PROJECT_1_TEST="echo 'quoted test'"
PROJECT_1_APP="echo \"it's the app\""
PROJECT_1_APP_PORT=39999
PROJECT_1_PRETEST="true"
NVIM_EXTRAS="lang.prisma"
NVIM_PLUGINS="ThePrimeagen/vim-be-good"
EOF
printf '[aws.profile_aliases]\n"ci@example.com" = "ci"\n' > "$CONF_HOME/starship.local.toml"
cat >> "$SECRETS" <<'EOF'
CI_PRIVATE_TOKEN=must-not-leak
CI_CLAUDE_TOKEN=claude-secret-value
EOF

mkdir -p "$LOCAL/bin"
cat > "$LOCAL/ci.sh" <<'EOF'
# desc: CI local command
ci-local() { echo "local-ok"; }
ci_pre() { echo "pre-ok"; }
EOF
# Fake claude binary: shows what the account function passes to it
cat > "$LOCAL/bin/claude" <<'EOF'
#!/usr/bin/env bash
echo "FAKE_CLAUDE dir=${CLAUDE_CONFIG_DIR##*/} env=${CI_ACCOUNT_ENV:-} token=${CI_ACCOUNT_TOKEN:-} leak=${CI_PRIVATE_TOKEN:-}"
EOF
mkdir -p "$LOCAL/nvim"
echo 'vim.fn.writefile({ "ok" }, vim.env.HOME .. "/.ci-nvim-local")' > "$LOCAL/nvim/init.lua"
cat > "$LOCAL/install.sh" <<'EOF'
#!/usr/bin/env bash
touch "$HOME/.ci-hook-ran"
EOF
chmod +x "$LOCAL/bin/claude" "$LOCAL/install.sh"
pass "config, secrets and local extensions set"

# ------------------------------------
# Full install
# ------------------------------------

step "Full install (--yes)"
"$REPO/install.sh" --yes

step "Enabled modules are linked into the repo"
for pair in \
  ".zshrc:shell/.zshrc" \
  ".tmux.conf:tmux/.tmux.conf" \
  ".config/nvim:editor/nvim" \
  ".config/tmux/nested-toggle.conf:tmux/nested-toggle.conf" \
  ".config/git/ignore:git/.gitignore" \
  ".config/sesh/sesh.toml:tools/sesh.toml" \
  ".config/ghostty/config:terminal/ghostty/config" \
  "bin/vpn:tools/vpn"; do
  dst="$HOME/${pair%%:*}" src="$REPO/${pair#*:}"
  [ "$(readlink "$dst")" = "$src" ] || die "$dst does not link to $src"
done
pass "all enabled configs linked"

step "Cyrillic bindings are off without keyboard-ua-ru"
[ ! -e "$HOME/.config/tmux/keyboard-ua-ru.conf" ] || die "tmux Cyrillic include linked"
[ ! -e "$HOME/.config/ghostty/keyboard-ua-ru" ] || die "Ghostty Cyrillic include linked"
! grep -q '"keyboard-ua-ru"' "$SETTINGS" || die "settings.lua lists keyboard-ua-ru"
nvim_kbd="$(nvim --headless -u NONE --cmd "set rtp+=$HOME/.config/nvim" \
  -c 'lua io.write(tostring(require("lib.dotfiles").module("keyboard-ua-ru")))' -c 'qa!' 2>&1)"
[ "$nvim_kbd" = false ] || die "nvim sees keyboard-ua-ru as enabled ($nvim_kbd)"
pass "no Cyrillic includes, nvim flag off"

step "Local additions, nvim settings and local nvim code"
starship_cfg="$HOME/.config/starship.toml"
[ -f "$starship_cfg" ] && [ ! -L "$starship_cfg" ] || die "starship.toml not generated from the local file"
grep -q '"ci@example.com" = "ci"' "$starship_cfg" || die "starship.local.toml not appended"
nvim_specs="$(nvim --headless -u NONE --cmd "set rtp+=$HOME/.config/nvim" \
  -c 'lua io.write(vim.inspect(require("lib.dotfiles").optional_specs()))' -c 'qa!' 2>&1)"
[[ "$nvim_specs" == *lazyvim.plugins.extras.lang.prisma*vim-be-good* ]] || die "NVIM_EXTRAS/NVIM_PLUGINS not applied ($nvim_specs)"
nvim --headless -u NONE --cmd "set rtp+=$HOME/.config/nvim" \
  -c 'lua require("lib.dotfiles").load_local_init()' -c 'qa!' > /dev/null 2>&1
[ -f "$HOME/.ci-nvim-local" ] || die "local nvim/init.lua was not loaded"
pass "starship merge, nvim extras/plugins, local nvim init"

step "Generated git config"
[ "$(git config --global user.email)" = "ci@example.com" ] || die "git user.email not set"
[[ "$(git config --global --get-all include.path)" == *.gitconfig.local* ]] || die "~/.gitconfig.local not included"
tmp_repo="$(mktemp -d)"
git -C "$tmp_repo" init -q
git -C "$tmp_repo" check-ignore -q .DS_Store || die "global ignore (~/.config/git/ignore) not active"
rm -rf "$tmp_repo"
pass "identity, local include and global ignore work"

step "Packages and frameworks"
for cmd in nvim tmux fzf rg jq gh zoxide; do
  command -v "$cmd" > /dev/null || die "$cmd not installed"
done
command -v fd > /dev/null || command -v fdfind > /dev/null || die "fd not installed"
for dir in \
  .oh-my-zsh \
  .oh-my-zsh/custom/plugins/zsh-autosuggestions \
  .oh-my-zsh/custom/plugins/zsh-syntax-highlighting \
  .tmux/plugins/tpm \
  .tmux/plugins/vim-tmux-navigator; do
  [ -d "$HOME/$dir" ] || die "~/$dir missing"
done
pass "apt packages, Oh My Zsh + plugins, TPM + tmux plugins installed"

step "Claude accounts and local hook"
accounts="$HOME/.aliases.d/claude-accounts.sh"
[ -f "$accounts" ] || die "claude-accounts.sh not generated"
! grep -q 'claude-secret-value' "$accounts" || die "secret value written to claude-accounts.sh"
[ -d "$HOME/.claude-ci" ] && [ -d "$HOME/.claude-other" ] || die "account config dirs not created"
[ -f "$HOME/.ci-hook-ran" ] || die "local install.sh hook did not run"
[ "$(jq -r '.statusLine.command' "$HOME/.claude-ci/settings.json")" = "$REPO/tools/claude-statusline.sh" ] ||
  die "status line not added to claude-ci settings.json"
pass "no plaintext secret, config dirs created, status line set, hook ran"

step "zsh is the login shell"
[ "$(getent passwd "$(id -un)" | cut -d: -f7)" = "$(command -v zsh)" ] || die "login shell was not changed to zsh"
pass "login shell is zsh"

step "Backups are private"
[ "$(stat -c %a "$CONF_HOME/backups")" = 700 ] || die "backups dir is not chmod 700"
pass "backups dir is 700"

# ------------------------------------
# Shell startup
# ------------------------------------

step "Interactive zsh starts cleanly"
zsh_out="$(zsh -i -c '
  echo "DOTFILES_DIR=$DOTFILES_DIR"
  type dotfiles tmux-session gs > /dev/null && echo "FUNCS=ok"
  echo "LEAK=$(printenv CI_PRIVATE_TOKEN || true)"
  echo "EXPORTED=$(printenv CI_PUBLIC_VAR || true)"
  echo "LOCAL=$(ci-local)"
  [[ "$(dotfiles)" == *ci-local* ]] && echo "LISTING=ok"
  [[ "$(dotfiles acme-test)" == *"Runs: echo"*quoted\ test* ]] && echo "DOC_PROJECT=ok"
  [[ "$(dotfiles tmux-session)" == *Examples*tmux-session\ ~/projects/acme* ]] && echo "DOC_STATIC=ok"
  [[ "$(dotfiles vpn)" == *"vpn up"* ]] && echo "DOC_SCRIPT=ok"
  [[ "$(dotfiles -v)" == *"e.g. gl main..HEAD"* ]] && echo "DOC_VERBOSE=ok"
  [[ "$(dotfiles claude)" == *claude-ci* ]] && echo "DOC_FILTER=ok"
  [[ "$(dotfiles)" != *compress-pdf* ]] && ! type compress-pdf > /dev/null 2>&1 && echo "DOC_MODULE=ok"
  claude --version
  acme-test
  acme-app
' 2>&1)"
echo "$zsh_out"
if grep -Eiq 'not found|no such file|error' <<< "$zsh_out"; then
  die "zsh startup printed errors"
fi
grep -q "^DOTFILES_DIR=$REPO$" <<< "$zsh_out" || die "DOTFILES_DIR not derived from the .zshrc symlink"
grep -q '^FUNCS=ok$'           <<< "$zsh_out" || die "static aliases or generated functions not loaded"
grep -q '^LEAK=$'              <<< "$zsh_out" || die "secret was exported to child processes"
grep -q '^EXPORTED=exported$'  <<< "$zsh_out" || die "DOTFILES_EXPORT variable was not exported"
grep -q '^LOCAL=local-ok$'     <<< "$zsh_out" || die "local extension not sourced"
grep -q '^LISTING=ok$'         <<< "$zsh_out" || die "dotfiles listing misses local extensions"
for doc in PROJECT STATIC SCRIPT VERBOSE FILTER MODULE; do
  grep -q "^DOC_$doc=ok$" <<< "$zsh_out" || die "dotfiles docs check DOC_$doc failed"
done
grep -q '^pre-ok$'             <<< "$zsh_out" || die "PRE_CMD did not run"
grep -q '^quoted test$'        <<< "$zsh_out" || die "project alias with single quotes broke"
grep -q "^it's the app$"       <<< "$zsh_out" || die "project alias with pretest + port + quotes broke"
grep -q 'FAKE_CLAUDE dir=.claude-ci env=plain token=claude-secret-value leak=$' <<< "$zsh_out" ||
  die "default account did not pass config dir, env and secret (or leaked others)"
zsh -i -c 'print -l $path' 2>/dev/null | grep -qx "$HOME/ci-path" || die "DOTFILES_PATH not on PATH"
pass "no errors, aliases and local extensions loaded, secrets scoped, accounts work"

# ------------------------------------
# Module toggling
# ------------------------------------

step "Enabling keyboard-ua-ru links the Cyrillic includes"
set_modules "zsh git cli tmux nvim starship sesh ghostty vpn claude keyboard-ua-ru"
"$REPO/install.sh" --yes > /dev/null
[ "$(readlink "$HOME/.config/tmux/keyboard-ua-ru.conf")" = "$REPO/tmux/keyboard-ua-ru.conf" ] ||
  die "tmux Cyrillic include not linked"
[ "$(readlink "$HOME/.config/ghostty/keyboard-ua-ru")" = "$REPO/terminal/ghostty/keyboard-ua-ru" ] ||
  die "Ghostty Cyrillic include not linked"
TERM=xterm-256color tmux -L ci -f "$HOME/.tmux.conf" new-session -d
[[ "$(tmux -L ci list-keys -T prefix)" == *" е "* ]] || die "tmux did not load Cyrillic bindings"
tmux -L ci kill-server
nvim_kbd="$(nvim --headless -u NONE --cmd "set rtp+=$HOME/.config/nvim" \
  -c 'lua io.write(tostring(require("lib.dotfiles").module("keyboard-ua-ru")))' -c 'qa!' 2>&1)"
[ "$nvim_kbd" = true ] || die "nvim does not see keyboard-ua-ru ($nvim_kbd)"
pass "tmux loads Cyrillic bindings, Ghostty include linked, nvim flag on"

step "TMUX_NESTED_TOGGLE=false removes the F12 include"
echo "TMUX_NESTED_TOGGLE=false" >> "$CONFIG"
"$REPO/install.sh" --yes > /dev/null
[ ! -e "$HOME/.config/tmux/nested-toggle.conf" ] || die "nested-toggle.conf still linked"
[ -L "$HOME/.tmux.conf" ] || die "tmux config should stay linked"
sed -i '/^TMUX_NESTED_TOGGLE=false$/d' "$CONFIG"
pass "F12 include removed, tmux config kept"

step "Disabling modules removes their links"
set_modules "zsh git cli nvim starship vpn claude"
"$REPO/install.sh" --yes > /dev/null
for path in .tmux.conf .config/ghostty/config .config/tmux/keyboard-ua-ru.conf .config/ghostty/keyboard-ua-ru \
  .config/sesh/sesh.toml .config/tmux/nested-toggle.conf; do
  [ ! -e "$HOME/$path" ] || die "~/$path still linked after disabling its module"
done
pass "tmux, sesh, ghostty, Cyrillic and nested-toggle links removed"

step "Missing requirements are reported and added on approval"
set_modules "git nvim claude"
req_out="$("$REPO/install.sh" --yes 2>&1)"
grep -q "claude needs module 'zsh'" <<< "$req_out" || die "no warning that claude needs zsh"
grep -q "local extensions needs module 'zsh'" <<< "$req_out" || die "no warning that local extensions need zsh"
[ "$(readlink "$HOME/.zshrc")" = "$REPO/shell/.zshrc" ] || die "zsh was not kept after approval"
req_check="$("$REPO/check.sh" 2>&1)"
grep -q "REQUIRES: claude needs module 'zsh'" <<< "$req_check" || die "check.sh does not report the unmet requirement"
pass "warned, zsh added for the run, check.sh reports it"

step "Nothing is installed without modules"
set_modules ""
if "$REPO/install.sh" --yes > /dev/null 2>&1; then
  die "install.sh ran with an empty module list"
fi
pass "empty DOTFILES_MODULES is rejected"

set_modules "zsh git cli nvim starship vpn claude"
"$REPO/install.sh" --yes > /dev/null

# ------------------------------------
# check.sh and idempotency
# ------------------------------------

step "check.sh reports a healthy install"
check_out="$("$REPO/check.sh" 2>&1)"
echo "$check_out"
if grep -Eq 'WRONG LINK|NOT LINKED|INSECURE|MISSING' <<< "$check_out"; then
  die "check.sh found problems"
fi
pass "check.sh clean"

step "Re-running install.sh is idempotent"
"$REPO/install.sh" --yes > /dev/null
if find "$HOME" -maxdepth 3 -name '*.bak.*' | grep -q .; then
  die "re-run backed up files it had already installed"
fi
[ "$(readlink "$HOME/.zshrc")" = "$REPO/shell/.zshrc" ] || die "~/.zshrc link changed on re-run"
pass "second run changed nothing"

# ------------------------------------
# Uninstall
# ------------------------------------

step "uninstall.sh removes links and generated files, keeps config"
"$REPO/uninstall.sh" --yes > /dev/null
left="$(find "$HOME" -maxdepth 4 -type l -lname "$REPO/*" 2>/dev/null)"
[ -z "$left" ] || die "links into the repo remain: $left"
[ ! -e "$HOME/.gitconfig" ] || die "~/.gitconfig not removed"
[ ! -e "$HOME/.aliases.d" ] || die "~/.aliases.d not removed"
[ -f "$CONFIG" ] && [ -f "$SECRETS" ] && [ -f "$LOCAL/ci.sh" ] || die "config, secrets or local files were removed"
[ "$(jq 'has("statusLine")' "$HOME/.claude-ci/settings.json")" = false ] || die "status line entry not removed"
pass "links and generated files gone, config and local files kept"

printf '\n\033[1;32mAll fresh-install checks passed.\033[0m\n'
