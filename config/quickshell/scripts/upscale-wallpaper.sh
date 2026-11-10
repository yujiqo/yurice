#!/bin/sh
src="$1"; dst="$2"; backup="$3"; scale="$4"; size="$5"
tmp=$(mktemp -d "${XDG_RUNTIME_DIR:-/tmp}/yurice-upscale.XXXXXX") || exit 1
trap "rm -rf \"$tmp\"" EXIT
magick "$src[0]" -strip "$tmp/in.png" || exit 1
realesrgan-ncnn-vulkan -i "$tmp/in.png" -o "$tmp/out.png" -n realesr-animevideov3 -s "$scale" -t 128 || exit 1
before=$(magick "$tmp/in.png" -format "%[fx:mean]" info:)
after=$(magick "$tmp/out.png" -format "%[fx:mean]" info:)
if awk -v a="$after" -v b="$before" "BEGIN { exit !(a < b * 0.6) }"; then
  echo "output looks corrupted (mean $after vs $before)" >&2
  exit 1
fi
magick "$tmp/out.png" -filter Lanczos -resize "$size^>" "$tmp/final.png" || exit 1
mkdir -p "$(dirname "$backup")" || exit 1
[ -e "$backup" ] && backup="${backup%.*}.$(date +%s).${backup##*.}"
mv -- "$src" "$backup" || exit 1
mv -- "$tmp/final.png" "$dst" || { mv -- "$backup" "$src"; exit 1; }
