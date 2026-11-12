#!/bin/sh
set -eu

src=$1
dst=${2:-"$HOME/Pictures/Wallpapers"}
marker="${XDG_STATE_HOME:-$HOME/.local/state}/yurice/wallpapers-seeded"

[ -e "$marker" ] && exit 0
[ -d "$src" ] || exit 0

mkdir -p "$dst" "$(dirname "$marker")"
for file in "$src"/*; do
  [ -f "$file" ] || continue
  target="$dst/$(basename "$file")"
  [ -e "$target" ] && continue
  cp "$file" "$target"
  chmod u+w "$target"
done
touch "$marker"
