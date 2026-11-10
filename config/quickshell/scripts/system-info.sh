#!/bin/sh
echo "$(cat /proc/sys/kernel/hostname)"
echo "$(uname -r)"
echo "$(cat /run/current-system/nixos-version 2>/dev/null || nixos-version 2>/dev/null)"
echo "$(cut -d' ' -f1 /proc/uptime)"
link=$(readlink /nix/var/nix/profiles/system)
echo "$link"
echo "$(stat -c %Y "/nix/var/nix/profiles/$link" 2>/dev/null || echo 0)"
