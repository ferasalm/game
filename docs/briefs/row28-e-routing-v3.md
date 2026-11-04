# Brief: row28-e-routing-v3 (head, Sonnet high; docs and a small Python edit, RUN_KIND=py)
You are in your own worktree on branch worktree-row28-e (made from origin/main after parts a-d). Follow GEMINI.md, including
<review_misses>. Load the builders skill.
Pattern: tools/runs_log.py, tools/test_runs_log.py
Timebox: 40 min (<= 45). First commit within 15 min, then small WIP commits.

## Why
Feras 11-04 (what-we-have pipeline, decisions-log): agy builds most; GLM-5.3-flash takes levels, technical art, dialogue, narrative; DeepSeek 1017 takes debug, balance, optimization, accuracy-critical mechanics; routine reads go to agy flash-low then Haiku. The docs and runs.csv must say so. Pillar served: none directly.

## Read first
.claude/skills/low-cost-pipeline/routing.md and SKILL.md, .claude/skills/builders/models.md, docs/decisions-tools.md, docs/WORKFLOW.md Routing table, tools/runs_log.py.

## What to build
1. routing.md: the role table of the row 28 plan (head, agy build, GLM content, DeepSeek accuracy, reads, consultant) with the lane order: OpenRouter :free, then paid on its own key with the $3 cap and PAID_OK=1, NIM overnight only.
2. models.md: add GLM-5.3-flash (NIM id z-ai/glm-5.3-flash; OpenRouter price range), DeepSeek 1017 provider routing (fp8 or better, DeepSeek endpoint ignored), the verified cliffs (Haiku 100k, Luna 272k, Sonnet none), the DeepSeek peak hours in GMT+3.
3. WORKFLOW Routing table and builders skill: the same roles, nothing else changed.
4. runs_log.py and its test: runs.csv gains columns provider, effort, peak (0 or 1), cost_usd; old rows read back with blanks; one test per column.
5. DECISIONS Process gets no new line unless the head adds one from decisions-log 11-04 (the head owns it).

## Do NOT edit
D6 defaults, protected by tools/build_gate.py without being listed. Keep this prose free of backticks outside May edit.

## May edit
`.claude/skills/low-cost-pipeline/routing.md`
`.claude/skills/builders/models.md`
`.claude/skills/builders/SKILL.md`
`docs/WORKFLOW.md`
`tools/runs_log.py`
`tools/test_runs_log.py`

## Ripple
runs.csv is read by kaizen_report.py (part b reads the peak flag) and slots.sh append-spend: keep the old column order and append new ones at the end. doc_check.py counts note sizes: stay inside the caps.

## Pre-mortem
- Old rows break the reader: the test loads a base-era row.
- Docs contradict decisions: the head greps `Cloudflare` and `200k` after the edit.
- A cap overflow: run doc_check before the commit.

## Tests
- tools/test_runs_log.py :: test_new_columns_round_trip, test_old_rows_read_with_blanks (red on the base). Player-visible: not applicable.

## Checklist
- file: .claude/skills/low-cost-pipeline/routing.md
- has: tools/runs_log.py :: peak
- test: tools/test_runs_log.py :: test_new_columns_round_trip

## Proof
`bash tools/check.sh --no-godot` raw last 15 lines; final message ends with `Built-by: <model> (opencode)`.
