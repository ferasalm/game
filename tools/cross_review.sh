#!/usr/bin/env bash
# Cross-review (row 12 A, DECISIONS 2026-10-28): the other model family reviews a PASS run before Claude's gate:
# gemini/<run> (agy-built) -> cf (DeepSeek on opencode); oc/<run> (cf/oc-built) -> agy. One-shot from an empty box
# folder (no repo to explore, edit or push from); the reviewer reads box/packet.md = tools/cross_review_prompt.md +
# brief + `git diff -W` + the code-reviewer skill + code rules (a file, not -p text: Windows caps a command at ~32k).
# agy runs with --dangerously-skip-permissions --sandbox (Feras 10-29: headless agy denies even its file read without
# it); DeepSeek runs with bash, edit and web denied (cross_review.opencode.json). No valid block -> one forced round.
# Output: <checkout>/.check/reviews/<run>-cross.md; exit 0 OK, 1 INVALID, 2 usage.
# Usage: bash tools/cross_review.sh <run> <brief> <base> [head-ref] [reviewer agy|cf]
set -euo pipefail
. "$(dirname "$0")/lib.sh"
[ $# -ge 3 ] || { echo "usage: cross_review.sh <run> <brief> <base> [head-ref] [reviewer agy|cf]" >&2; exit 2; }
run="$1"; brief="$2"; base="$3"; head="${4:-}"; rev="${5:-}"
root="$(git rev-parse --show-toplevel)"
[[ "$run" =~ ^[a-z0-9-]+$ ]] || { echo "run name: lowercase letters, digits and - only" >&2; exit 2; }
[ -f "$brief" ] || { echo "no brief $brief" >&2; exit 2; }
if [ -z "$head" ]; then
  for p in gemini oc; do git -C "$root" rev-parse -q --verify "refs/heads/$p/$run" > /dev/null && head="$p/$run"; done
fi
[ -n "$head" ] || { echo "no branch gemini/$run or oc/$run: pass a head ref" >&2; exit 2; }
[ -n "$rev" ] || case "$head" in gemini/*) rev=cf ;; oc/*) rev=agy ;; *) echo "pass a reviewer for $head" >&2; exit 2 ;; esac
[ "$rev" = agy ] || [ "$rev" = cf ] || { echo "reviewer: agy or cf" >&2; exit 2; }

box="$(wt_dir)/xr/$run-$rev"; log="$(wt_dir)/$run.xr-$rev.log"; out="$root/.check/reviews/$run-cross.md"
rm -rf "$box"; mkdir -p "$box" "$(dirname "$out")"
{ cat "$lib_dir/cross_review_prompt.md"; echo; echo "## Brief"; cat "$brief"
  echo; echo "## Diff ($base..$head, with whole functions)"; git -C "$root" diff -W "$base" "$head"
  echo; echo "## Reviewer skill"; sed '1,/^---$/{/^---$/!d}; /^---$/d' "$root/.agents/skills/code-reviewer/SKILL.md"
  echo; echo "## Code rules"; cat "$root/.claude/rules/code.md"; } > "$box/packet.md"

ask() {  # <timeout> <message>: one reviewer call from the box, appending to the log
  local rc=0
  if [ "$rev" = agy ]; then
    (cd "$box" && run_limited "$1" agy -p "$2" --model "$AGY_MODEL" --dangerously-skip-permissions --sandbox \
      --print-timeout "$1" < /dev/null >> "$log" 2>&1) || rc=$?
  else
    if [ -z "${CLOUDFLARE_ACCOUNT_ID:-}" ]; then  # a setx value is not in shells started before it was set
      CLOUDFLARE_ACCOUNT_ID="$(powershell -NoProfile -Command \
        "[Environment]::GetEnvironmentVariable('CLOUDFLARE_ACCOUNT_ID','User')" | tr -d '\r')"
    fi
    (cd "$box" && CLOUDFLARE_ACCOUNT_ID="$CLOUDFLARE_ACCOUNT_ID" OPENCODE_CONFIG="$lib_dir/cross_review.opencode.json" \
      XDG_DATA_HOME="$HOME/.local/share/oc-cli" run_limited "$1" opencode run --model "$CF_MODEL" -f packet.md -- "$2" \
      < /dev/null >> "$log" 2>&1) || rc=$?
  fi
  [ $rc -eq 0 ] || echo "reviewer exited $rc" >> "$log"
}

: > "$log"
ask "$REVIEW_TIMEOUT" "Read packet.md in this folder and do exactly what it says. The packet holds everything you need: \
run no commands, edit no file, read no other file. Finish by printing the BEGIN FINDINGS block."
parse() { $py "$lib_dir/cross_review.py" parse "$log" --out "$out" < /dev/null; }
if ! parse > /dev/null; then
  echo "== forced round" >> "$log"
  ask 5m "Read packet.md in this folder. Do not explore, run or open anything else. Print only the \
BEGIN FINDINGS / END FINDINGS block the packet defines, from the diff it holds, now."
fi
[ "$rev" = agy ] || bash "$lib_dir/slots.sh" append-spend "$log" "$run-xr" "$CF_INPUT_RATE" "$CF_OUTPUT_RATE" \
  "$(wt_dir)/cf_spend.csv" || true
rc=0; parse || rc=$?
echo "review: $out; log: $log"
exit $rc
