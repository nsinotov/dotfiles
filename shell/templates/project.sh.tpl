# ===========================================
# Project Commands Template (module: zsh)
# ===========================================
# Shows what install.sh generates into ~/.aliases.d/project-<name>.sh for each
# PROJECT_<N>_* block in ~/.config/dotfiles/config.sh. Every command is
# optional: it exists only when its variable is set. Run `dotfiles <command>`
# to see the generated docs, including the exact command each one runs.
#
#   Variable                  Generates          Notes
#   PROJECT_<N>_NAME          prefix <name>-     required
#   PROJECT_<N>_APP           <name>-app         + _APP_PORT: frees the port first
#   PROJECT_<N>_API           <name>-api         + _API_PORT: frees the port first
#   _APP_PORT / _API_PORT     <name>-stop        stops whichever servers have ports
#   PROJECT_<N>_TEST          <name>-test
#   PROJECT_<N>_E2E           <name>-e2e
#   PROJECT_<N>_STORYBOOK     <name>-storybook
#   PROJECT_<N>_INSTALL       <name>-install
#   PROJECT_<N>_REINSTALL     <name>-reinstall
#   PROJECT_<N>_WT_REPO       <name>-wt-new, <name>-wt-done, <name>-wt-ls
#
# Modifiers:
#
#   PROJECT_<N>_PRETEST       Runs before app/api/test/storybook/install/reinstall
#                             and before WT_INSTALL in wt-new; a non-zero exit
#                             aborts the command (e.g. a malware scan).
#   PROJECT_<N>_ENV           Space-separated KEY=value pairs passed (via `env`)
#                             to app/api/test/e2e/storybook only. No spaces in values.
#   PROJECT_<N>_DIR +         Git email for every repo under DIR (module: git,
#   PROJECT_<N>_GIT_EMAIL     via includeIf in ~/.gitconfig).
#   PROJECT_<N>_WT_BRANCH     Base branch for wt-new (default: main).
#   PROJECT_<N>_WT_ENV_FILES  Files copied from the main repo into new worktrees.
#   PROJECT_<N>_WT_INSTALL    Dependency install run in new worktrees.
#   PROJECT_<N>_TMUX_WINDOWS  "name:panes[:layout] ..." — wt-new opens a tmux
#                             session <name>-<branch> (module: tmux).
#
# Commands with arguments append extra arguments to the configured command
# (aliases). Servers with ports are freed first: the listener and its parent
# processes are killed, and Ctrl-C stops the whole process tree.
#
# Worktrees are created next to WT_REPO as <name>-<branch>, with slashes in the
# branch replaced by dashes (hotfix/DEV-1 → ~/projects/acme-hotfix-DEV-1).
#
# Example config.sh:
#
#   PROJECT_1_NAME=acme
#   PROJECT_1_APP="yarn nx serve web"
#   PROJECT_1_APP_PORT=3000
#   PROJECT_1_TEST="yarn nx affected --target=test"
#   PROJECT_1_WT_REPO="$HOME/projects/acme"
#   PROJECT_1_TMUX_WINDOWS="bash:4:tiled agent:1 code:1"
#
# Generated ~/.aliases.d/project-acme.sh (doc markers shortened):
#
#   # section: Project: acme
#
#   # desc: Start the app on port 3000, stopping whatever listens there first
#   # usage: [args]
#   # detail: Runs: yarn nx serve web
#   alias acme-app='_run_on_port 3000 -- yarn nx serve web'
#
#   # desc: Stop the app server (port 3000)
#   # help
#   acme-stop() { ... }
#
#   # desc: Run the tests
#   alias acme-test='yarn nx affected --target=test'
#
#   # desc: Create a worktree and branch, ready to work in
#   # usage: <branch> [base-branch]
#   # help
#   acme-wt-new() { ... }
#   acme-wt-done() { ... }
#   acme-wt-ls() { ... }
#
# Shared port helpers (_run_on_port, _free_port) live in ~/.aliases.d/_port-helpers.sh.
