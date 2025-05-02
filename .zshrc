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
export PATH="/Users/h/.local/bin:$PATH"

# pnpm
export PNPM_HOME="/Users/h/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

# Added by Windsurf
export PATH="/Users/h/.codeium/windsurf/bin:$PATH"

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
