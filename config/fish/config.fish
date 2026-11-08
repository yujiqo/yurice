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

function files
    setsid -f nautilus $argv[1] (or echo .) &>/dev/null
end

function fastfetch
    set -l generated ~/.cache/yurice/fastfetch.jsonc
    if not test -f $generated
        command fastfetch $argv
        return
    end
    if test (count $argv) -gt 0; or not isatty stdout
        command fastfetch -c $generated $argv
        return
    end

    set -l logo_slot 32
    set -l logo_margin 6
    set -l text_columns (math $COLUMNS - $logo_slot - $logo_margin)

    set -l rendered (command fastfetch -c $generated --pipe false | awk -v columns=$text_columns -f ~/.config/fastfetch/wrap.awk)

    set -l logo_height 16
    if test (math "($rendered[2] - $logo_height) % 2") -ne 0
        set logo_height 15
    end
    set -l logo_width (math "$logo_height * 2")
    set -l logo_right (math "$logo_margin + $logo_slot - $logo_width")
    set -l logo_top (math -s0 "max(0, ($rendered[2] - $logo_height) / 2 - 1)")

    command fastfetch -c (printf '{"logo":{"source":"~/.config/fastfetch/images/nixos.png","type":"kitty-icat","width":%s,"height":%s,"padding":{"top":%s,"left":0,"right":%s}},"modules":[%s]}' $logo_width $logo_height $logo_top $logo_right $rendered[1] | psub -s .jsonc)
end

function fish_greeting; end

# path for uv tools
fish_add_path "~/.local/bin"

set -l custom ~/.config/yurice/custom/fish/config.fish
test -f $custom; and source $custom
