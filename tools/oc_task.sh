#!/usr/bin/env bash
# Runs opencode on one task brief inside its own git worktree, never in the main checkout (DECISIONS 2026-10-23).
# Usage: tools/oc_task.sh <task-name> <brief-file> [base-branch] [model]
# Models (free, docs/research/opencode-setup.md): opencode/glm-5.3-flash-free (default), opencode/deepseek-v4.1-flash-free.
# The worktree is ../game-wt/<task-name> on branch oc/<task-name>; the log is ../game-wt/<task-name>.log.
# Rules come from AGENTS.md + opencode.json (GEMINI.md); edit and bash are allowed there. OC_TIMEOUT caps the run.
# Own data folder (XDG_DATA_HOME): the owner's opencode desktop app keeps a database the CLI can't share.
set -euo pipefail
name="$1"; brief="$(cd "$(dirname "$2")" && pwd)/$(basename "$2")"
root="$(git rev-parse --show-toplevel)"
base="${3:-$(git -C "$root" rev-parse --abbrev-ref HEAD)}"; model="${4:-opencode/glm-5.3-flash-free}"
[[ "$name" =~ ^[a-z0-9-]+$ ]] || { echo "task name: lowercase letters, digits and - only" >&2; exit 1; }
[ "$base" != "HEAD" ] || { echo "base branch needed" >&2; exit 1; }
command -v opencode >/dev/null || { echo "opencode is not installed (docs/research/opencode-setup.md 7)" >&2; exit 1; }
wt="$(dirname "$root")/game-wt/$name"; branch="oc/$name"; log="$(dirname "$root")/game-wt/$name.log"
mkdir -p "$(dirname "$wt")"
[ -d "$wt" ] || git -C "$root" worktree add -q -b "$branch" "$wt" "$base"
wt="$(cd "$wt" && pwd)"
[ "$wt" != "$root" ] || { echo "refusing to run in the main checkout" >&2; exit 1; }
[ "$(git -C "$wt" rev-parse --abbrev-ref HEAD)" = "$branch" ] || { echo "worktree is not on $branch" >&2; exit 1; }
cd "$wt"
XDG_DATA_HOME="$HOME/.local/share/oc-cli" timeout "${OC_TIMEOUT:-90m}" opencode run --model "$model" "$(cat "$brief")" > "$log" 2>&1   || echo "opencode exited $?" >> "$log"
echo "done: $wt ($branch); log: $log"
