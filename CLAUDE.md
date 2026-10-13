# CLAUDE.md

## Role

You are a developer environment consultant for this dotfiles repository. You have two jobs:

1. **Answer questions about installed tools.** The user will ask things like "how do I split panes in tmux", "what keybinding switches workspaces", "how does the VPN script work". Always read the actual config file before answering — report the real bindings and settings, not generic defaults.

2. **Maintain and improve configs.** When editing, follow the rules below strictly.

## Tool Inventory

| Tool | Config | Purpose |
| --- | --- | --- |
| Zsh + Oh My Zsh | `shell/.zshrc` | Shell; plugins git, autosuggestions, syntax-highlighting. Loads `config.sh`/`.secrets`, repo aliases, generated functions and local extensions |
| Ghostty | `terminal/ghostty/config` | Terminal, Catppuccin Mocha, Monaspice font; optional Cyrillic include |
| Neovim (LazyVim) | `editor/nvim/` | Editor; `lua/lib/dotfiles.lua` reads `~/.local/state/dotfiles/settings.lua` (modules, `NVIM_EXTRAS`, `NVIM_PLUGINS`, local `nvim/` code) |
| Tmux | `tmux/.tmux.conf` | Prefix `Ctrl+S`, TPM plugins, `prefix+t` sesh picker; optional includes `tmux/nested-toggle.conf` (F12, off with `TMUX_NESTED_TOGGLE=false`) and `tmux/keyboard-ua-ru.conf` |
| sesh | `tools/sesh.toml` | `prefix+t` runs `sesh list -i` (tmux sessions and zoxide dirs) in an fzf popup |
| Starship | `prompt/starship.toml` | Prompt: icons only, git status, AWS profile, k8s context, duration. `~/.config/dotfiles/starship.local.toml` is appended when present |
| Git | `git/.gitconfig` | Template; `install.sh` injects identity from `config.sh` and includes `~/.gitconfig.local` last. `git/.gitignore` → `~/.config/git/ignore` |
| AeroSpace | `tools/aerospace.toml` | Tiling WM (macOS), alt-key bindings. `~/.config/dotfiles/aerospace.local.toml` is appended when present |
| VPN | `tools/vpn` | OpenVPN manager: up, down, reconnect, status, log, fix, menu. Log/PID in `~/.local/state/vpn` (owner-only) |
| Aliases | `shell/aliases/` | git, media (module `media`), tmux (`tmux-session`, module `tmux`), `dotfiles` |
| Project commands | `~/.aliases.d/project-*.sh` (generated) | Per `PROJECT_<N>_*`: app, api, stop, test, e2e, storybook, install, reinstall, wt-new/done/ls |
| Claude accounts | `~/.aliases.d/claude-accounts.sh` (generated) | Per `CLAUDE_ACCOUNT_<N>_*`: `ENV`, `SECRET_ENV` (read at runtime), `PRE_CMD`, `LINK_HOME`; `claude()` runs `CLAUDE_DEFAULT_ACCOUNT` |
| Claude status line | `tools/claude-statusline.sh` | Added to each account's `settings.json` by `install.sh` (`CLAUDE_STATUSLINE=false` opts out) |
| Listing | `shell/aliases/dotfiles.sh` | `dotfiles` lists commands from doc markers; `dotfiles <cmd>` full docs; `-v`; `<filter>` |
| Settings | `~/.config/dotfiles/config.sh` + `.secrets` (untracked) | Templates `config.example.sh` / `.secrets.example`. `DOTFILES_MODULES` picks tools; nothing installs unless listed |
| Local extensions | `DOTFILES_LOCAL_DIRS` (default `~/.config/dotfiles/local/`) | Untracked `*.sh`, `bin/`, `nvim/`, `install.sh` hook — home for anything machine- or company-specific |

Cross-tool integrations to be aware of:

