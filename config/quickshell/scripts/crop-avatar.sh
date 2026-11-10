#!/bin/sh
src="$1"; out="$2"; x="$3"; y="$4"; side="$5"
mkdir -p "$(dirname "$out")" || exit 1
dims=$(magick "$src[0]" -auto-orient -format "%w %h" info:) || exit 1
geo=$(echo "$dims" | awk -v x="$x" -v y="$y" -v s="$side" "{ w = \$1; h = \$2; n = int(s * w + 0.5); printf \"%dx%d+%d+%d\", n, n, int(x * w + 0.5), int(y * h + 0.5) }")
tmp="${out%.*}.tmp.${out##*.}"
magick "$src[0]" -auto-orient -crop "$geo" +repage -resize "512x512!" -strip -quality 92 "$tmp" || { rm -f "$tmp"; exit 1; }
mv "$tmp" "$out"
