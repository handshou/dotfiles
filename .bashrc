alias config='/usr/bin/git --git-dir=/Users/h/.cfg/ --work-tree=/Users/h'
alias vim='nvim'
alias ls='ls -al --color'
alias tree='tree -I node_modules'
alias v='vim .'
PATH=/opt/homebrew/bin:$PATH

function parse_git_branch() {
    git branch 2> /dev/null | sed -n -e 's/^\* \(.*\)/[\1] /p'
}

COLOR_DEF=$'%f'
COLOR_USR=$'%F{243}'
COLOR_DIR=$'%F{197}'
COLOR_GIT=$'%F{39}'
setopt PROMPT_SUBST
export PROMPT='${COLOR_USR}%n ${COLOR_DIR}%2~ ${COLOR_GIT}$(parse_git_branch)${COLOR_DEF}$ '
. "$HOME/.cargo/env"
. "/Users/h/.deno/env"