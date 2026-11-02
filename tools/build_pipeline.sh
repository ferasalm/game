#!/usr/bin/env bash
# Free builder pipeline (DECISIONS 2026-10-23, hardened 2026-10-27, run state 2026-11-02): slots check -> builder run (idle
# and quiet watchdogs) -> check.sh -> up to FIX_PASSES free fix passes fed the FAIL lines, each checked -> build_gate.py ->
# game-wt/<task>.result (first word PASS/FAIL/NOWORK/BREACH/ERROR, the gate's checklist, the checked commit, the pipeline's
# pid, the model and the minutes an idle or quiet kill cost). Exit 0 only for PASS; tools/merge_run.sh merges a PASS.
# Usage (cwd = a checkout whose origin has <base> pushed): bash tools/build_pipeline.sh <oc|agy|cf> <task> <brief> <base> [model]
# Refuses (exit 3, no .result) when slots/memory say no, when <base> has commits origin lacks, when <base> holds a red tool
# test the brief does not name (base_red.py), or when an oc builder would spend a spent opencode/*-free route.
# Every end path (PASS, FAIL, BREACH, ERROR, NOWORK, REFUSED) appends one docs/runs.csv row (tools/run_state.sh).
# Run it with run_in_background. Env: SKIP_BUILD=1 (build already ran), BUILDER_CMD (stub builder, tests), IMPORT_CMD,
# IDLE_SEC, QUIET_SEC, NEWTEST_KINDS (py,gd: new tests are run against the base by the gate).
set -uo pipefail
. "$(dirname "$0")/lib.sh"
builder="$1"; name="$2"; brief="$(cd "$(dirname "$3")" && pwd)/$(basename "$3")"; base="$4"; model="${5:-}"
RUN_KIND="${RUN_KIND:-godot}"
here="$lib_dir"; root="$(git rev-parse --show-toplevel)"; dir="$(wt_dir)"; wt="$dir/$name"; res="$wt.result"
prefix="$(builder_prefix "$builder")"
idle_sec="${IDLE_SEC:-$((IDLE_MIN * 60))}"; quiet_sec="${QUIET_SEC:-300}"; poll="${WATCH_POLL:-20}"
pipeline_start=$(date +%s)
idle_min=0; idle_note=""; quota=""; bg_kill=""; quiet=""; quiet_n=0; fork_note=""; fix=0
model_used="${model:-}"
if [ -z "$model_used" ]; then  # the model the build runs on: argv, else the builder's builders.conf default
  case "$builder" in agy) model_used="$AGY_MODEL" ;; cf) model_used="$CF_MODEL" ;; oc) model_used="$OC_MODEL" ;; esac
fi
eff_m="$model_used"
rm -f "$res"  # a refused or relaunched run must not leave an old PASS for a reader (row25-sync-dirty)
. "$here/run_state.sh"  # result_head, row_tokens, clean_empty_wt, nowork_exit: one truth for every end path

