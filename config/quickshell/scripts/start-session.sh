#!/bin/sh
printf '\033[2J\033[H\033[?25l'

[ "$#" -gt 0 ] || set -- niri-session
exec "$@" >/dev/null 2>&1
