#!/usr/bin/env bash
# The mechanical half of /handoff in one call (row 23 b, 2026-11-01): map, doc_check, check, commit, push and (with
# --main) CI. Usage (cwd = anywhere in the repo): bash tools/handoff.sh "<commit message>" [--main]
# Each step prints "== <step>"; the first non-zero one stops the run. Last line HANDOFF PASS (exit 0) or
# HANDOFF FAIL <step> (map, doc_check, check, commit, push, ci; exit 1). No message: Usage, exit 2.
set -uo pipefail

msg="${1:-}"
if [ -z "$msg" ] || [ "$msg" = --main ]; then
  echo "Usage: bash tools/handoff.sh \"<commit message>\" [--main]"
  exit 2
fi
shift
to_main=0
for a in "$@"; do
  case "$a" in
    --main) to_main=1 ;;
    *) echo "Usage: bash tools/handoff.sh \"<commit message>\" [--main]"; exit 2 ;;
  esac
done

root="$(git rev-parse --show-toplevel 2> /dev/null)" || { echo "not inside a git repository"; exit 2; }
cd "$root" || exit 2
# CI_WAIT_SEC is data in tools/builders.conf (row 26 S4: CI may take 15 min); the copy below only serves a repo that
# has no builders.conf (a toy checkout), so the wait still has a cap there.
[ -f tools/builders.conf ] && . tools/builders.conf
ci_wait="${CI_WAIT_SEC:-960}"

fail() { echo "HANDOFF FAIL $1"; exit 1; }

echo "== map"
git add -A || fail map  # map.py lists `git ls-files --cached`: a new file must be staged first or CI finds MAP.md stale (11-02)
python tools/map.py || fail map
# docs/DOCMAP.md is a check.sh gate too: any doc edit of the handoff (USAGE, LESSONS, HANDOFF) made it stale and failed the
# first run of the 11-03 handoff (a stub repo without the tool skips this)
[ ! -f tools/doc_graph.py ] || python tools/doc_graph.py > /dev/null || fail map
git add -A || fail map  # and the regenerated maps join the commit

echo "== doc_check"
python tools/doc_check.py || fail doc_check

echo "== check"
check_out="$(bash tools/check.sh 2>&1)"
check_rc=$?
tail -n 15 <<< "$check_out"
if [ "$check_rc" -ne 0 ]; then
  grep FAIL <<< "$check_out"  # every FAIL line, not only the ones in the tail
  fail check
fi

echo "== commit"
git add -A || fail commit
if git diff --cached --quiet; then
  echo "nothing to commit"
else
  git commit -m "$msg" || fail commit
fi

echo "== push"
# A branch that tracks origin/<other> (a worktree branch following system-v3) pushes there, not to a new same-named branch.
up="$(git rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2> /dev/null || true)"
if [ "$to_main" != 1 ] && { [ "$up" = origin/main ] || [ "$(git rev-parse --abbrev-ref HEAD)" = main ]; }; then
  fail push  # only --main touches main (skill, step 0); the commit is kept
fi
if [ "${up#origin/}" != "$up" ] && [ "$up" != origin/HEAD ]; then
  git push origin "HEAD:${up#origin/}" || fail push
else
  git push -u origin HEAD || fail push  # a detached HEAD fails here, after the commit is kept
fi
if [ "$to_main" = 1 ]; then
  git push origin HEAD:main || fail push
fi

if [ "$to_main" = 1 ]; then
  echo "== ci"
  # The check workflow for this exact commit (row 26 S4, Feras 11-02): `gh run list --limit 1` read any workflow, and
  # "the first run" is the Android export's (D17) as soon as a second one exists. ci_state.py waits for every run of
  # check.yml on the commit and speaks one word.
  sha="$(git rev-parse HEAD)"
  ci_cmd="${HANDOFF_CI:-gh run list --workflow check.yml --commit $sha --json status,conclusion | python tools/ci_state.py}"
  waited=0
  while :; do
    ci_out="$(bash -c "$ci_cmd" 2>&1)" || ci_out="error"
    ci_word="$(tr -d '[:space:]' <<< "$ci_out")"
    [ "$ci_word" = success ] && break
    case "$ci_word" in
      ""|null|in_progress|queued|requested|waiting|pending)  # a run still on its way: poll, and say so
        echo "ci: ${ci_word:-no run yet}; waiting 20 s" ;;
      *) fail ci ;;
    esac
    [ "$waited" -ge "$ci_wait" ] && fail ci
    sleep 20
    waited=$((waited + 20))
  done
fi

echo "HANDOFF PASS"
