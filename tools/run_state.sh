#!/usr/bin/env bash
# Run state for build_pipeline.sh (row 26, Feras 11-02): the .result header every reader parses by name, the tokens of an
# opencode run read from its own session export, the worktree between two steps, and no empty worktree left behind by a
# NOWORK or REFUSED run. Sourced after lib.sh and the run's variables; nothing here runs on its own (like lib.sh).
status_line() {  # <word> <step>
  { echo "$1 $(date +%H:%M) $2"; echo "builder $builder"; echo "pid $$"; echo "kind $RUN_KIND"; } > "$res"
}

commits() { [ -n "$(git -C "$wt" log --oneline "$base..HEAD" 2> /dev/null)" ]; }

import_wt() {  # a fresh worktree has no class cache; Godot's import then rewrites tracked assets/*.import: put those back
  if [ -n "${IMPORT_CMD:-}" ]; then (cd "$wt" && eval "$IMPORT_CMD") < /dev/null >> "$wt.import.txt" 2>&1
  elif [ -f "$wt/tools/run_godot.sh" ]; then (cd "$wt" && bash tools/run_godot.sh --import) < /dev/null >> "$wt.import.txt" 2>&1; fi
  git -C "$wt" ls-files -m -- 'assets/*.import' | xargs -r git -C "$wt" checkout -- 2> /dev/null
}

refresh_map() {  # map.py lists tracked files, so after leftovers; a new file's stale MAP cost a fix pass (row 18c)
  [ -f "$wt/tools/map.py" ] || return 0
  (cd "$wt" && $py tools/map.py) < /dev/null > /dev/null 2>&1
  [ -z "$(git -C "$wt" status --porcelain -- docs/MAP.md)" ] ||
    git -C "$wt" commit -q -m "docs/MAP.md refreshed (build_pipeline)" -- docs/MAP.md
}

leftovers() {  # builders die mid-edit: keep their work as a WIP commit (only .uid files after import_wt's restore)
  if [ -n "$(git -C "$wt" status --porcelain 2> /dev/null)" ]; then
    git -C "$wt" add -A && git -C "$wt" commit -q -m "WIP: $1 leftovers (build_pipeline)"
  fi
}

result_head() {  # <word> <step>: slots.sh reads builder, pid and kind by name; model and idle_min are added after them
  echo "$1 $(date +%H:%M) $2"
  echo "builder $builder"
  echo "pid $$"
  echo "kind $RUN_KIND"
  echo "model $model_used"
  echo "idle_min $idle_min"
}

row_tokens() {  # <gate>: "in out usd source"; a cf or oc run's own sessions are the only real reading, else ? (never 0)
  if [ "$1" != REFUSED ] && { [ "$builder" = cf ] || [ "$builder" = oc ]; }; then
    local f in_t out_t usd
    f="$($py tools/oc_usage.py collect --wt "$wt" 2> /dev/null |
      $py tools/oc_usage.py fields --in-rate "$CF_INPUT_RATE" --out-rate "$CF_OUTPUT_RATE" 2> /dev/null)"
    case "$f" in [0-9]*,[0-9]*,[0-9]*)
      IFS=, read -r in_t out_t usd <<< "$f"; echo "$in_t $out_t $usd opencode-export"; return 0 ;; esac
  fi
  echo "? ? ? unknown"
}

clean_empty_wt() {  # a NOWORK or REFUSED run leaves no worktree or branch: a rerun on a new base starts clean
  [ -d "$wt" ] || return 0
  [ -z "$(git -C "$wt" status --porcelain 2> /dev/null)" ] || return 0
  local head; head="$(git -C "$wt" rev-parse HEAD 2> /dev/null)" || return 0
  git -C "$wt" merge-base --is-ancestor "$head" "$base" 2> /dev/null || return 0  # its commits are all in base
  git -C "$root" worktree remove --force "$wt" > /dev/null 2>&1
  git -C "$root" branch -D "$prefix/$name" > /dev/null 2>&1
}

nowork_exit() {  # <reason>: nothing to check; the empty worktree goes, the row is logged, exit 1
  { result_head NOWORK "$prefix/$name"; echo "why: $1"; } > "$res"
  cat "$res"
  clean_empty_wt
  log_row NOWORK "$(( ($(date +%s) - pipeline_start) / 60 ))" "${fix:-0}"
  exit 1
}
