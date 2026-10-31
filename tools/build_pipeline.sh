#!/usr/bin/env bash
# Free builder pipeline (DECISIONS 2026-10-23, hardened 2026-10-27): slots check -> builder run (idle watchdog) ->
# check.sh -> up to FIX_PASSES free fix passes fed the FAIL lines, each checked -> tools/build_gate.py -> game-wt/<task>.result
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
here="$lib_dir"; root="$(git rev-parse --show-toplevel)"; dir="$(wt_dir)"; wt="$dir/$name"; res="$wt.result"
prefix="$(builder_prefix "$builder")"
idle_sec="${IDLE_SEC:-$((IDLE_MIN * 60))}"; poll="${WATCH_POLL:-20}"

refuse() { echo "REFUSED: $*" >&2; echo "REFUSED: $*"; exit 3; }
case "$RUN_KIND" in godot) chk="bash tools/check.sh" ;; py) chk="bash tools/check.sh --no-godot" ;;
  *) refuse "RUN_KIND must be godot or py, not $RUN_KIND" ;; esac
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
    # opencode's spent free quota prints no text and exits 0 (row16-audit hung 25 min, 10-29): stop at the first sight
    if grep -q "$OC_QUOTA_MSG" "$wt.log" 2> /dev/null; then quota=1; kill_tree "$pid"; wait "$pid" 2> /dev/null; return 99; fi
    if [ $(( $(date +%s) - mark )) -ge "$idle_sec" ]; then kill_tree "$pid"; wait "$pid" 2> /dev/null; return 99; fi
  done
  wait "$pid"; return 0
}
idle_note=""; quota=""
idle_exit() {  # <step>: killed idle. Committed work still goes to check and gate (builders hang after a last commit)
  leftovers "$1"
  if [ -n "$(git -C "$wt" log --oneline "$base..HEAD" 2> /dev/null)" ]; then
    idle_note="idle: $1 killed after ${idle_sec}s without a commit; its commits were checked"; return 0
  fi
  local why="idle: no commit for ${idle_sec}s, builder killed (the brief needs a first-commit deadline)"
  [ -z "$quota" ] || why="quota: opencode's free usage limit is spent ($OC_QUOTA_MSG); rerun on cf (tools/cf_build.sh)"
  { echo "NOWORK $(date +%H:%M) $prefix/$name"; echo "builder $builder"; echo "pid $$"; echo "kind $RUN_KIND"
    echo "$why"; } > "$res"
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
skill_file() {  # a persona (.agents/skills) or a task skill (.claude/skills, e.g. players-eye-gate)
  local d; for d in .agents .claude; do [ -f "$here/../$d/skills/$1/SKILL.md" ] && { echo "$here/../$d/skills/$1/SKILL.md"; return 0; }; done
  return 1
}
skills="$(grep -o -E '[a-z][a-z-]+ skill' "$brief" | sed 's/ skill$//' | awk '!seen[$0]++' |
  while read -r s; do skill_file "$s" > /dev/null && echo "$s"; done | head -2)"
# A skill the brief loads ("Load the X skill") that does not exist is not pasted: say so (P2b review).
for s in $(grep -o -E 'Load the [a-z][a-z-]+ skill' "$brief" | awk '{print $3}' | awk '!seen[$0]++'); do
  skill_file "$s" > /dev/null || echo "WARN: the brief loads the $s skill, but no .agents or .claude skill has it: not pasted" >&2
done
for skill in $skills; do
  { echo; echo "## Skill: $skill (reference; GEMINI.md and this brief win where they differ: typed GDScript, no C#)"
    sed '1,/^---$/{/^---$/!d}; /^---$/d' "$(skill_file "$skill")"; } >> "$prompt"
done
# "Pattern: a.gd, b.gd" lines: real files to copy. No-reasoning DeepSeek dropped its flaws with one in the prompt (row 18)
for f in $(sed -n 's/^Pattern: *//p' "$brief" | tr ',\r' '  ' | xargs -n 1 2> /dev/null | head -3); do
  if git cat-file -e "$base:$f" 2> /dev/null; then
    { echo; echo "## Pattern to follow: $f"; echo '```'; git show "$base:$f"; echo '```'; } >> "$prompt"
  else echo "WARN: Pattern $f is not on the base: not pasted" >&2; fi
done
if [ -f "$root/.claude/rules/code.md" ]; then
  { echo; echo "## Code rules (.claude/rules/code.md)"; cat "$root/.claude/rules/code.md"; } >> "$prompt"
fi
if [ -z "${SKIP_BUILD:-}" ]; then run "$prompt" || idle_exit build; fi
leftovers "build"; cp "$wt.log" "$wt.build.log" 2> /dev/null; fix_from=""
fix=0  # FIX_PASSES free fix passes (builders.conf; Feras 10-28: builder time is free), each fed the latest FAIL lines
until check; do
  fix=$((fix + 1)); [ "$fix" -le "$FIX_PASSES" ] || break
  model="${FIX_MODEL:-$model}"  # a fast build's failures are debugging: they get the reasoning model (cf_build.sh fast)
  [ -n "$fix_from" ] || fix_from="$(git -C "$wt" rev-parse HEAD)"
  status_line RUNNING "fix pass $fix"
  { echo "# Fix pass $fix of $FIX_PASSES: $name (<= 45 min)"
    echo "You are in your own worktree on branch $prefix/$name. Your build of the brief below left checks failing."
    echo "Fix the causes, never weaken a test's intent, keep the brief's Do NOT edit list, run \`$chk\`"
    echo "until it prints \"all checks passed\", commit. The FAIL lines:"
    echo '```'; grep -A13 '^FAIL' "$wt.check.txt"; echo '```'
    echo; echo "## The brief"; cat "$brief"; } > "$wt.fix.md"
  OC_TIMEOUT=45m AGY_TIMEOUT=45m run "$wt.fix.md" || idle_exit "fix pass $fix"; leftovers "fix pass $fix"
done
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
