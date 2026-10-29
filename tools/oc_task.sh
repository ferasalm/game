#!/usr/bin/env bash
# Runs opencode on one task brief inside its own git worktree, never in the main checkout (DECISIONS 2026-10-23).
# Usage: tools/oc_task.sh <task-name> <brief-file> [base-branch] [model]
# Default model: OC_MODEL in tools/builders.conf (free DeepSeek, D1). The worktree is <main checkout's parent>/game-wt/<task>
# on branch oc/<task>; the log is game-wt/<task>.log. Rules come from AGENTS.md + opencode.json. OC_TIMEOUT caps the run
# (outside timeout, process tree killed). Own data folder (XDG_DATA_HOME): the owner's desktop app keeps a database.
set -euo pipefail
. "$(dirname "$0")/lib.sh"
name="$1"; brief="$(cd "$(dirname "$2")" && pwd)/$(basename "$2")"
root="$(git rev-parse --show-toplevel)"
base="${3:-$(git -C "$root" rev-parse --abbrev-ref HEAD)}"; model="${4:-$OC_MODEL}"
[[ "$name" =~ ^[a-z0-9-]+$ ]] || { echo "task name: lowercase letters, digits and - only" >&2; exit 1; }
[ "$base" != "HEAD" ] || { echo "base branch needed" >&2; exit 1; }
command -v opencode >/dev/null || { echo "opencode is not installed (docs/research/opencode-setup.md 7)" >&2; exit 1; }
dir="$(wt_dir)"; wt="$dir/$name"; branch="oc/$name"; log="$dir/$name.log"
ensure_wt "$root" "$wt" "$branch" "$base"
wt="$(cd "$wt" && pwd)"
[ "$wt" != "$root" ] || { echo "refusing to run in the main checkout" >&2; exit 1; }
[ "$(git -C "$wt" rev-parse --abbrev-ref HEAD)" = "$branch" ] || { echo "worktree is not on $branch" >&2; exit 1; }
cd "$wt"
rc=0
# --print-logs: API errors (a spent free quota) reach the log; without it opencode prints nothing and exits 0 (10-29)
XDG_DATA_HOME="$HOME/.local/share/oc-cli" run_limited "${OC_TIMEOUT:-90m}" opencode run --print-logs --log-level ERROR \
  --model "$model" "$(cat "$brief")" \
  < /dev/null > "$log" 2>&1 || rc=$?
[ $rc -eq 0 ] || echo "opencode exited $rc" >> "$log"
echo "done: $wt ($branch); log: $log"