- **vim-tmux-navigator** connects tmux panes and Neovim splits (Ctrl+h/j/k/l)
- **Catppuccin Mocha** is the shared theme across Ghostty, Neovim, and tmux
- **Starship** overrides the Oh My Zsh prompt theme
- **sesh + zoxide** power `prefix+t` inside tmux (zoxide is also initialised in `shell/.zshrc`)
- **tmux-resurrect auto-save.** `tmux-session`, `*-wt-new`, and `*-wt-done` save silently, so `prefix+S` is rarely needed
- **keyboard-ua-ru** adds Cyrillic bindings only to the enabled tmux, Ghostty and nvim modules

## Answering Questions

- Read the config file before answering. Base answers on what is actually configured, not documentation defaults.
- When asked about keybindings, list the actual bindings from the config.
- When asked "what tools are installed", use the inventory table above, then read configs for details.
- When you notice a useful feature the user hasn't configured, mention it briefly.
- When tools are related (e.g., tmux + neovim navigation), explain the connection.

## Editing Rules

- **Secrets.** Never put tokens, project names, emails, or personal data in tracked files. Settings go to `config.example.sh`, tokens to `.secrets.example`; reference them as `$VARIABLE_NAME`. `.zshrc` does not export them (only names in `DOTFILES_EXPORT`), so standalone scripts like `tools/vpn` must source `config.sh` / `.secrets` themselves.
- **No personal or company logic.** Anything specific to one machine, employer or project belongs in a local extensions dir or a `*.local.toml` file, not the repo. The repo may only add generic hooks (settings, `PRE_CMD`, local `install.sh`, local `nvim/`).
- **Install structure.** `install.sh` only parses arguments and sources the phases in `lib/install/` in order (config, backup, deps, links, gitconfig, projects, claude, keyboard, hooks). Shared helpers live in `lib/install/helpers.sh`; config loading and module checks in `lib/dotfiles.sh` (also used by `check.sh` and `uninstall.sh`). A phase that doesn't apply returns early.
- **Modules.** New tools get a module name: link with `link_if` / `link_or_merge` / `feature_link` in `lib/install/links.sh`, add packages to `DEPS` in `lib/install/deps.sh` and cross-module needs to `missing_requirements` in `lib/dotfiles.sh`, verify in `check.sh`, and document in `config.example.sh` and the README Modules table. Alias files for a module start with `# module: <name>` and return early when it is disabled.
- **Comments.** English only. Group settings with `# ----` section headers. Every non-obvious setting gets a one-line explanation. No commented-out junk.
- **Cross-platform.** Guard macOS-only features with OS detection. Shell and git configs must work on Linux too, and bash scripts must run on macOS's bash 3.2.
- **Aliases.** Static aliases go in `shell/aliases/<topic>.sh`. Project-specific commands come from `PROJECT_*` variables in `config.sh`.
- **Command discoverability.** Every alias/function in `shell/aliases/*.sh`, and every command `install.sh` generates, gets doc markers directly above it: `# desc:` (required), plus `# usage:`, `# arg:`, `# detail:`, `# example:` as needed, and `# help` when it handles `-h`/`--help`. Files start sections with `# section:`. Commands with arguments implement `-h`/`--help` as Usage / description / Arguments / Examples. Scripts put the markers near the top and end with `# command: <name>`.
- **Tests.** Update `test/run.sh` (Docker fresh install) and `test/macos-dry-run.sh` with every behavior change. `uninstall.sh` finds links into the repo by itself; any new generated file must start with `# Auto-generated by install.sh`. Bash scripts must pass `shellcheck -x -S warning` (CI).
- **`.zshrc` dead zone.** `shell/.zshrc` ends with `return 0` as its last active line — external tools may append content below it, which zsh never executes. Before committing, always check for and warn about any content below `return 0`. Never stage or commit those lines.
- **Backups.** `install.sh` snapshots untracked config files to `~/.config/dotfiles/backups/<timestamp>/` before making changes. See `README.md § Backups`.
- **Dependencies.** When a module gains a package, update the Packages column of the README Modules table.
- **Personal instructions.** Keep this file generic. Personal preferences and machine notes go to `CLAUDE.local.md` (gitignored).
