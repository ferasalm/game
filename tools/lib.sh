#!/usr/bin/env bash
# Shared shell helpers for the builder tools (slots, pipeline, task runners, merge, check): paths, python, limits.
# Source it: . "$(dirname "$0")/lib.sh". Everything here is a function or a variable; it runs nothing.
lib_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$lib_dir/builders.conf"

py=python; $py -c "" > /dev/null 2>&1 || py=python3

main_root() {  # the main checkout, also from inside a worktree (a worktree's toplevel is NOT the main checkout)
  local c; c="$(git rev-parse --path-format=absolute --git-common-dir 2> /dev/null)" || { dirname "$lib_dir"; return; }
  dirname "$c"
}

wt_dir() {  # where builder worktrees, .result and .log files live: <main checkout's parent>/game-wt
  if [ -n "${GAME_WT_DIR:-}" ]; then echo "$GAME_WT_DIR"; else echo "$(dirname "$(main_root)")/game-wt"; fi
}

builder_prefix() { [ "$1" = agy ] && echo gemini || echo oc; }

free_mb() {  # free virtual memory in MB (Win32_OperatingSystem, KB); FREE_MB stubs it; unknown = plenty
  if [ -n "${FREE_MB:-}" ]; then echo "$FREE_MB"; return; fi
  local kb; kb="$(powershell -NoProfile -Command '(Get-CimInstance Win32_OperatingSystem).FreeVirtualMemory' 2> /dev/null | tr -d '\r')"
  case "$kb" in ''|*[!0-9]*) echo 999999 ;; *) echo $((kb / 1024)) ;; esac
}

win_pid() { cat "/proc/$1/winpid" 2> /dev/null || echo "$1"; }  # msys pid -> Windows pid (taskkill needs it)

kill_tree() {  # kill a process and its children; native Windows children survive a plain kill
  local pid="$1"
  if command -v taskkill > /dev/null 2>&1; then taskkill //T //F //PID "$(win_pid "$pid")" > /dev/null 2>&1; fi
  kill -9 "$pid" 2> /dev/null; return 0
}

ensure_wt() {  # <root> <wt> <branch> <base>: create the worktree, or refuse to reuse one made from another base
  local root="$1" wt="$2" branch="$3" base="$4"
  mkdir -p "$(dirname "$wt")"
  if [ -d "$wt" ]; then
    git -C "$wt" merge-base --is-ancestor "$(git -C "$root" rev-parse "$base")" HEAD 2> /dev/null ||
      { echo "worktree $wt was made from another base than $base: remove it or pick a new task name" >&2; return 1; }
  else
    git -C "$root" worktree add -q -b "$branch" "$wt" "$base" || return 1
  fi
}

dur_secs() {  # 90m / 45m / 30s / 2h / plain seconds -> seconds
  case "$1" in *h) echo $((${1%h} * 3600)) ;; *m) echo $((${1%m} * 60)) ;; *s) echo "${1%s}" ;; *) echo "$1" ;; esac
}

run_limited() {  # <duration> cmd...: run it, kill its whole process tree when the time is up; returns 124 then
  local secs; secs="$(dur_secs "$1")"; shift
  "$@" & local pid=$! t=0
  while kill -0 "$pid" 2> /dev/null; do
    sleep 1; t=$((t + 1))
    if [ "$t" -ge "$secs" ]; then kill_tree "$pid"; wait "$pid" 2> /dev/null; return 124; fi
  done
  wait "$pid"
}
