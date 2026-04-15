# ===========================================
# Git Aliases
# ===========================================

# desc: Delete all local branches except master/main/develop
alias branches-delete='git branch | grep -v "master" | grep -v "main" | grep -v "develop" | xargs git branch -D'

# desc: Show compact git log with graph (last 20)
alias gl='git log --oneline --graph --decorate -20'

# desc: Amend last commit without editing the message
alias gamend='git commit --amend --no-edit'

# desc: Show short git status with branch
alias gs='git status --short --branch'
