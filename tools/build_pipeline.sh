#!/usr/bin/env bash
# Free builder pipeline (DECISIONS 2026-10-23): builder run -> check.sh -> one free fix pass fed the FAIL lines ->
# check.sh again -> ../game-wt/<task>.result (PASS/FAIL, fail lines, commits, leftovers). Claude reviews after it.
# Usage (cwd = the main checkout): bash <this repo>/tools/build_pipeline.sh <oc|agy> <task> <brief> <base> [model]
# Run it with run_in_background; agy needs stdin detached (< /dev/null) or it exits 2 at once. SKIP_BUILD=1 below.
set -uo pipefail
kind="$1"; name="$2"; brief="$(cd "$(dirname "$3")" && pwd)/$(basename "$3")"; base="$4"; model="${5:-}"
here="$(cd "$(dirname "$0")" && pwd)"
root="$(git rev-parse --show-toplevel)"; wt="$(dirname "$root")/game-wt/$name"; res="$wt.result"
prefix=oc; [ "$kind" = agy ] && prefix=gemini

run() {  # <brief file>
  if [ "$kind" = agy ]; then bash "$here/agy_task.sh" "$name" "$1" "$base" ${model:+"$model"} < /dev/null
  else bash "$here/oc_task.sh" "$name" "$1" "$base" ${model:+"$model"} < /dev/null; fi
}
check() {  # -> 0 when all checks pass; output in <task>.check.txt
  (cd "$wt" && bash tools/check.sh > "$wt.check.txt" 2>&1)
}
leftovers() {  # builders die mid-edit: keep their work as a WIP commit
  if [ -n "$(git -C "$wt" status --porcelain)" ]; then
    git -C "$wt" add -A && git -C "$wt" commit -q -m "WIP: $1 leftovers (build_pipeline)"
  fi
}

echo "RUNNING $(date +%H:%M) build" > "$res"
# The skill the brief names (".agents/skills/<name>") goes into the prompt itself: builders skipped optional skills.
prompt="$(dirname "$wt")/$name.prompt.md"; cp "$brief" "$prompt"
skill="$(grep -o -m1 -E '(godot|game|level|narrative|technical|blender)-[a-z-]+ skill' "$brief" | sed 's/ skill$//')"
if [ -n "$skill" ] && [ -f "$here/../.agents/skills/$skill/SKILL.md" ]; then
  { echo; echo "## Skill: $skill (reference; GEMINI.md and this brief win where they differ: typed GDScript, no C#)"
    sed '1,/^---$/{/^---$/!d}; /^---$/d' "$here/../.agents/skills/$skill/SKILL.md"; } >> "$prompt"
fi
[ -n "${SKIP_BUILD:-}" ] || run "$prompt"  # SKIP_BUILD=1: the build already ran; start at the check
leftovers "build"; cp "$wt.log" "$wt.build.log" 2> /dev/null
if check; then status=PASS; else
  echo "RUNNING $(date +%H:%M) fix pass" > "$res"
  { echo "# Fix pass: $name (<= 45 min)"
    echo "You are in your own worktree on branch $prefix/$name. Your build of the brief below left checks failing."
    echo "Fix the causes, never weaken a test's intent, keep the brief's Do NOT edit list, run \`bash tools/check.sh\`"
    echo "until it prints \"all checks passed\", commit. The FAIL lines:"
    echo '```'; grep -A13 '^FAIL' "$wt.check.txt"; echo '```'
    echo; echo "## The brief"; cat "$brief"; } > "$wt.fix.md"
  OC_TIMEOUT=45m AGY_TIMEOUT=45m run "$wt.fix.md"; leftovers "fix pass"
  if check; then status=PASS; else status=FAIL; fi
fi
[ -n "$(git -C "$wt" log --oneline "$base..HEAD")" ] || status="NOWORK"  # green but nothing built (quota, quit)
{ echo "$status $(date +%H:%M) $prefix/$name"
  grep -E '^(ok|FAIL)|^ {5}|passed|FAILED' "$wt.check.txt" | head -40
  echo "--- commits"; git -C "$wt" log --oneline "$base..HEAD" | head -30
  echo "--- diffstat"; git -C "$wt" diff --stat "$base..HEAD" | tail -n 3; } > "$res"
cat "$res"
