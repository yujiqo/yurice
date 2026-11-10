#!/bin/sh
f="$1"
T="${XDG_DATA_HOME:-$HOME/.local/share}/Trash"
mkdir -p "$T/files" "$T/info" || exit 1
base=$(basename "$f")
stem="${base%.*}"
ext="${base##*.}"
name="$base"
n=1
while [ -e "$T/files/$name" ] || [ -e "$T/info/$name.trashinfo" ]; do
  name="$stem.$n.$ext"
  n=$((n + 1))
done
printf "[Trash Info]\nPath=%s\nDeletionDate=%s\n" "$2" "$(date +%Y-%m-%dT%H:%M:%S)" > "$T/info/$name.trashinfo" || exit 1
mv -- "$f" "$T/files/$name" || { rm -f "$T/info/$name.trashinfo"; exit 1; }
