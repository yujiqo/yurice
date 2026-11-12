#!/bin/sh
[ -r /etc/os-release ] && . /etc/os-release
echo "$(cat /proc/sys/kernel/hostname)"
echo "$(uname -r)"
echo "$(cat /run/current-system/nixos-version 2>/dev/null || nixos-version 2>/dev/null || echo "${VERSION_ID:-$BUILD_ID}")"
echo "$(cut -d' ' -f1 /proc/uptime)"
link=$(readlink /nix/var/nix/profiles/system 2>/dev/null)
echo "$link"
echo "$(stat -c %Y "/nix/var/nix/profiles/$link" 2>/dev/null || echo 0)"
echo "${ID:-linux}"
echo "${NAME:-Linux}"
