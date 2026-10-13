# ===========================================
# Git Aliases
# ===========================================
# section: Git

# desc: Delete local branches except master/main/develop and the current one
# detail: Lists the branches first and asks before force-deleting (git branch -D),
# detail: so unmerged work on those branches is lost.
# example: branches-delete
# help
branches-delete() {
  if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
    cat <<'HELP'
Usage: branches-delete

Force-delete every local branch except master, main, develop and the current
branch. Lists the branches and asks before deleting; unmerged work is lost.

Examples:
  branches-delete
HELP
    return 0
  fi
  local current branches
  current="$(git branch --show-current)" || return 1
  # Exact, literal names only, so e.g. "maintenance" is not protected by "main"
  branches="$(git for-each-ref --format='%(refname:short)' refs/heads |
    grep -vxF -e master -e main -e develop -e "$current")"
  if [ -z "$branches" ]; then
    echo "No branches to delete."
    return 0
  fi
  printf '%s\n' "$branches"
  printf "Force-delete these branches? [y/N] "
  local reply
  read -r reply
  [ "$reply" = "y" ] || [ "$reply" = "Y" ] || return 0
  printf '%s\n' "$branches" | while IFS= read -r b; do git branch -D "$b"; done
}

# desc: Compact git log with graph (last 20 commits)
# usage: [git-log-options]
# arg: [git-log-options]  Any git log options; they are added after the defaults
# detail: Runs: git log --oneline --graph --decorate -20
# example: gl
# example: gl -50 --author="Jane"
# example: gl main..HEAD
alias gl='git log --oneline --graph --decorate -20'

# desc: Amend the last commit without editing its message
# usage: [git-commit-options]
# detail: Runs: git commit --amend --no-edit (stage changes first)
# example: git add -p && gamend
# example: gamend --date=now
alias gamend='git commit --amend --no-edit'

# desc: Short git status with branch and tracking info
# usage: [paths]
# detail: Runs: git status --short --branch
# example: gs
# example: gs src/
alias gs='git status --short --branch'
