#!/usr/bin/env bash
# Runs Gemini (agy) on one task brief inside its own git worktree, never in the main checkout (DECISIONS 2026-10-22).
# Usage: tools/agy_task.sh <task-name> <brief-file> [base-branch] [model]
# The worktree is ../game-wt/<task-name> on branch gemini/<task-name>; the log is ../game-wt/<task-name>.log.
set -euo pipefail
name="$1"; brief="$(cd "$(dirname "$2")" && pwd)/$(basename "$2")"
root="$(git rev-parse --show-toplevel)"
base="${3:-$(git -C "$root" rev-parse --abbrev-ref HEAD)}"; model="${4:-gemini-3.8-flash-high}"
[[ "$name" =~ ^[a-z0-9-]+$ ]] || { echo "task name: lowercase letters, digits and - only" >&2; exit 1; }
[ "$base" != "HEAD" ] || { echo "base branch needed" >&2; exit 1; }
wt="$(dirname "$root")/game-wt/$name"; branch="gemini/$name"; log="$(dirname "$root")/game-wt/$name.log"
mkdir -p "$(dirname "$wt")"
[ -d "$wt" ] || git -C "$root" worktree add -q -b "$branch" "$wt" "$base"
wt="$(cd "$wt" && pwd)"
[ "$wt" != "$root" ] || { echo "refusing to run in the main checkout" >&2; exit 1; }
[ "$(git -C "$wt" rev-parse --abbrev-ref HEAD)" = "$branch" ] || { echo "worktree is not on $branch" >&2; exit 1; }
cd "$wt"
agy -p "$(cat "$brief")" --model "$model" --dangerously-skip-permissions \
  --print-timeout "${AGY_TIMEOUT:-90m}" > "$log" 2>&1 || echo "agy exited $?" >> "$log"
echo "done: $wt ($branch); log: $log"
