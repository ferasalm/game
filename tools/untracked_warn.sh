#!/usr/bin/env bash
# Warn (never fail) when untracked, non-ignored files exist: map.py and doc_graph.py read only tracked files, so a new
# file that is not `git add`ed passes the local MAP/DOCMAP gate and fails CI "docs/MAP.md current" (row 28, 11-04).
# Usage: untracked_warn.sh [repo dir]; prints nothing when clean; exit 0 always.
cd "${1:-.}" || exit 0
new=$(git ls-files --others --exclude-standard 2> /dev/null | grep -v '^\.check/' | head -n 10)
[ -z "$new" ] && exit 0
echo "WARN untracked files (git add -A, then python tools/map.py and tools/doc_graph.py, or CI fails MAP.md current):"
echo "$new" | sed 's/^/     /'
exit 0
