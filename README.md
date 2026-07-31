# dotfiles

Developer environment configuration files for macOS/Linux.

## What's Inside

| Directory          | Tool             | Description                                                   |
| ------------------ | ---------------- | ------------------------------------------------------------- |
| `shell/`           | Zsh + Oh My Zsh  | Shell config, topic-based aliases, key bindings               |
| `shell/aliases/`   | —                | Static aliases grouped by topic (git, media, navigation, tmux) |
| `shell/templates/` | —                | Documentation for generated project and account aliases       |
| `terminal/`        | Ghostty          | Terminal emulator (Catppuccin Mocha, Monaspice font)          |
| `editor/`          | Neovim (LazyVim) | Editor with Catppuccin theme, LSP support                     |
| `git/`             | Git              | Config template, global gitignore, modern defaults            |
| `tmux/`            | Tmux             | Multiplexer with TPM, vim-tmux-navigator, session persistence, `prefix+T` sesh picker, F12 nested tmux toggle |
| `prompt/`          | Starship         | Cross-shell prompt (clean, icons only)                        |
| `tools/`           | AeroSpace, VPN, sesh | Tiling window manager (macOS), OpenVPN connection manager, tmux session picker config |

## Architecture

```
┌─────────────────────────────────────────────────────┐
│  ~/.config/dotfiles/.secrets (secrets, project definitions, identity)    │  ← never committed
├─────────────────────────────────────────────────────┤
│  install.sh reads .secrets and:                     │
│    1. Symlinks static configs to system paths       │
│    2. Generates .gitconfig with identity            │
│    3. Generates project aliases → ~/.aliases.d/     │
│    4. Generates Claude account functions            │
│    5. Links custom scripts to ~/bin/                │
├─────────────────────────────────────────────────────┤
│  .zshrc sources:                                    │
│    • shell/aliases/*.sh              (static, from repo)      │
│    • ~/.aliases.d/*.sh               (generated, not tracked) │
│    • ~/.config/dotfiles/aliases.d/*  (local extras, not tracked) │
└─────────────────────────────────────────────────────┘
```

## Quick Start

```bash
# 1. Clone the repo
git clone <repo-url> ~/dotfiles
cd ~/dotfiles

# 2. Set up secrets
cp .secrets.example ~/.config/dotfiles/.secrets
# Edit ~/.config/dotfiles/.secrets with real values (git identity, project definitions, tokens)

# 3. Install (symlinks configs, generates project aliases)
chmod +x install.sh && ./install.sh

# 4. Verify everything is set up correctly
./check.sh

# 5. Install tmux plugins (inside tmux)
# Press Ctrl+S, then I
```

## Dependencies

### Required

