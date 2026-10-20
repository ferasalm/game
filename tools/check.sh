#!/usr/bin/env bash
# One command for every check (docs, lint, Godot import, tests). One ok/FAIL line per step; logs in .check/.
# Read the FAIL lines (and the log tail printed under them); a check counts only when its output was read.
set -uo pipefail
cd "$(dirname "$0")/.."
mkdir -p .check
fails=0
step() {
  local name="$1"; shift
  if "$@" > ".check/$name.log" 2>&1; then echo "ok   $name"
  else echo "FAIL $name (.check/$name.log)"; grep -vE '^\s*$|\[ *[0-9]+% \]|DONE' ".check/$name.log" | tail -n 12 | sed 's/^/     /'; fails=$((fails + 1)); fi
}
py=python3; command -v python3 > /dev/null 2>&1 && python3 -c "" 2> /dev/null || py=python
step docs $py tools/doc_check.py
step lint $py tools/lint_gd.py
step import tools/run_godot.sh --import
step tests tools/run_godot.sh -s res://tests/runner.gd
grep -h '^tests:' .check/tests.log 2>/dev/null | sed 's/^/     /'
if [ $fails -eq 0 ]; then echo "all checks passed"; else echo "$fails check(s) FAILED"; exit 1; fi
