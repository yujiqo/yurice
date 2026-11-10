#!/usr/bin/env bash
set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
cd "$root"

ini=.qmlls.ini
if [ ! -r "$ini" ]; then
  echo "$ini is missing: start the shell once with quickshell so it generates the import paths" >&2
  exit 2
fi

args=()
build=$(sed -n 's/^buildDir="\(.*\)"$/\1/p' "$ini")
[ -n "$build" ] && args+=(-I "$build")
IFS=: read -ra paths <<<"$(sed -n 's/^importPaths="\(.*\)"$/\1/p' "$ini")"
for path in "${paths[@]}"; do
  args+=(-I "$path")
done

mapfile -t files < <(find . -name '*.qml' -not -path './tests/*' | sed 's|^\./||' | sort)
output=$(qmllint "${args[@]}" "$@" "${files[@]}" 2>&1 || true)

grep -E '^Warning: [^ ]+\.qml:[0-9]+' <<<"$output" | grep -vF '[unqualified]' || true
echo
echo "warnings by category:"
grep -oE '^Warning: .*\[[A-Za-z.-]+\]$' <<<"$output" | grep -oE '\[[A-Za-z.-]+\]$' | sort | uniq -c | sort -rn
