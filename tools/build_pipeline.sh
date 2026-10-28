#!/usr/bin/env bash
# Free builder pipeline (DECISIONS 2026-10-23, hardened 2026-10-27): slots check -> builder run (idle watchdog) ->
# check.sh -> one free fix pass fed the FAIL lines -> check.sh -> tools/build_gate.py -> game-wt/<task>.result
# (first word PASS/FAIL/NOWORK/BREACH, the gate's checklist, the checked commit, the pipeline's pid). Exit 0 only for PASS.
# Claude reads only a PASS; tools/merge_run.sh merges it.
# Usage (cwd = a checkout whose origin has <base> pushed): bash tools/build_pipeline.sh <oc|agy|cf> <task> <brief> <base> [model]
# Refuses (exit 3, no .result) when slots/memory say no, or when <base> has commits origin lacks. Run it with
# run_in_background. Env: SKIP_BUILD=1 (build already ran), BUILDER_CMD (stub builder, tests), IMPORT_CMD, IDLE_SEC,
# NEWTEST_KINDS (py,gd: new tests are run against the base by the gate).
set -uo pipefail
. "$(dirname "$0")/lib.sh"
builder="$1"; name="$2"; brief="$(cd "$(dirname "$3")" && pwd)/$(basename "$3")"; base="$4"; model="${5:-}"
RUN_KIND="${RUN_KIND:-godot}"
case "$RUN_KIND" in godot|py) ;; *) refuse "RUN_KIND must be godot or py" ;; esac
here="$lib_dir"; root="$(git rev-parse --show-toplevel)"; dir="$(wt_dir)"; wt="$dir/$name"; res="$wt.result"
prefix="$(builder_prefix "$builder")"
idle_sec="${IDLE_SEC:-$((IDLE_MIN * 60))}"; poll="${WATCH_POLL:-20}"

