#!/usr/bin/env bash
# Lock a SCOPED test-writing run as the hand's base branch (row 26 S5, Feras 11-02): <new-base> at oc/<task>'s tip, the
# generated docs refreshed there (tools/map.py, tools/doc_graph.py), committed and pushed. Everything happens in a
# temporary worktree: the caller's checkout and branch are never touched.
# Usage (cwd = the checkout): bash tools/lock_tests.sh <task> <new-base-branch>
# Refuses unless <wt_dir>/<task>.result starts with SCOPED (a REJECT run proves nothing).
set -uo pipefail
. "$(dirname "$0")/lib.sh"
name="${1:-}"; newbase="${2:-}"
[ -n "$name" ] && [ -n "$newbase" ] || { echo "usage: lock_tests.sh <task> <new-base-branch>" >&2; exit 2; }
res="$(wt_dir)/$name.result"; src="oc/$name"
first="$(head -1 "$res" 2> /dev/null | tr -d '\r')"
[ "${first%% *}" = SCOPED ] || { echo "needs a SCOPED result: $res says ${first:-nothing}" >&2; exit 1; }
git rev-parse -q --verify "refs/heads/$src" > /dev/null || { echo "no branch $src: the run's worktree is gone" >&2; exit 1; }
git rev-parse -q --verify "refs/heads/$newbase" > /dev/null && { echo "branch $newbase already exists" >&2; exit 1; }
tmp="$(mktemp -d)"; tmpwt="$tmp/wt"
cleanup() { git worktree remove --force "$tmpwt" > /dev/null 2>&1; git branch -D "$newbase" > /dev/null 2>&1; rm -rf "$tmp"; }
git worktree add -q -b "$newbase" "$tmpwt" "$src" || { cleanup; exit 1; }
refresh() {  # <tool> [args]: rewrite one generated doc in the temporary worktree; a broken tool warns, it never loses the tests
  [ -f "$tmpwt/tools/$1" ] || return 0
  (cd "$tmpwt" && $py "tools/$@") < /dev/null > /dev/null 2>&1 || echo "WARN: $1 failed, its doc may be stale" >&2
}
# The generated docs quote the locked tests, and a test names the tool it is red for (tools/<new>.py): that reference is
# expected until the hand builds it, so it is recorded in the doc graph allowlist, or a clean base fails test_doc_graph and
# base_red refuses the hand's launch (row 26 proof P2, 11-02).
refresh map.py; refresh doc_graph.py --baseline; refresh doc_graph.py
if [ -n "$(git -C "$tmpwt" status --porcelain)" ]; then
  git -C "$tmpwt" add -A && git -C "$tmpwt" commit -q -m "locked tests: generated docs refreshed" ||
    { echo "the docs commit failed" >&2; cleanup; exit 1; }
fi
git -C "$tmpwt" push -q origin "$newbase" || { echo "push origin $newbase failed" >&2; cleanup; exit 1; }
sha="$(git -C "$tmpwt" rev-parse HEAD)"
git worktree remove --force "$tmpwt" > /dev/null 2>&1 || echo "WARN: could not remove $tmpwt" >&2
rm -rf "$tmp"
echo "LOCKED $newbase $sha"
