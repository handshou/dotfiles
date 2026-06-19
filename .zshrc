# Homebrew
eval "$(/opt/homebrew/bin/brew shellenv)"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

source ~/.bashrc

# prune git branches
function prune-local () {
  git fetch -p;
  git branch -vv | grep ': gone]' | grep -v '*' | awk '{ print $1; }' > /tmp/branch-to-delete;
  ${EDITOR:-vi} /tmp/branch-to-delete;
  xargs git branch -D < /tmp/branch-to-delete;
  rm /tmp/branch-to-delete;
}

# poetry in python3
export PATH="$HOME/.local/bin:$PATH"

# pnpm
export PNPM_HOME="$HOME/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

# Darktable
export PATH="/Applications/darktable.app/Contents/MacOS:$PATH"

source <(fzf --zsh)

# Add tmux-sessionizer script to PATH
export PATH="$HOME/scripts/tmux-sessionizer:$PATH"

# Alias for tmux-sessionizer
alias tmux-sessionizer="tmux-sessionizer"

# Add ssh keys for git
if [ "$SSH_AUTH_SOCK" = "" -a -x /usr/bin/ssh-agent ]; then
    eval `/usr/bin/ssh-agent`
    # eval "$(ssh-agent -s)"
    ssh-add ~/.ssh/id_ed25519_work
    ssh-add ~/.ssh/id_ed25519
fi

# Format ONLY the Python files you've changed (working tree + staged) on the
# current branch — never the whole tree. Mirrors the lefthook pre-commit hook
# (`ruff format {staged_files}`) so manual runs stop reformatting dormant files
# owned by other teams. ruff discovers each file's nearest pyproject.toml, so
# per-service config (quote-style etc.) still applies.
function ruff-mine () {
  local files
  files=$( { git diff --name-only --diff-filter=d HEAD -- '*.py'; \
             git diff --cached --name-only --diff-filter=d -- '*.py'; } \
           | sort -u | grep . )
  if [ -z "$files" ]; then
    echo "ruff-mine: no changed .py files"
    return 0
  fi
  echo "$files" | tr '\n' ' ' | xargs ruff format
  echo "$files" | tr '\n' ' ' | xargs ruff check --fix
}
