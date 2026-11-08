#!/bin/sh
dir="${XDG_CONFIG_HOME:-$HOME/.config}/kitty"
awk '
  $1 == "font_size" { size = $2 }
  $1 == "font_family" {
    family = $0
    sub(/^[ \t]*font_family[ \t]+/, "", family)
    if (match(family, /family="[^"]+"/)) family = substr(family, RSTART + 8, RLENGTH - 9)
  }
  END { if (family != "") printf "%s (%gpt)\n", family, size }
' "$dir/kitty.conf" "$dir/kitty.local.conf" 2>/dev/null
