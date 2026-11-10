#!/bin/sh
wall="$1"; avatar="$2"; colors="$3"; size="$4"; cache="$5"; dir="$6"
mkdir -p "$(dirname "$cache")"
if [ -f "$wall" ] && [ "$(cat "$cache.path" 2>/dev/null)" != "$wall" ]; then
  magick "$wall[0]" -resize "$size^" -strip -quality 95 "$cache.tmp.jpg" || exit 1
  mv "$cache.tmp.jpg" "$cache"
  printf %s "$wall" > "$cache.path"
fi
[ -d "$dir" ] && [ -w "$dir" ] || exit 0
if [ -f "$wall" ] && [ -f "$cache" ]; then
  cp "$cache" "$dir/.wallpaper.tmp" && mv "$dir/.wallpaper.tmp" "$dir/wallpaper.jpg"
else
  rm -f "$dir/wallpaper.jpg"
fi
if [ -f "$avatar" ]; then
  magick "$avatar[0]" -resize "256x256^" -strip -quality 92 "$dir/.avatar.tmp.jpg" && mv "$dir/.avatar.tmp.jpg" "$dir/avatar.jpg"
else
  rm -f "$dir/avatar.jpg"
fi
[ -f "$colors" ] && cp "$colors" "$dir/.colors.tmp" && mv "$dir/.colors.tmp" "$dir/colors.json"
chmod 644 "$dir"/wallpaper.jpg "$dir"/avatar.jpg "$dir"/colors.json 2>/dev/null
exit 0
