#!/usr/bin/env bash
# Cache waker for builder runs (row 16, Feras 10-29). A chat waiting on a run is idle and its prompt cache lives 1 hour:
# a wake-up after that re-writes the whole context (~2x C), while one call inside the hour reads it (~0.1x C) and
# restarts the hour. Start this with run_in_background right after the pipeline(s); it sleeps WAIT_SEC (default 3000 =
# 50 min), then prints each run's state and the best move. The chat stops it (TaskStop) in the same message it gates
# the run, so a finished run wakes the chat once. Never blocks anything.
# Usage: bash tools/wait_run.sh <task> [<task>...]   (test: tools/test_wait_run.py)
set -uo pipefail
. "$(dirname "$0")/lib.sh"
dir="$(wt_dir)"; wait_sec="${WAIT_SEC:-3000}"; long_min="${WAIT_LONG_MIN:-180}"
[ $# -gt 0 ] || { echo "usage: bash tools/wait_run.sh <task> [<task>...]"; exit 2; }
sleep "$wait_sec"
left=""
for t in "$@"; do
  res="$dir/$t.result"; first="$(head -n 1 "$res" 2> /dev/null)"
  case "$first" in
    RUNNING*)
      pid="$(sed -n 's/^pid //p' "$res")"
      since="$(stat -c %Y "$dir/$t.prompt.md" 2> /dev/null || date +%s)"; age=$(( ($(date +%s) - since) / 60 ))
      if [ -n "$pid" ] && ! kill -0 "$pid" 2> /dev/null; then
        echo "DEAD $t: pipeline pid $pid is gone but .result says RUNNING: read $dir/$t.log, do not re-arm"
      elif [ "$age" -ge "$long_min" ]; then
        echo "LONG $t: running $age min: /handoff now; a fresh chat gates it (cheaper than more wake-ups)"
      else
        echo "RUNNING $t: $age min"; left="$left $t"
      fi ;;
    "") echo "MISSING $t: no $res" ;;
    *) echo "$t: $first" ;;
  esac
done
if [ -n "$left" ]; then
  echo "Best move: re-arm in the background: bash tools/wait_run.sh$left (one cheap call keeps the cache warm)"
else
  echo "Nothing to wait for: gate what finished (next time TaskStop this waker when the run's own notice arrives)"
fi
