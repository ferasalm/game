#!/usr/bin/env bash
# Lists (default) or removes (--apply) builder worktrees in game-wt that are merged into origin/main, ended NOWORK, or
# whose pipeline died mid-run. Never touches a live RUNNING run or an unmerged PASS/FAIL/BREACH result (audit S4).
# Usage: bash tools/wt_clean.sh [--apply]
set -uo pipefail
. "$(dirname "$0")/lib.sh"
dir="$(wt_dir)"; main="$(main_root)"; apply=0; [ "${1:-}" = "--apply" ] && apply=1
tip=origin/main; git -C "$main" rev-parse -q --verify "$tip" > /dev/null || tip=main
for wt in "$dir"/*/; do
  [ -e "${wt}.git" ] || continue
  wt="${wt%/}"; name="$(basename "$wt")"; res="$dir/$name.result"
  branch="$(git -C "$wt" rev-parse --abbrev-ref HEAD 2> /dev/null)"
  word="$(head -n 1 "$res" 2> /dev/null | cut -d' ' -f1)"; pid="$(sed -n 's/^pid //p' "$res" 2> /dev/null | head -n 1)"
  reason=""
  if [ "$word" = RUNNING ]; then
    if [ -n "$pid" ] && ! kill -0 "$pid" 2> /dev/null; then reason="dead run"; else continue; fi
  elif [ "$word" = NOWORK ]; then reason="no work"
  elif git -C "$main" merge-base --is-ancestor "$branch" "$tip" 2> /dev/null; then reason="merged"; fi
  [ -n "$reason" ] || { echo "keep   $name (${word:-no result})"; continue; }
  if [ $apply -eq 1 ]; then
    git -C "$main" worktree remove --force "$wt" && git -C "$main" branch -D "$branch" > /dev/null 2>&1
    rm -f "$dir/$name".*; echo "removed $name ($reason)"
  else echo "would remove $name ($reason)"; fi
done
