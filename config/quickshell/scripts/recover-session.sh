#!/bin/sh
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"

socket=$(ls -t "$XDG_RUNTIME_DIR"/niri.wayland-*.sock 2>/dev/null | head -n 1)
if [ -z "$socket" ]; then
  echo "no running niri session found" >&2
  exit 1
fi

name=${socket##*/niri.}
export WAYLAND_DISPLAY="${WAYLAND_DISPLAY:-${name%%.*}}"
export NIRI_SOCKET="${NIRI_SOCKET:-$socket}"

quiet=0
tries=0
while [ "$quiet" -lt 5 ] && [ "$tries" -lt 40 ]; do
  instances=$(qs list "$@" 2>/dev/null)
  if printf '%s\n' "$instances" | grep -q '^Instance '; then
    quiet=0
    if [ "$tries" -gt 10 ]; then
      printf '%s\n' "$instances" | sed -n 's/.*Process ID: //p' | xargs -r kill -9
    else
      qs kill "$@" 2>/dev/null
    fi
  else
    quiet=$((quiet + 1))
  fi
  tries=$((tries + 1))
  sleep 1
done

qs -n -d "$@"
