#!/bin/sh
size="$1"; dir="$2"; shift 2
mkdir -p "$dir" || exit 1
keep=""
missing=""
while [ $# -ge 2 ]; do
  keep="$keep$(basename "$2")
"
  if [ -f "$2" ]; then
    printf '%s\n' "$2"
  else
    missing="$missing$1	$2
"
  fi
  shift 2
done
for f in "$dir"/*.jpg; do
  [ -e "$f" ] || continue
  printf %s "$keep" | grep -Fxq "$(basename "$f")" || rm -f -- "$f"
done
[ -n "$missing" ] || exit 0
jobs=$(nproc 2>/dev/null || echo 4)
[ "$jobs" -gt 8 ] && jobs=8
printf %s "$missing" | tr '\t\n' '\0\0' | MAGICK_THREAD_LIMIT=1 xargs -0 -n2 -P "$jobs" sh -c '
  magick "$2[0]" -strip -thumbnail "$1^" -quality 85 "$3.tmp.jpg" && mv -- "$3.tmp.jpg" "$3" && printf "%s\n" "$3"
  rm -f -- "$3.tmp.jpg"
' thumb "$size"
exit 0
