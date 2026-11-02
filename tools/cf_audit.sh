#!/usr/bin/env bash
# Read-only audit by Cloudflare DeepSeek V4.1 Flash at max (row 25, Feras 11-01): the model reads the repository with opencode's
# read tools only (tools/cross_review.opencode.json denies edit, bash, web, task) and prints one report. Needs no Claude tokens.
# Staged under <repo>/.check/audit/: prompt.md, coach/ (the kaizen coach checklists), memory/ (the user's memory files), because
# opencode may not read outside the repo (external_directory deny). COACH_DIR and MEMORY_DIR override where they come from.
# Usage (cwd = a checkout): bash tools/cf_audit.sh <prompt-file> <out-file> [timeout, default AUDIT_TIMEOUT or 30m]
# Model: AUDIT_MODEL, default cf DeepSeek V4.1 Flash max. GLM lens: AUDIT_MODEL=cloudflare-workers-ai/@cf/zai-org/glm-5.3-flash
# (no effort levels, Feras 10-31) or cloudflare-workers-ai/@cf/zai-org/glm-5.3 (max). Their long-output caps live in cross_review.opencode.json.
# Exit: 0 ran, 2 usage, 124 timed out (the partial report stays in <out-file>). Spend line: cf_spend.csv like a cross-review.
set -uo pipefail
. "$(dirname "$0")/lib.sh"
[ $# -ge 2 ] && [ -f "$1" ] || { echo "usage: cf_audit.sh <prompt-file> <out-file> [timeout]" >&2; exit 2; }
prompt="$1"; out="$2"; limit="${3:-${AUDIT_TIMEOUT:-30m}}"
root="${AUDIT_ROOT:-$(git rev-parse --show-toplevel 2> /dev/null)}"  # AUDIT_ROOT: audit another checkout (an old commit's worktree)
[ -n "$root" ] && [ -d "$root" ] || { echo "not inside a git repository (or AUDIT_ROOT is not a folder)" >&2; exit 2; }

box="$root/.check/audit"
rm -rf "$box"; mkdir -p "$box/coach" "$box/memory"
cp "$prompt" "$box/prompt.md"
coach="${COACH_DIR:-$(ls -d "$HOME"/.claude/plugins/cache/kaizen/kaizen/*/skills/coach/references 2> /dev/null | tail -n 1)}"
[ -z "$coach" ] || [ ! -d "$coach" ] || cp -r "$coach"/. "$box/coach/"
mem="${MEMORY_DIR:-$HOME/.claude/projects/C--dev-game/memory}"
[ ! -d "$mem" ] || cp "$mem"/*.md "$box/memory/" 2> /dev/null || true

ask="Read .check/audit/prompt.md and do exactly what it says. You may read any file in this repository, including \
.check/audit/coach (the audit checklists) and .check/audit/memory (the user's memory files). Run no command, edit no file, \
write nothing. Print the finished report as your final answer."
: > "$out"
rc=0
# The repo's own opencode.json allows bash and edit and outranks OPENCODE_CONFIG (probed 11-01: a file was written); inline
# content outranks the project file, so the deny rules go in both. cross_review.sh needs no inline copy: its box has no project file.
(cd "$root" && OPENCODE_CONFIG="$lib_dir/cross_review.opencode.json" \
  OPENCODE_CONFIG_CONTENT="$(cat "$lib_dir/cross_review.opencode.json")" run_limited "$limit" oc_run --model "${AUDIT_MODEL:-$CF_MODEL}" \
  --format default -- "$ask" < /dev/null >> "$out" 2>&1) || rc=$?
[ "$rc" -eq 0 ] || echo "audit exited $rc" >> "$out"
bash "$lib_dir/slots.sh" append-spend "$out" "audit" "$CF_INPUT_RATE" "$CF_OUTPUT_RATE" "$(wt_dir)/cf_spend.csv" || true
sed -i '/^timestamp=.* level=INFO /d' "$out"  # opencode v2 logs each git call at INFO: 269 KB around a 6 KB report (11-02); errors stay
echo "audit report: $out"
exit "$rc"