| Tool | Why |
| --- | --- |
| git | Install script, lazy.nvim bootstrap, diffview, worktree aliases |
| zsh | Shell — `.zshrc` is zsh-specific |
| [Oh My Zsh](https://ohmyz.sh/) | Plugin framework — git, zsh-autosuggestions, zsh-syntax-highlighting |
| [Neovim](https://neovim.io/) (≥ 0.9) | Editor — entire `editor/nvim/` config targets it |
| C compiler (gcc or clang) | Treesitter needs one to compile parsers |
| [Node.js](https://nodejs.org/) (via nvm) | LSP servers installed by Mason, LazyVim TypeScript/Prettier/ESLint extras |
| [ripgrep](https://github.com/BurntSushi/ripgrep) | LazyVim grep/search |
| [fd](https://github.com/sharkdophin/fd) | LazyVim file finder |
| [tmux](https://github.com/tmux/tmux) | Multiplexer — `.tmux.conf` and all session management |
| [TPM](https://github.com/tmux-plugins/tpm) | Tmux plugin manager — vim-tmux-navigator, resurrect, continuum, catppuccin |
| [fzf](https://github.com/junegunn/fzf) | Sesh picker (`prefix+T`), vpn menu |

### Recommended

| Tool | Why |
| --- | --- |
| [Starship](https://starship.rs/) | Shell prompt — `.zshrc` calls `starship init zsh` |
| [sesh](https://github.com/joshmedeski/sesh) | Tmux session/directory fuzzy switcher |
| [zoxide](https://github.com/ajeetdsouza/zoxide) | Smarter `cd` — powers sesh directory source |
| [lazygit](https://github.com/jesseduffield/lazygit) | Git TUI — integrated via LazyVim Snacks terminal |
| [gh](https://cli.github.com/) | GitHub CLI |

### macOS only

| Tool | Why |
| --- | --- |
| [Ghostty](https://ghostty.org/) | Terminal emulator (Catppuccin Mocha, Monaspace Nerd Font) |
| [AeroSpace](https://github.com/nikitabobko/AeroSpace) | Tiling window manager |
| [JankyBorders](https://github.com/FelixKratz/JankyBorders) | Focused-window border highlight (launched by AeroSpace) |
| [macism](https://github.com/laishulu/macism) | Input-method switcher for Cyrillic safety net in Neovim |
| [Monaspace Nerd Font](https://github.com/ryanoasis/nerd-fonts) | Terminal and editor font |

### Optional (specific features)

| Tool | Used by |
| --- | --- |
| ffmpeg | `compress-mov`, `compress-mp4` aliases |
| ghostscript | `compress-pdf` alias |
| openvpn | `vpn` script (`tools/vpn`) |
| xclip | Tmux copy-mode on Linux (macOS uses pbcopy) |

## Adding a Project

Define project variables in `~/.config/dotfiles/.secrets` and re-run `install.sh`:

```bash
# In ~/.config/dotfiles/.secrets
PROJECT_1_NAME=myapp
PROJECT_1_APP="nx serve app"
PROJECT_1_APP_PORT=3000
PROJECT_1_API="nx serve api"
PROJECT_1_API_PORT=8081
PROJECT_1_TEST="yarn test"
PROJECT_1_E2E="yarn e2e"
PROJECT_1_REINSTALL="rm -rf node_modules && yarn"
```

This generates aliases: `myapp-app`, `myapp-api`, `myapp-stop`, `myapp-test`, `myapp-e2e`, `myapp-reinstall`.

When `APP_PORT` or `API_PORT` is set:
- Running `myapp-app` / `myapp-api` will automatically kill any process already listening on that port before starting the server. This lets you switch between worktrees without manually finding and stopping the old instance — just run the command and it takes over.
- On Ctrl-C, the full process tree is cleaned up (including child processes that escape the terminal's process group, e.g. nx executor workers).
- `myapp-stop` kills all app and API server processes on the configured ports.

### Worktree management

Add worktree variables to enable `wt-new`, `wt-done`, and `wt-ls` functions:

```bash
PROJECT_1_WT_REPO="$HOME/projects/myapp"
PROJECT_1_WT_BRANCH=main                              # base branch for new worktrees (default: main)
PROJECT_1_WT_ENV_FILES=".env apps/app/.env"            # env files copied from main repo
PROJECT_1_WT_INSTALL="pnpm install"                    # run after worktree creation
PROJECT_1_TMUX_WINDOWS="main:4:tiled agent:1 ide:1"   # optional tmux session layout
```

Generated functions:

| Function | Description |
| --- | --- |
| `myapp-wt-new <branch>` | Create worktree, copy env files, install deps, start tmux session (if configured). Stays in current directory. |
| `myapp-wt-done <branch>` | Remove worktree + directory, delete local branch, kill tmux session |
| `myapp-wt-ls` | List all worktrees for the project |

`TMUX_WINDOWS` format is `"name:panes[:layout]"` — each entry creates a tmux window with the given number of panes. Layout is optional (e.g. `tiled`, `even-horizontal`).

Standalone equivalent: `tmux-session <dir> [windows-spec]` creates (or attaches to) a session for any directory using the same spec format. Session name = basename of the directory; on collision it becomes `<parent>-<basename>`. Default spec is `"main:4:tiled agent:1 ide:1"`, overridable via `TMUX_SESSION_WINDOWS`.

`wt-done` has a safety guard that refuses to remove the main project directory or primary worktree.

See `shell/templates/` for full documentation on the template system.

## Local Aliases

For project-specific commands that shouldn't live in the repo (dev tools, credentials-dependent scripts, one-off shortcuts), drop a `.sh` file into `~/.config/dotfiles/aliases.d/`:

```bash
# ~/.config/dotfiles/aliases.d/voxia.sh

# desc: Start Twilio dev phone
voxia-dev-phones() {
  TWILIO_AUTH_TOKEN="$TWILIO_AUTH_TOKEN" \
  TWILIO_ACCOUNT_SID="$TWILIO_ACCOUNT_SID" \
  twilio dev-phone
}
```

- Files here are sourced by `.zshrc` on every shell start — no install step needed.
- `install.sh` creates the directory but never writes or deletes files inside it.
- Credentials go in `~/.config/dotfiles/.secrets` alongside the project's `PROJECT_N_*` block; they are auto-exported by `.zshrc`'s `set -a` block.
- Annotate with `# desc:` (and optionally `# help`) to have the command appear in the `dotfiles` listing under "Local aliases".

See `shell/templates/local-aliases.sh.tpl` for a full annotated example.

## Discovering Commands

Run `dotfiles` in any shell to list every custom command this repo provides, grouped by category (git, media, navigation, tmux, scripts, per-project, Claude accounts). Commands marked with `*` support `-h`/`--help` for detailed usage:

```bash
dotfiles            # list everything
tmux-session --help # show usage for one command
vpn --help
myapp-wt-new -h
```

The static sections (git, media, navigation, tmux, projects, Claude accounts) are baked in by `install.sh` from `# desc:` / `# help` markers in `shell/aliases/*.sh` and definitions in `~/.config/dotfiles/.secrets`. The "Local aliases" section is scanned at runtime from `~/.config/dotfiles/aliases.d/` — no install step needed when you add a new file there.

## Claude Accounts

The setup supports one personal account and any number of work accounts, each fully isolated.

| Command | Config dir | Description |
|---|---|---|
| `claude-personal` | `~/.claude-personal/` | Personal Anthropic account, never touched by work proxies |
| `claude` | delegates to `CLAUDE_SYMLINK_ACCOUNT` or `claude-personal` | Default command — routes to the active work account if configured |
| `claude-<name>` | `CLAUDE_ACCOUNT_N_CONFIG_DIR` | One per work account, generated by `install.sh` from `.secrets` |

### How it works

- **Personal** account uses `CLAUDE_CONFIG_DIR=~/.claude-personal/`. That directory is not registered with any work proxy, so it is always clean.
- **Work** accounts are defined by `CLAUDE_ACCOUNT_N_*` variables in `.secrets`. Each gets a `claude-<name>()` function with its own environment (API keys, proxy URLs, model overrides).
- **`CLAUDE_SYMLINK_ACCOUNT`** names one work account whose `CONFIG_DIR` is symlinked to `~/.claude/`. Company tools that manage `~/.claude/` (e.g. anyray) affect only that account.
- **`claude`** reads `CLAUDE_SYMLINK_ACCOUNT` at runtime and delegates to `claude-<name>` if set, otherwise falls back to `claude-personal`.

### Adding a work account

```bash
# In ~/.config/dotfiles/.secrets
CLAUDE_ACCOUNT_2_NAME=newco
CLAUDE_ACCOUNT_2_CONFIG_DIR=$HOME/.claude-newco
CLAUDE_ACCOUNT_2_EXTRA_VARS="ANTHROPIC_BASE_URL=http://proxy ANTHROPIC_AUTH_TOKEN=sk-..."

# Re-run install.sh to generate the claude-newco() function
./install.sh
```

## Backups

`install.sh` automatically snapshots all non-tracked config files before making any changes:

```
~/.config/dotfiles/backups/<timestamp>/
  .secrets                                   ← secrets file
  aliases.d/                                 ← local extra alias files
  claude/settings.json                       ← Claude Code default config (~/.claude/)
  claude-personal/settings.json              ← Claude Code personal account
  claude-<name>/settings.json                ← one entry per work account in .secrets
  claude-desktop/claude_desktop_config.json  ← Claude Desktop MCP config (macOS)
  claude-desktop/config.json                 ← Claude Desktop preferences and auth (macOS)
```

Each `install.sh` run creates a new timestamped snapshot. Old snapshots are never deleted automatically.

### Restoring

```bash
SNAP=~/.config/dotfiles/backups/<timestamp>

cp "$SNAP/.secrets" ~/.config/dotfiles/.secrets
cp -R "$SNAP/aliases.d" ~/.config/dotfiles/
cp "$SNAP/claude/settings.json" ~/.claude/settings.json

# Re-run to regenerate everything from .secrets
./install.sh
```

## Server Deployment

When setting up tmux on a remote server using this config, omit the **"Nested Tmux Toggle (F12)"** section from `.tmux.conf`. That section is for local workstations only — it lets F12 pass all keystrokes through to a remote (nested) tmux. Including it on the server would cause an accidental double-F12 to disable bindings on both ends.

The section is clearly marked with `LOCAL WORKSTATION ONLY` in the config file.

## Key Design Decisions

- **Symlinks for static configs.** Edits on the system are edits in the repo — no manual sync needed.
- **Generated files for anything with secrets.** `.gitconfig`, project aliases, and Claude account functions are built from `~/.config/dotfiles/.secrets` by `install.sh`. They are never committed.
- **Topic-based alias files.** Aliases are split by concern (git, media, navigation, tmux), not dumped in one file.
- **Catppuccin Mocha everywhere.** Consistent theme across Ghostty, Neovim, and Tmux.
