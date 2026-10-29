if status is-interactive
  starship init fish | source

  set -gx EDITOR nvim

  alias ls="eza --icons --group-directories-first"
  alias ll="eza -lah --icons --group-directories-first"
  alias l="eza -lh --icons --group-directories-first"
  alias tree="eza --tree --icons --group-directories-first"
  alias less="less -S"
  alias cat="bat --theme base16-256 -S"
  alias top="btop"
  alias lgit="lazygit"

  abbr -a nixos-switch "sudo nixos-rebuild switch --flake"
  abbr -a darwin-switch "sudo darwin-rebuild switch --flake"
end

function fish_greeting; end
