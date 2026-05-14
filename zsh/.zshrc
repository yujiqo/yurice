export ZSH="$HOME/.oh-my-zsh"
export PATH="/opt/homebrew/bin:$PATH"

ZSH_THEME="minimal"
DISABLE_AUTO_TITLE="true"
zstyle ':omz:update' mode reminder

plugins=(git zsh-syntax-highlighting)

source $ZSH/oh-my-zsh.sh

# -----------------------------------------

alias nvim="nvim -p"
alias quote="fortune | cowsay"
export PATH="/Library/TeX/texbin:$PATH"