refuse() { echo "REFUSED: $*" >&2; echo "REFUSED: $*"; exit 3; }
bash "$here/slots.sh" can-start "$builder" "$RUN_KIND" < /dev/null > "$dir.slots.tmp" 2>&1 || refuse "$(grep REFUSED "$dir.slots.tmp" | head -1)"
rm -f "$dir.slots.tmp"
# A stale or unpushed base made builders fork old code: pin <base> to origin's commit, refuse when local is ahead.
git fetch -q origin < /dev/null 2> /dev/null
case "$base" in
  origin/*) git rev-parse -q --verify "$base" > /dev/null || refuse "$base unknown" ;;
  *) git rev-parse -q --verify "origin/$base" > /dev/null || refuse "base $base is not on origin (unpushed): push it first"
     if git rev-parse -q --verify "refs/heads/$base" > /dev/null && ! git merge-base --is-ancestor "$base" "origin/$base"; then
       refuse "local $base has unpushed commits: push it first"; fi
     base="origin/$base" ;;
esac
base="$(git rev-parse "$base")"
mkdir -p "$dir"

status_line() {  # <word> <step>
  { echo "$1 $(date +%H:%M) $2"; echo "builder $builder"; echo "pid $$"; echo "kind $RUN_KIND"; } > "$res"
}

run() {  # <brief file>; watched: no commit in the worktree for idle_sec -> kill the tree. Returns 99 when killed idle.
  local started=$(date +%s) last pid mark
  mark=$started
  if [ -n "${BUILDER_CMD:-}" ]; then bash "$BUILDER_CMD" "$name" "$1" "$base" ${model:+"$model"} < /dev/null > "$wt.log" 2>&1 &
  elif [ "$builder" = agy ]; then bash "$here/agy_task.sh" "$name" "$1" "$base" ${model:+"$model"} < /dev/null &
  else bash "$here/oc_task.sh" "$name" "$1" "$base" ${model:+"$model"} < /dev/null & fi
  pid=$!
  while kill -0 "$pid" 2> /dev/null; do
    sleep "$poll"
    last="$(git -C "$wt" log -1 --format=%ct 2> /dev/null || echo 0)"; [ "${last:-0}" -gt "$mark" ] && mark="$last"
    if [ $(( $(date +%s) - mark )) -ge "$idle_sec" ]; then kill_tree "$pid"; wait "$pid" 2> /dev/null; return 99; fi
  done
  wait "$pid"; return 0
}
idle_note=""
idle_exit() {  # <step>: killed idle. Committed work still goes to check and gate (builders hang after a last commit)
  leftovers "$1"
  if [ -n "$(git -C "$wt" log --oneline "$base..HEAD" 2> /dev/null)" ]; then
    idle_note="idle: $1 killed after ${idle_sec}s without a commit; its commits were checked"; return 0
  fi
  { echo "NOWORK $(date +%H:%M) $prefix/$name"; echo "builder $builder"; echo "pid $$"; echo "kind $RUN_KIND"
    echo "idle: no commit for ${idle_sec}s, builder killed (the brief needs a first-commit deadline)"; } > "$res"
  cat "$res"; exit 1
}
import_wt() {  # a fresh worktree has no class cache; Godot's import then rewrites tracked assets/*.import: put those back
  if [ -n "${IMPORT_CMD:-}" ]; then (cd "$wt" && eval "$IMPORT_CMD") < /dev/null >> "$wt.import.txt" 2>&1
  elif [ -f "$wt/tools/run_godot.sh" ]; then (cd "$wt" && bash tools/run_godot.sh --import) < /dev/null >> "$wt.import.txt" 2>&1; fi
  git -C "$wt" ls-files -m -- 'assets/*.import' | xargs -r git -C "$wt" checkout -- 2> /dev/null
}
check() {  # -> 0 when all checks pass; output in <task>.check.txt
  if [ "$RUN_KIND" = py ]; then
    (cd "$wt" && bash tools/check.sh --no-godot < /dev/null > "$wt.check.txt" 2>&1)
  else
    import_wt; (cd "$wt" && bash tools/check.sh < /dev/null > "$wt.check.txt" 2>&1)
  fi
}
leftovers() {  # builders die mid-edit: keep their work as a WIP commit (only .uid files after import_wt's restore)
  if [ -n "$(git -C "$wt" status --porcelain 2> /dev/null)" ]; then
    git -C "$wt" add -A && git -C "$wt" commit -q -m "WIP: $1 leftovers (build_pipeline)"
  fi
}

status_line RUNNING build
# The skill the brief names goes into the prompt itself (builders skipped optional skills), then the code rules.
prompt="$dir/$name.prompt.md"; cp "$brief" "$prompt"
skills="$(grep -o -E '[a-z][a-z-]+ skill' "$brief" | sed 's/ skill$//' | awk '!seen[$0]++' |
  while read -r s; do [ -f "$here/../.agents/skills/$s/SKILL.md" ] && echo "$s"; done | head -2)"
# A skill the brief loads ("Load the X skill") that does not exist is not pasted: say so (P2b review).
for s in $(grep -o -E 'Load the [a-z][a-z-]+ skill' "$brief" | awk '{print $3}' | awk '!seen[$0]++'); do
  [ -f "$here/../.agents/skills/$s/SKILL.md" ] || echo "WARN: the brief loads the $s skill, but .agents/skills/$s/SKILL.md is missing: not pasted" >&2
done
for skill in $skills; do
  { echo; echo "## Skill: $skill (reference; GEMINI.md and this brief win where they differ: typed GDScript, no C#)"
    sed '1,/^---$/{/^---$/!d}; /^---$/d' "$here/../.agents/skills/$skill/SKILL.md"; } >> "$prompt"
done
if [ -f "$root/.claude/rules/code.md" ]; then
  { echo; echo "## Code rules (.claude/rules/code.md)"; cat "$root/.claude/rules/code.md"; } >> "$prompt"
fi
if [ -z "${SKIP_BUILD:-}" ]; then run "$prompt" || idle_exit build; fi
leftovers "build"; cp "$wt.log" "$wt.build.log" 2> /dev/null; fix_from=""
if check; then :; else
  fix_from="$(git -C "$wt" rev-parse HEAD)"
  status_line RUNNING "fix pass"
  { echo "# Fix pass: $name (<= 45 min)"
    echo "You are in your own worktree on branch $prefix/$name. Your build of the brief below left checks failing."
    echo "Fix the causes, never weaken a test's intent, keep the brief's Do NOT edit list, run \`bash tools/check.sh\`"
    echo "until it prints \"all checks passed\", commit. The FAIL lines:"
    echo '```'; grep -A13 '^FAIL' "$wt.check.txt"; echo '```'
    echo; echo "## The brief"; cat "$brief"; } > "$wt.fix.md"
  OC_TIMEOUT=45m AGY_TIMEOUT=45m run "$wt.fix.md" || idle_exit "fix pass"; leftovers "fix pass"; check
fi
leftovers "check"  # the .uid files Godot wrote during the last check belong to the checked tree
gate="$($py "$here/build_gate.py" gate --wt "$wt" --base "$base" --brief "$brief" --check "$wt.check.txt" \
  --kind "$RUN_KIND" \
  --run-new-tests "${NEWTEST_KINDS:-py,gd}" ${fix_from:+--fix-from "$fix_from"} --inbox "$root/inbox" < /dev/null 2>&1)"
status="$(echo "$gate" | sed -n 's/^VERDICT //p')"; status="${status:-FAIL}"
{ echo "$status $(date +%H:%M) $prefix/$name"
  echo "builder $builder"
  echo "pid $$"
  echo "kind $RUN_KIND"
  [ -n "$idle_note" ] && echo "$idle_note"
  echo "checked $(git -C "$wt" rev-parse HEAD)"
  echo "$gate"; grep -E '^ {5}tests:' "$wt.check.txt" | head -3
  echo "--- commits"; git -C "$wt" log --oneline "$base..HEAD" | head -30
  echo "--- diffstat"; git -C "$wt" diff --stat "$base..HEAD" | tail -n 3; } > "$res"
cat "$res"
[ "$status" = PASS ]
