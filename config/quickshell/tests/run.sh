#!/usr/bin/env bash
set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
filter=${1:-}
timeout=${TEST_TIMEOUT:-90}

if [ -z "${WAYLAND_DISPLAY:-}" ]; then
  echo "tests need a running Wayland session (WAYLAND_DISPLAY is unset)" >&2
  exit 2
fi
case $WAYLAND_DISPLAY in
  /*) wayland=$WAYLAND_DISPLAY ;;
  *) wayland=${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/$WAYLAND_DISPLAY ;;
esac

work=$(mktemp -d "${TMPDIR:-/tmp}/yurice-tests.XXXXXX")
pid=""
cleanup() {
  if [ -n "$pid" ]; then
    kill -- "-$pid" 2>/dev/null || true
    wait "$pid" 2>/dev/null || true
  fi
  if [ -n "${TEST_LOG:-}" ] && [ -f "$work/log" ]; then
    cp "$work/log" "$TEST_LOG"
  fi
  if mountpoint -q "$work/run/doc" 2>/dev/null; then
    fusermount -u "$work/run/doc" 2>/dev/null || fusermount -uz "$work/run/doc" || true
  fi
  rm -rf "$work"
}
trap cleanup EXIT

mkdir -p "$work/config" "$work/home" "$work/bin"
mkdir -m 700 "$work/run"
for dir in components services theme modules shaders scripts tests; do
  ln -s "$root/$dir" "$work/config/$dir"
done

for cmd in bluetoothctl brightnessctl busctl cliphist curl dconf identify magick matugen niri qalc \
  realesrgan-ncnn-vulkan systemctl systemd-inhibit wl-copy wl-paste wtype notify-send loginctl; do
  printf '#!/bin/sh\nexit 1\n' > "$work/bin/$cmd"
  chmod +x "$work/bin/$cmd"
done

cat > "$work/config/shell.qml" <<'EOF'
import Quickshell
import qs.components
import qs.services
import qs.theme
import qs.modules.bar
import qs.modules.greeter
import qs.modules.lock
import qs.modules.screenshot
import qs.modules.wallpaper
import qs.tests

ShellRoot {
  Runner {}
}
EOF

cd "$root"
for script in scripts/*.sh; do
  if ! sh -n "$script"; then
    echo "FAIL syntax $script" >&2
    exit 1
  fi
done

smoke=$(find components modules services theme -name '*.qml' | sort | tr '\n' ':')
tests=$(cd tests && ls Test*.qml | sed 's/\.qml$//' | tr '\n' ':')
instantiate=$(find components modules/bar -name '*.qml' | sort | while read -r file; do
  grep -q '^pragma Singleton' "$file" && continue
  grep -qE '^(PanelWindow|Variants) \{' "$file" && continue
  echo "$file"
done | tr '\n' ':')

log="$work/log"
show_log() {
  grep -vE "xdg-desktop-portal|GLib-GIO|^\s*$" "$log" | sed "s/\x1b\[[0-9;]*m//g" >&2
}
env -u NIRI_SOCKET -u DBUS_SESSION_BUS_ADDRESS -u HYPRLAND_INSTANCE_SIGNATURE \
  HOME="$work/home" \
  XDG_CONFIG_HOME="$work/home/.config" \
  XDG_CACHE_HOME="$work/home/.cache" \
  XDG_STATE_HOME="$work/home/.local/state" \
  XDG_DATA_HOME="$work/home/.local/share" \
  XDG_RUNTIME_DIR="$work/run" \
  WAYLAND_DISPLAY="$wayland" \
  QT_QPA_PLATFORM=wayland \
  PATH="$work/bin:$PATH" \
  YURICE_SMOKE="$smoke" \
  YURICE_TESTS="$tests" \
  YURICE_INSTANTIATE="$instantiate" \
  YURICE_FILTER="$filter" \
  setsid dbus-run-session -- quickshell -p "$work/config" > "$log" 2>&1 &
pid=$!

deadline=$((SECONDS + timeout))
while ! grep -q '@@DONE' "$log" 2>/dev/null; do
  if ! kill -0 "$pid" 2>/dev/null; then
    show_log
    echo "quickshell exited before finishing" >&2
    exit 1
  fi
  if [ $SECONDS -ge $deadline ]; then
    show_log
    echo "timed out after ${timeout}s" >&2
    exit 1
  fi
  sleep 0.2
done

results=$(grep -oE '@@(PASS|FAIL|DONE).*' "$log" | sed 's/\x1b\[[0-9;]*m//g')
runtime=$(sed 's/\x1b\[[0-9;]*m//g' "$log" | grep -E 'ReferenceError|TypeError|RangeError|SyntaxError|is not defined|was not initialized|Unable to assign|Cannot assign' | sed -E 's/^ *[A-Z]+ *[a-z.]*: *//' | sort -u || true)
if [ -n "$runtime" ]; then
  results+=$'\n'$(sed 's/^/@@FAIL runtime: /' <<<"$runtime")
fi
grep '^@@FAIL' <<<"$results" | sed 's/^@@FAIL /FAIL /' || true
pass=$(grep -c '^@@PASS' <<<"$results" || true)
fail=$(grep -c '^@@FAIL' <<<"$results" || true)
echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
