# Brief: row28-c-cliff-guard (agy; Python, RUN_KIND=py)
You are in your own worktree on branch gemini/row28-c-cliff-guard (made from origin/main). Follow GEMINI.md, including
<review_misses>. Load the builders skill.
Pattern: tools/free_mb.py, tools/kaizen_report.py
Timebox: 30 min (<= 45). First commit within 15 min, then small WIP commits.

## Why
Feras 11-04: keep paid and subagent calls under their price cliffs. Verified live 11-04: Haiku 5.5 costs 5x past 100k prompt tokens, GPT-6 Luna about 2x input and 1.5x output past 272k; Sonnet 5.5, DeepSeek and GLM have none (the plan's 200k guess was wrong). Pillar served: none directly (spend control).

## Read first
.claude/skills/low-cost-pipeline/foremen.md, tools/build_pipeline.sh (where the prompt file is assembled), tools/lib.sh.

## What to build
1. `tools/cliff_guard.py <prompt-file> <model-slug>` (<= 70 lines): estimate tokens as bytes / 3.5; print `WARN: ~<n>k tokens, past <model>'s <limit>k price cliff (x<mult>)` and exit 0 when over, silent when under. Cliffs in a small table at the top: haiku 100000, luna 272000; unknown models never warn.
2. build_pipeline.sh calls it on the finished prompt file and appends the warning to the run's stderr (a warning, never a refusal).
3. foremen.md gets the same two numbers in one line, replacing any 200k statement.

## Do NOT edit
D6 defaults, protected by tools/build_gate.py without being listed. Keep this prose free of backticks outside May edit.

## May edit
`tools/cliff_guard.py`
`tools/build_pipeline.sh`
`.claude/skills/low-cost-pipeline/foremen.md`

## Locked tests (the head wrote them, read them first; do not edit them)
tools/test_cliff_guard.py pins: the exact output `WARN: ~120k tokens, past haiku's 100k price cliff (x5)` on stdout (tokens = bytes / 3.5, whole k, key = haiku or luna, matched case-insensitively inside the slug), luna 272k x2, silence and exit 0 for under, unknown slug or unreadable file, a call in build_pipeline.sh on the prompt file, and foremen.md naming 100k and 272k with no 200k left.

## Ripple
build_pipeline.sh is read by every run (edit only while no run is live). grep the repo for 200k: routing.md, models.md and DECISIONS name the old cliff; part e fixes the docs, this brief fixes foremen.md only.

## Pre-mortem
- The estimate is off: bytes / 3.5 errs high for code; a 20 percent miss is fine for a warning.
- A warning spam on every run: it prints only over a cliff; a test pins the silent case.
- A cliff changes: the table has a source comment with the 11-04 date.

## Tests
- tools/test_cliff_guard.py :: under, over, unknown model (red on the base). Player-visible: not applicable.

## Checklist
- file: tools/cliff_guard.py
- has: tools/cliff_guard.py :: main
- test: tools/test_cliff_guard.py :: test_haiku_over_100k_warns

## Proof
`bash tools/check.sh --no-godot` raw last 15 lines; final message ends with `Built-by: Gemini 3.8 Flash (agy)`.
