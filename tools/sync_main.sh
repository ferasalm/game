#!/usr/bin/env bash
# Brings the main checkout up to origin/main and proves the game starts (2026-10-24: merges pulled without a re-import
# left a stale class cache; ~60 "not declared" errors and the game did not run). Usage (cwd = C:/dev/game):
# bash tools/sync_main.sh   -> last line SYNC PASS <commit> or SYNC FAIL <step>. A dirty tracked tree fails with
# SYNC FAIL dirty and the checkout is left untouched (untracked files are fine).
root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root" || exit 1
git diff --quiet HEAD -- || { echo "SYNC FAIL dirty"; exit 1; }  # never carry uncommitted tracked changes across the switch
[ "$(git rev-parse --abbrev-ref HEAD)" = main ] || git switch -q main || { echo "SYNC FAIL branch"; exit 1; }  # a pull on a side branch left main behind
git fetch -q origin || { echo "SYNC FAIL pull"; exit 1; }
# A file that was hand-copied here untracked and that origin/main now tracks with IDENTICAL content (the usage hook,
# row 26 11-02) would make the pull refuse to overwrite it: drop that copy, the tracked one replaces it. A differing
# untracked file is never touched (the pull then fails and says so).
for f in $(git diff --name-only --diff-filter=A HEAD origin/main 2> /dev/null); do
  if [ -f "$f" ] && ! git ls-files --error-unmatch -- "$f" > /dev/null 2>&1 &&
     [ "$(git hash-object -- "$f")" = "$(git rev-parse "origin/main:$f" 2> /dev/null)" ]; then rm -f -- "$f"; fi
done
git pull -q --ff-only origin main || { echo "SYNC FAIL pull"; exit 1; }
bash tools/run_godot.sh --import > /dev/null 2>&1 || { echo "SYNC FAIL import"; exit 1; }
out="$(bash tools/run_godot.sh --quit-after 300 2>&1)"
if [ $? -ne 0 ]; then
  grep -E "ERROR" <<< "$out" | sort | uniq -c | sort -rn | head -10
  echo "SYNC FAIL smoke"; exit 1
fi
echo "SYNC PASS $(git rev-parse --short HEAD)"
