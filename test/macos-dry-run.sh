#!/usr/bin/env bash
# ===========================================
# macos-dry-run.sh — macOS checks without touching $HOME (CI and local)
# ===========================================
# Runs install.sh --dry-run with every module enabled under the system bash
# (3.2 on macOS, what a fresh Mac has), then checks the generated files in
# build/, the keyboard bundle and the `dotfiles` command. Uses a temporary
# config dir, so the real ~/.config/dotfiles is never read.

# shellcheck disable=SC2088  # "~" in messages is display text, not a path

set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
BUILD="$REPO/build"
CONF="$(mktemp -d)"
trap 'rm -rf "$CONF"' EXIT

step() { printf '\n\033[1;34m== %s ==\033[0m\n' "$1"; }
pass() { printf '\033[1;32m✓ %s\033[0m\n' "$1"; }
die()  { printf '\033[1;31m✗ %s\033[0m\n' "$1" >&2; exit 1; }

[ "$(uname -s)" = Darwin ] || die "macOS only (use the Docker test on Linux)"

step "Sample config with every module"
mkdir -p "$CONF/dotfiles/local"
cat > "$CONF/dotfiles/config.sh" <<'EOF'
GIT_USER_NAME="CI Tester"
GIT_USER_EMAIL="ci@example.com"
DOTFILES_MODULES="zsh git cli tmux nvim mermaid starship sesh ghostty aerospace vpn media claude keyboard-ua-ru"
PROJECT_1_NAME=acme
PROJECT_1_APP="yarn start"
PROJECT_1_APP_PORT=3000
PROJECT_1_WT_REPO="$HOME/projects/acme"
PROJECT_1_TMUX_WINDOWS="bash:2 code:1"
CLAUDE_ACCOUNT_1_NAME=work
NVIM_EXTRAS="lang.prisma"
EOF
printf '[[on-window-detected]]\nif.app-id = "com.example.app"\nrun = "layout floating"\n' \
  > "$CONF/dotfiles/aerospace.local.toml"
pass "config in $CONF"

step "install.sh --dry-run under /bin/bash $(/bin/bash -c 'echo $BASH_VERSION')"
env -i HOME="$HOME" PATH="$PATH" XDG_CONFIG_HOME="$CONF" /bin/bash "$REPO/install.sh" --dry-run
pass "dry run finished"

step "Generated files"
for f in \
  .zshrc .tmux.conf .config/nvim/init.lua .config/starship.toml .config/ghostty/config \
  .config/tmux/keyboard-ua-ru.conf .config/tmux/nested-toggle.conf .config/ghostty/keyboard-ua-ru \
  .config/git/ignore .gitconfig .aerospace.toml bin/vpn \
  .aliases.d/project-acme.sh .aliases.d/claude-accounts.sh .claude-work/settings.json \
  .local/state/dotfiles/settings.lua "Library/Keyboard Layouts/UA-RU-layout.bundle/Contents/Info.plist"; do
  [ -e "$BUILD/$f" ] || die "~/$f was not generated"
done
grep -q 'com.example.app' "$BUILD/.aerospace.toml" || die "aerospace.local.toml not appended"
grep -q '"lang.prisma"' "$BUILD/.local/state/dotfiles/settings.lua" || die "NVIM_EXTRAS missing from settings.lua"
grep -q '"mermaid"' "$BUILD/.local/state/dotfiles/settings.lua" || die "mermaid module missing from settings.lua"
pass "all module outputs present"

step "Keyboard bundle and shell syntax"
plutil -lint "$REPO/keyboards/UA-RU-layout.bundle/Contents/Info.plist" > /dev/null || die "Info.plist is invalid"
for f in "$REPO"/shell/.zshrc "$REPO"/shell/aliases/*.sh "$BUILD"/.aliases.d/*.sh; do
  zsh -n "$f" || die "zsh syntax error in $f"
done
pass "Info.plist valid, zsh files parse"

step "vpn down cleans up with route and scutil on macOS"
vpn_stub="$(mktemp -d)"
export VPN_STUB_LOG="$vpn_stub/calls.log"
: > "$VPN_STUB_LOG"
# Network tools only record their call; sudo records the command it wraps and
# really runs only the harmless ones, so the test never changes the network
for cmd in ip resolvectl route ifconfig scutil openvpn dscacheutil killall; do
  printf '#!/bin/sh\necho "%s $*" >> "$VPN_STUB_LOG"\n' "$cmd" > "$vpn_stub/$cmd"
done
printf '#!/bin/sh\necho "$*" >> "$VPN_STUB_LOG"\ncase "$1" in kill | rm | chown) exec "$@" ;; esac\n' > "$vpn_stub/sudo"
chmod +x "$vpn_stub"/*
touch "$vpn_stub/test.ovpn"
mkdir -p "$vpn_stub/state/vpn"
sleep 300 &
vpn_fake_pid=$!
echo "$vpn_fake_pid" > "$vpn_stub/state/vpn/openvpn.pid"
vpn_out="$(PATH="$vpn_stub:$PATH" XDG_STATE_HOME="$vpn_stub/state" VPN_CONFIG_PATH="$vpn_stub/test.ovpn" \
  /bin/bash "$REPO/tools/vpn" down 2>&1)"
[[ "$vpn_out" == *"VPN stopped"* ]] || die "vpn down did not report a stop: $vpn_out"
kill -0 "$vpn_fake_pid" 2>/dev/null && die "vpn down left the openvpn process running"
grep -q '^route -n delete -net 0.0.0.0/1$' "$VPN_STUB_LOG" || die "vpn down did not remove the override routes"
grep -q '^scutil$' "$VPN_STUB_LOG" || die "vpn down did not reset DNS with scutil"
grep -q '^dscacheutil -flushcache$' "$VPN_STUB_LOG" || die "vpn down did not flush the DNS cache"
if grep -Eq '^(ip|resolvectl) ' "$VPN_STUB_LOG"; then
  die "vpn down called Linux-only tools on macOS"
fi
rm -rf "$vpn_stub"
pass "process stopped, routes and DNS reset the macOS way"

step "dotfiles command"
listing="$(env -i HOME="$BUILD" PATH="$PATH" zsh -fc "
  DOTFILES_DIR='$REPO'; DOTFILES_MODULES='media tmux'
  source '$REPO/shell/aliases/dotfiles.sh'; dotfiles; dotfiles acme-wt-new")"
[[ "$listing" == *"acme-wt-new <branch> [base-branch]"* ]] || die "listing misses project commands"
[[ "$listing" == *compress-pdf* ]] || die "listing misses media commands"
[[ "$listing" == *Examples*"acme-wt-new feature/login"* ]] || die "per-command docs missing"
pass "listing and per-command docs"

printf '\n\033[1;32mAll macOS checks passed.\033[0m\n'
