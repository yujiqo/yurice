#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
for frag in *.frag; do
  nix shell nixpkgs#qt6.qtshadertools -c qsb --qt6 -o "$frag.qsb" "$frag"
done
