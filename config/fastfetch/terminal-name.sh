#!/bin/sh
if [ -n "$TMUX" ]; then
  client=$(tmux display-message -p '#{client_termname}')
  case "$client" in
    xterm-kitty) kitty --version | awk '{ print "Kitty", $2 }' ;;
    *) printf '%s\n' "$client" ;;
  esac
else
  fastfetch -c none --logo none --pipe true --structure terminal --key-type none
fi
