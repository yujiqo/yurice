#!/usr/bin/env sh
id=$1
shift
cliphist decode "$id" | wl-copy || exit 1
sleep 0.25
app=$(niri msg --json focused-window | grep -o '"app_id":"[^"]*"' | cut -d'"' -f4)
for term in "$@"; do
  if [ "$app" = "$term" ]; then
    exec wtype -M ctrl -M shift v -m shift -m ctrl
  fi
done
exec wtype -M ctrl v -m ctrl
