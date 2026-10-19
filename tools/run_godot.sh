#!/usr/bin/env bash
# Runs the pinned Godot headless on this project with the given arguments; fails on a non-zero exit or on
# any engine/script error in the output (Godot often exits 0 after an error). Full output goes to stdout.
set -uo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
godot="$("$root/tools/godot.sh")" || exit 1
out="$(timeout "${GODOT_TIMEOUT:-120}" "$godot" --headless --path "$root" "$@" 2>&1)"
code=$?
echo "$out"
if [ $code -ne 0 ]; then echo "run_godot: exit code $code"; exit 1; fi
if echo "$out" | grep -qE '^(SCRIPT ERROR|ERROR|Parse Error|USER ERROR)|^WARNING: .*leaked'; then
  echo "run_godot: errors in output"; exit 1
fi
