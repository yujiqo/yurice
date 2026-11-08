#!/bin/sh
config="${XDG_CONFIG_HOME:-$HOME/.config}"
dir="$config/kitty"
cat "$dir/kitty.conf" "$dir/kitty.local.conf" "$config/yurice/custom/kitty/kitty.conf" 2>/dev/null | awk '
  $1 == "font_size" { size = $2 }
  $1 == "font_family" {
    family = $0
    sub(/^[ \t]*font_family[ \t]+/, "", family)
    if (match(family, /family="[^"]+"/)) family = substr(family, RSTART + 8, RLENGTH - 9)
  }
  END { if (family != "") printf "%s (%gpt)\n", family, size }
'
