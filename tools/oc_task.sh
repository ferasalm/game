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
command -v "$OC_BIN" >/dev/null || { echo "opencode is not installed: $OC_BIN (tools/builders.conf)" >&2; exit 1; }
dir="$(wt_dir)"; wt="$dir/$name"; branch="oc/$name"; log="$dir/$name.log"
ensure_wt "$root" "$wt" "$branch" "$base"
wt="$(cd "$wt" && pwd)"
[ "$wt" != "$root" ] || { echo "refusing to run in the main checkout" >&2; exit 1; }
[ "$(git -C "$wt" rev-parse --abbrev-ref HEAD)" = "$branch" ] || { echo "worktree is not on $branch" >&2; exit 1; }
cd "$wt"
: > "$log"
# The prompt travels as an attached file: a brief + skill + Pattern file passed as argv hit Windows' ~32 KB command cap
# ("Argument list too long", exit 126, row 26 11-02; smoke: a 60 KB file works).
# Two opencode v2 servers started in the same second share one SQLite database and the second dies at startup ("database
# is locked", row 26 11-02): a STARTUP failure (matches OC_START_FAIL_RE, nothing committed yet) is retried after a short
# random wait, up to OC_START_TRIES; a real failure never is.
attempt=1
while :; do
  rc=0
  run_limited "${OC_TIMEOUT:-90m}" oc_run --model "$model" -f "$brief" -- \
    "Your whole task is in the attached file. Follow it exactly: it is the brief, the rules and the pipeline rules." \
    < /dev/null >> "$log" 2>&1 || rc=$?
  [ $rc -ne 0 ] || break
  [ "$attempt" -lt "$OC_START_TRIES" ] || break
  grep -aqE "$OC_START_FAIL_RE" "$log" || break
  [ -z "$(git log --oneline "$base..HEAD" 2> /dev/null)" ] || break
  echo "startup collision (attempt $attempt of $OC_START_TRIES): retrying" >> "$log"
  sleep "${OC_START_WAIT:-$(( RANDOM % 5 + 2 ))}"
  attempt=$((attempt + 1))
done
[ $rc -eq 0 ] || echo "opencode exited $rc" >> "$log"
echo "done: $wt ($branch); log: $log"
