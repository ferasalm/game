#!/usr/bin/env bash
# Merges one gated builder run into the current branch (DECISIONS 2026-10-23): only a PASS .result that also carries a
# `VERDICT PASS` line (row 26 S4, Feras 11-02: the gate's verdict is the merge's proof, not the first word). The run's
# branch is the .result's own (`PASS 19:56 oc/row25` -> oc/row25), so a cf run needs no hand-typed prefix; an explicit
# argument still wins. A fast-forward onto the exact commit the pipeline checked reuses that check, anything else merges
# and runs tools/check.sh. Then removes the run's worktree and branch.
# Usage (cwd = the session checkout): tools/merge_run.sh <task> [oc|gemini] [--keep]
set -euo pipefail
name="${1:-}"; [ -n "$name" ] || { echo "usage: merge_run.sh <task> [oc|gemini] [--keep]" >&2; exit 2; }
shift
prefix=""; keep=""
for a in "$@"; do
  case "$a" in
    --keep) keep=1 ;;
    oc|gemini) prefix="$a" ;;
    *) echo "usage: merge_run.sh <task> [oc|gemini] [--keep]" >&2; exit 2 ;;
  esac
done
. "$(dirname "$0")/lib.sh"; here="$lib_dir"; root="$(git rev-parse --show-toplevel)"
main="$(main_root)"
wt="$(wt_dir)/$name"; res="$wt.result"
[ -f "$res" ] || { echo "no $res" >&2; exit 1; }
first="$(head -1 "$res" | tr -d '\r')"
word="${first%% *}"
[ "$word" = PASS ] || { echo "refusing: $res says $word" >&2; exit 1; }
tr -d '\r' < "$res" | grep -qx 'VERDICT PASS' ||
  { echo "refusing: $res has no VERDICT PASS line" >&2; exit 1; }
if [ -z "$prefix" ]; then  # the .result's 3rd field: `PASS 19:56 oc/row25` -> oc
  run_branch="$(echo "$first" | cut -d' ' -f3)"
  prefix="${run_branch%%/*}"
fi
case "$prefix" in
  oc|gemini) ;;
  *) echo "refusing: $res names no oc/ or gemini/ branch ($first)" >&2; exit 1 ;;
esac
branch="$prefix/$name"
checked="$(sed -n 's/^checked //p' "$res")"
plan="$($py "$here/build_gate.py" can-skip --repo "$root" --checked "$checked" --tip "$branch")"
if [ "$plan" = SKIP ] && ! grep -q '^kind py' "$res"; then
  git -C "$root" merge -q --ff-only "$branch"; echo "fast-forward onto checked $checked: check reused"
else
  git -C "$root" merge -q --no-edit "$branch"
  (cd "$root" && bash tools/check.sh) || { echo "merged, but check.sh FAILED: fix before pushing" >&2; exit 1; }
fi
if [ -z "$keep" ]; then
  git -C "$main" worktree remove --force "$wt" && git -C "$main" branch -D "$branch" > /dev/null
  echo "removed $wt and $branch"
fi
