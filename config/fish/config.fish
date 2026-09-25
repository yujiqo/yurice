starship init fish | source

function fish_greeting; end

set -gx EDITOR nvim

alias ls="eza --icons --group-directories-first"
alias ll="eza -lah --icons --group-directories-first"
alias l="eza -lh --icons --group-directories-first"
alias tree="eza --tree --icons --group-directories-first"
alias top="btop"
alias nixos-switch="sudo nixos-rebuild switch --flake"
