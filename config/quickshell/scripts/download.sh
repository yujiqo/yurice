#!/bin/sh
url="$1"; path="$2"; agent="$3"
mkdir -p "$(dirname "$path")" || exit 1
set -- -fsSL --retry 2 -o "$path.part"
[ -n "$agent" ] && set -- "$@" -A "$agent"
curl "$@" "$url" || { rm -f "$path.part"; exit 1; }
mv "$path.part" "$path"
