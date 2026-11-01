#!/usr/bin/env bash
# One command for every check (docs, lint, Godot import, tests). One ok/FAIL line per step; logs in .check/.
# Read the FAIL lines (and the log tail printed under them); a check counts only when its output was read.
set -uo pipefail
cd "$(dirname "$0")/.."
mkdir -p .check
fails=0
step() {
  local name="$1" t0=$SECONDS; shift
  if "$@" > ".check/$name.log" 2>&1; then echo "ok   $name ($((SECONDS - t0)) s)"
  else echo "FAIL $name ($((SECONDS - t0)) s) (.check/$name.log)"; grep -vE '^\s*$|\[ *[0-9]+% \]|DONE' ".check/$name.log" | tail -n 12 | sed 's/^/     /'; fails=$((fails + 1)); fi
}
. tools/lib.sh  # $py
tool_tests() {  # run $py tools/tool_tests.py, then $py tools/oc_agents.py --check; both always run, and it returns non-zero when either fails
  local rc=0
  $py tools/tool_tests.py || rc=1
  $py tools/oc_agents.py --check || rc=1
  return $rc
}
docs() {  # doc_check.py, then the doc graph: a stale docs/DOCMAP.md or a new dangling reference fails this step
  $py tools/doc_check.py || return 1
  $py tools/doc_graph.py --check
}
no_godot=0; [ "${1:-}" = "--no-godot" ] && no_godot=1
step docs docs
step lint $py tools/lint_gd.py
step res_graph $py tools/res_graph.py --check  # no file under features/ core/ content/ assets/ that nothing uses
[ $no_godot -eq 0 ] && step import tools/run_godot.sh --import
step tool_tests tool_tests
grep -h '^cached:' .check/tool_tests.log 2>/dev/null | sed 's/^/     /'  # a skipped test is said out loud
git status --porcelain --untracked-files=all > .check/before_tests.txt  # tests and boot must leave the repo as found
if [ $no_godot -eq 0 ]; then
  . tools/check_slot.sh; acquire_check_slot || { echo "FAIL no test slot (see .check)"; exit 1; }; trap release_check_slot EXIT
  step tests env GODOT_TIMEOUT=600 tools/run_godot.sh -s res://tests/runner.gd
  step boot env GODOT_TIMEOUT=180 tools/run_godot.sh --quit-after 120  # the main scene starts without errors
  release_check_slot
fi
repo_untouched() {  # a file a test or the boot wrote into the checkout (a relative save folder was committed once)
  local new  # captured first: grep -q under pipefail could stop git early (SIGPIPE) and pass by mistake
  new=$(git status --porcelain --untracked-files=all | grep -vxF -f .check/before_tests.txt)
  [ -z "$new" ] || { echo "$new"; return 1; }
}
step repo_untouched repo_untouched
if [ $no_godot -eq 1 ]; then
  echo "     no Godot: import, tests and boot skipped (--no-godot)"
else
  grep -h '^tests:' .check/tests.log 2>/dev/null | sed 's/^/     /'
fi
if [ $fails -eq 0 ]; then echo "all checks passed"; else echo "$fails check(s) FAILED"; exit 1; fi
