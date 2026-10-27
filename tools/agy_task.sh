#!/usr/bin/env bash
# Runs Gemini (agy) on one task brief inside its own git worktree, never in the main checkout (DECISIONS 2026-10-22).
# Usage: tools/agy_task.sh <task-name> <brief-file> [base-branch] [model]
# The worktree is <main checkout's parent>/game-wt/<task> on branch gemini/<task>; the log is game-wt/<task>.log.
# AGY_TIMEOUT is also enforced from outside (process tree killed): agy's own --print-timeout alone let runs hang.
set -euo pipefail
. "$(dirname "$0")/lib.sh"
name="$1"; brief="$(cd "$(dirname "$2")" && pwd)/$(basename "$2")"
root="$(git rev-parse --show-toplevel)"
base="${3:-$(git -C "$root" rev-parse --abbrev-ref HEAD)}"; model="${4:-$AGY_MODEL}"
[[ "$name" =~ ^[a-z0-9-]+$ ]] || { echo "task name: lowercase letters, digits and - only" >&2; exit 1; }
[ "$base" != "HEAD" ] || { echo "base branch needed" >&2; exit 1; }
dir="$(wt_dir)"; wt="$dir/$name"; branch="gemini/$name"; log="$dir/$name.log"
ensure_wt "$root" "$wt" "$branch" "$base"
wt="$(cd "$wt" && pwd)"
[ "$wt" != "$root" ] || { echo "refusing to run in the main checkout" >&2; exit 1; }
[ "$(git -C "$wt" rev-parse --abbrev-ref HEAD)" = "$branch" ] || { echo "worktree is not on $branch" >&2; exit 1; }
cd "$wt"
rc=0
run_limited "${AGY_TIMEOUT:-90m}" agy -p "$(cat "$brief")" --model "$model" --dangerously-skip-permissions \
  --print-timeout "${AGY_TIMEOUT:-90m}" < /dev/null > "$log" 2>&1 || rc=$?
[ $rc -eq 0 ] || echo "agy exited $rc" >> "$log"
echo "done: $wt ($branch); log: $log"
