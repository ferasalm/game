#!/usr/bin/env bash
# Brings the main checkout up to origin/main and proves the game starts (2026-10-24: merges pulled without a re-import
# left a stale class cache; ~60 "not declared" errors and the game did not run). Usage (cwd = C:/dev/game):
# bash tools/sync_main.sh   -> last line SYNC PASS <commit> or SYNC FAIL <step>.
root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root" || exit 1
git fetch -q origin && git pull -q --ff-only origin main || { echo "SYNC FAIL pull"; exit 1; }
bash tools/run_godot.sh --import > /dev/null 2>&1 || { echo "SYNC FAIL import"; exit 1; }
out="$(bash tools/run_godot.sh res://tools/smoke_new_game.tscn 2>&1)"
if [ $? -ne 0 ] || ! grep -q "SMOKE scene=PrototypeMain" <<< "$out"; then
  grep -E "ERROR|SMOKE" <<< "$out" | sort | uniq -c | sort -rn | head -10
  echo "SYNC FAIL smoke"; exit 1
fi
echo "SYNC PASS $(git rev-parse --short HEAD)"