log_row() {  # <gate> <minutes> <fix passes>: ONE docs/runs.csv row per end path; a failed call warns, never hides
  local tin tout usd src eff
  read -r tin tout usd src <<< "$(row_tokens "$1")"
  eff="$($py tools/model_effort.py "$eff_m" 2> /dev/null)"; [ -n "$eff" ] || eff="-"
  local args=(append --task "$name" --worker "$builder" --effort "$eff" --gate "$1" --fix-passes "$3" --minutes "$2")
  args+=(--cost 0 --findings 0 --tokens-in "$tin" --tokens-out "$tout" --usd "$usd" --source "$src" --idle-min "$idle_min")
  $py tools/runs_log.py "${args[@]}" || echo "WARN: the run logger failed, no docs/runs.csv row for $name" >&2 || true
}
refuse() { echo "REFUSED: $*" >&2; echo "REFUSED: $*"; clean_empty_wt; log_row REFUSED 0 "$fix"; exit 3; }
case "$builder" in  # a spent free route prints nothing and exits 0 (row16-audit): never launch one by accident
  oc) case "$model_used" in opencode/*-free)
        [ "${OC_ALLOW_FREE:-0}" = 1 ] || refuse "opencode/...-free routes are spent; use tools/cf_build.sh (or OC_ALLOW_FREE=1)" ;;
      esac ;;
esac
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
brief_copy="$dir/$name.brief.md"  # the original may vanish mid-run (row25-sync-dirty): every step reads this copy
cp "$brief" "$brief_copy" 2> /dev/null || refuse "brief $brief is not readable"
brief="$brief_copy"

run() {  # <brief file>; watched: idle (no commit), quiet (a commit but no log growth), background check. 99 when killed.
  local last pid mark bg_mark="" log_size=-1 log_mark
  mark=$(date +%s); log_mark=$mark
  if [ -n "${BUILDER_CMD:-}" ]; then bash "$BUILDER_CMD" "$name" "$1" "$base" ${model:+"$model"} < /dev/null > "$wt.log" 2>&1 &
  elif [ "$builder" = agy ]; then bash "$here/agy_task.sh" "$name" "$1" "$base" ${model:+"$model"} < /dev/null &
  else bash "$here/oc_task.sh" "$name" "$1" "$base" ${model:+"$model"} < /dev/null & fi
  pid=$!
  while kill -0 "$pid" 2> /dev/null; do
    sleep "$poll"
    local now size; now=$(date +%s)
    last="$(git -C "$wt" log -1 --format=%ct 2> /dev/null || echo 0)"; [ "${last:-0}" -gt "$mark" ] && mark="$last"
    size="$(stat -c %s "$wt.log" 2> /dev/null || echo 0)"; [ "$size" = "$log_size" ] || { log_size="$size"; log_mark=$now; }
    # opencode's spent free quota prints no text and exits 0 (row16-audit hung 25 min, 10-29): stop at the first sight
    if grep -q "$OC_QUOTA_MSG" "$wt.log" 2> /dev/null; then quota=1; kill_tree "$pid"; wait "$pid" 2> /dev/null; return 99; fi
    # A check the builder moved to the background reaches no commit (fast-probe-stream polled one for 25 min, row 18c)
    if [ -z "$bg_mark" ] && grep -a -B2 "$OC_BG_MSG" "$wt.log" 2> /dev/null | grep -aq 'check\.sh'; then bg_mark="$now"; fi
    if [ -n "$bg_mark" ] && [ "$mark" -lt "$bg_mark" ] && [ $(( now - bg_mark )) -ge "$BG_WAIT_SEC" ]; then
      bg_kill=1; kill_tree "$pid"; wait "$pid" 2> /dev/null; return 99; fi
    # A builder that commits then hangs costs the full IDLE_MIN (row25-base-red: 25 of 31 min): with a commit in the
    # worktree, a log that stops growing means it is done or stuck; its commits are checked below.
    if [ "$quiet_sec" -gt 0 ] && [ $(( now - log_mark )) -ge "$quiet_sec" ] && commits; then
      quiet=1; quiet_n=$(( now - log_mark )); kill_tree "$pid"; wait "$pid" 2> /dev/null; return 99; fi
    if [ $(( now - mark )) -ge "$idle_sec" ]; then kill_tree "$pid"; wait "$pid" 2> /dev/null; return 99; fi
  done
  wait "$pid"; grep -aqE "$FORK_FAIL_RE" "$wt.log" 2> /dev/null && fork_note="memory: fork failed in the builder's shell, the PC ran out, not the model"
  return 0
}
kill_exit() {  # <step>: killed idle/quiet/background. Committed work still goes to check and gate (builders hang after a commit)
  leftovers "$1"
  idle_min=$(( idle_sec / 60 )); [ -z "$quiet" ] || idle_min=$(( quiet_n / 60 )); [ -z "$bg_kill" ] || idle_min=0
  if commits; then
    idle_note="idle: $1 killed after ${idle_sec}s without a commit; its commits were checked"
    if [ -n "$quiet" ]; then idle_note="quiet: $1 killed after ${quiet_n}s without log output; its commits were checked"
    elif [ -n "$bg_kill" ]; then idle_note="background: $1 killed ${BG_WAIT_SEC}s after moving its check to the background; its commits were checked"; fi
    bg_kill=""; quiet=""; return 0
  fi
  local why="idle: no commit for ${idle_sec}s, builder killed (the brief needs a first-commit deadline)"
  [ -z "$quiet" ] || why="quiet: no log output for ${quiet_n}s, builder killed and it made no commit to check"
  [ -z "$quota" ] || why="quota: opencode's free usage limit is spent ($OC_QUOTA_MSG); rerun on cf (tools/cf_build.sh)"
  nowork_exit "$why"
}
check() {  # -> 0 when all checks pass; output in <task>.check.txt
  refresh_map
  if [ "$RUN_KIND" = py ]; then
    (cd "$wt" && bash tools/check.sh --no-godot < /dev/null > "$wt.check.txt" 2>&1)
  else
    import_wt; (cd "$wt" && bash tools/check.sh < /dev/null > "$wt.check.txt" 2>&1)
  fi
}

run_rules() {  # fast-probe-stream died in its first check with nothing committed, then waited on a background check (row 18c)
  echo; echo "## Pipeline rules (they outrank any timing in the brief)"
  echo "- Commit before your first check (\`git add -A\`, then \`git commit\`) and after each step: a run that dies keeps only its commits."
  echo "- Run \`$chk\` in the foreground and wait for it, however slow. Never background it or send it to a log to poll:"
  echo "  the pipeline kills that run ${BG_WAIT_SEC}s later and checks your commits itself."
}
status_line RUNNING build
# A sibling's red test on the base failed every part's check and sent fix passes after it (rows 23, 24): refuse before the build.
if [ -z "${SKIP_BUILD:-}" ]; then
  red="$(timeout "$BASE_RED_SEC" "$py" "$here/base_red.py" "$brief" "$base" < /dev/null 2>&1)"; red_rc=$?
  if [ "$red_rc" -eq 1 ]; then rm -f "$res"; refuse "$red"; fi
  [ "$red_rc" -eq 0 ] || echo "WARN: base_red.py did not finish (exit $red_rc), the base is unchecked: $red" >&2
fi
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
run_rules >> "$prompt"
if [ -z "${SKIP_BUILD:-}" ]; then run "$prompt" || kill_exit build; fi
leftovers "build"; cp "$wt.log" "$wt.build.log" 2> /dev/null; fix_from=""
# A builder that never started (oc_task.sh refused: a leftover worktree from another base, a missing opencode, exit 126)
# leaves nothing to check: NOWORK with its own first line as the reason, never the gate's bare "CHECKLIST missing".
if [ -z "${SKIP_BUILD:-}" ] && ! commits && git -C "$wt" rev-parse HEAD > /dev/null 2>&1; then
  why="$(grep -a -m1 '[^[:space:]]' "$wt.log" 2> /dev/null | tr -d '\r')"
  nowork_exit "${why:-the builder exited with no commit and no change in its worktree}"
fi
fix=0  # FIX_PASSES free fix passes (builders.conf; Feras 10-28: builder time is free), each fed the latest FAIL lines
until check; do
  [ "$fix" -lt "$FIX_PASSES" ] || break  # count the passes that ran, not the one that was refused (row 24b: 3 of 2)
  fix=$((fix + 1))
  model="${FIX_MODEL:-$model}"  # a fast build's failures are debugging: they get the reasoning model (cf_build.sh fast)
  [ -n "$fix_from" ] || fix_from="$(git -C "$wt" rev-parse HEAD)"
  status_line RUNNING "fix pass $fix"
  { echo "# Fix pass $fix of $FIX_PASSES: $name (<= 45 min)"
    echo "You are in your own worktree on branch $prefix/$name. Your build of the brief below left checks failing."
    echo "Fix the causes, never weaken a test's intent, keep the brief's Do NOT edit list, run \`$chk\`"
    echo "until it prints \"all checks passed\", commit. The FAIL lines:"
    echo '```'; grep -A13 '^FAIL' "$wt.check.txt"; echo '```'
    run_rules; echo; echo "## The brief"; cat "$brief"; } > "$wt.fix.md"
  OC_TIMEOUT=45m AGY_TIMEOUT=45m run "$wt.fix.md" || kill_exit "fix pass $fix"; leftovers "fix pass $fix"
done
leftovers "check"  # the .uid files Godot wrote during the last check belong to the checked tree
gate="$($py "$here/build_gate.py" gate --wt "$wt" --base "$base" --brief "$brief" --check "$wt.check.txt" \
  --kind "$RUN_KIND" \
  --run-new-tests "${NEWTEST_KINDS:-py,gd}" ${fix_from:+--fix-from "$fix_from"} --inbox "$root/inbox" < /dev/null 2>&1)"
status="$(echo "$gate" | sed -n 's/^VERDICT //p' | head -1)"
gate_error=""
if [ -z "$status" ]; then  # a crashed gate is ERROR with its own line, never FAIL (row25-sync-dirty read a traceback as FAIL)
  status=ERROR; gate_error="$(echo "$gate" | grep -v '^[[:space:]]*$' | tail -1)"
  [ -n "$gate_error" ] || gate_error="the gate printed no output"
fi
{ result_head "$status" "$prefix/$name"
  [ -z "$idle_note" ] || echo "$idle_note"
  [ -z "$fork_note" ] || echo "$fork_note"
  [ -z "$gate_error" ] || echo "gate error: $gate_error"
  echo "checked $(git -C "$wt" rev-parse HEAD)"
  echo "$gate"; grep -E '^ {5}tests:' "$wt.check.txt" | head -3
  echo "--- commits"; git -C "$wt" log --oneline "$base..HEAD" | head -30
  echo "--- diffstat"; git -C "$wt" diff --stat "$base..HEAD" | tail -n 3; } > "$res"
cat "$res"
log_row "$status" "$(( ($(date +%s) - pipeline_start) / 60 ))" "$fix"
[ "$status" = PASS ]
