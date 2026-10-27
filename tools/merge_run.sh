#!/usr/bin/env bash
# Merges one gated builder run into the current branch (DECISIONS 2026-10-23): only a PASS .result; a fast-forward onto
# the exact commit the pipeline checked reuses that check, anything else merges and runs tools/check.sh. Then removes
# the run's worktree and branch. Usage (cwd = the session checkout): tools/merge_run.sh <task> [oc|gemini] [--keep]
set -euo pipefail
name="$1"; prefix="${2:-gemini}"; keep="${3:-}"
. "$(dirname "$0")/lib.sh"; here="$lib_dir"; root="$(git rev-parse --show-toplevel)"
main="$(main_root)"
wt="$(wt_dir)/$name"; res="$wt.result"; branch="$prefix/$name"
[ -f "$res" ] || { echo "no $res" >&2; exit 1; }
word="$(head -1 "$res" | cut -d' ' -f1)"
[ "$word" = PASS ] || { echo "refusing: $res says $word" >&2; exit 1; }
checked="$(sed -n 's/^checked //p' "$res")"
plan="$($py "$here/build_gate.py" can-skip --repo "$root" --checked "$checked" --tip "$branch")"
if [ "$plan" = SKIP ]; then
  git -C "$root" merge -q --ff-only "$branch"; echo "fast-forward onto checked $checked: check reused"
else
  git -C "$root" merge -q --no-edit "$branch"
  (cd "$root" && bash tools/check.sh) || { echo "merged, but check.sh FAILED: fix before pushing" >&2; exit 1; }
fi
if [ -z "$keep" ]; then
  git -C "$main" worktree remove --force "$wt" && git -C "$main" branch -D "$branch" > /dev/null
  echo "removed $wt and $branch"
fi
