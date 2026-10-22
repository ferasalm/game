#!/usr/bin/env bash
# Shows what an agy task did, cheaply: its completion report, the check result, commits, file stats and the diff of
# the non-test code only (tests, MAP.md, .uid and localization are listed in the stats, not printed).
# Usage: tools/agy_review.sh <task-name> [base-ref]   (base defaults to the merge base with the current branch)
set -euo pipefail
name="$1"; root="$(git rev-parse --show-toplevel)"
wt="$(dirname "$root")/game-wt/$name"; log="$(dirname "$root")/game-wt/$name.log"; branch="gemini/$name"
base="${2:-$(git -C "$root" merge-base HEAD "$branch")}"
echo "== report"; grep -E "COMPLETION REPORT|Unresolved|Assumptions|tests: |all checks|FAIL" "$log" | tail -8 || true
echo "== commits"; git -C "$root" log --oneline "$base..$branch"
echo "== files"; git -C "$root" diff --stat "$base..$branch" | tail -40
echo "== code diff (no tests, MAP, uid, csv)"
git -C "$root" diff "$base..$branch" -- . ':(exclude)*/tests/*' ':(exclude)tests/*' ':(exclude)docs/MAP.md' \
  ':(exclude)*.uid' ':(exclude)localization/*' | grep -E '^[+-]' | grep -vE '^(\+\+\+|---)'
echo "== new player text"; git -C "$root" diff "$base..$branch" -- localization/ | grep -E '^\+[A-Z]' || true
echo "(worktree: $wt)"
