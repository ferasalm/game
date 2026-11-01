# Brief: row24a-one-home-docs (HANDOFF row 24, part a)
You are in your own worktree on branch gemini/row24a-one-home-docs (made from origin/system-v4; the base is pushed). Follow GEMINI.md, including
<review_misses>. Load the minimal-change-engineer skill (build_pipeline.sh pastes it; our rules outrank its text).
Pattern: tools/doc_check.py
Timebox: 45 min. First commit within 15 min, then small WIP commits: no commit for 25 min (IDLE_MIN) = NOWORK.

## Why
Feras 11-01: every rule has one home; the builders skill (Who does what, Build loop, Prompt recipes) is the only worker table. Pillar: process.

## Read first
docs/briefs/system-v3.md lines 30-41 (the one-home map), .claude/skills/builders/SKILL.md (the home), docs/WORKFLOW.md (all; 23.5 KB), the `## Routing` section
of .claude/skills/builders/models.md (lines 101-117), docs/HOW_WE_WORK.md, tools/doc_check.py lines 40-70, tools/test_doc_check.py (read-only: its last test is red).

## What to build
1. docs/WORKFLOW.md to 14,000 bytes or less (`wc -c`). Replace with a one-line pointer to the builders skill: `## Model routing on Pro` and `## Builder loop`
   (delete both bodies), and in `## Start here` step 3 (Who does it) and any step restating the build loop. Keep `## Routing` untouched
   (doc_check reads it), `## Protocols` (Review) and `## Limits`. If still over 14,000 bytes, shrink `## Practices taken from reem-bot...`, `## This repo's own methods`
   and `## How Feras can save tokens` to the lines no other file states (grep first), pointer otherwise. Never add a rule while moving one; never reword a Feras decision.
2. .claude/skills/builders/models.md: delete the `## Routing` section's table (header `| Task class | Model | Calibrated |` and its rows) and its two lead lines that only introduce the table;
   keep the `Limits:` and `Evidence:` lines, the opencode free-routes sentence, and `## Rule`. One pointer line under the heading: `Which worker does what: SKILL.md, Who does what.`
   Every row's calibration evidence already lives in the model cards above; if a row's evidence appears nowhere above, keep it as one line under that model's card.
3. docs/HOW_WE_WORK.md: redraw the loop diagram for v3 and keep the file under 4,500 bytes: Feras decides; Opus plans and gates; Sonnet high executes and delegates to agy, cf and oc builders
   (Haiku low launches and waits); two plugins (studio: reviewers and gates; pm: queue and handoff); the row flow `queue row -> brief -> red test -> builder run -> gate -> review -> merge -> /handoff`.
4. tools/doc_check.py: add the check that fails with `second worker routing table: <path>` for any markdown table whose header starts `| Work | Who` or `| Work | Worker` or `| Task class | Model`,
   found in CLAUDE.md, docs/**/*.md (skip docs/archive/ and docs/research/) and .claude/skills/**/*.md, except .claude/skills/builders/SKILL.md. Make tools/test_doc_check.py green (all 6 tests).
   Follow the style of the existing checks (`check(cond, msg)`).
5. Run `bash tools/check.sh --no-godot`; fix only what you broke (stale pointers to a deleted section: grep `Model routing on Pro` and `Builder loop` across docs/ tools/ .claude/ plugins/ CLAUDE.md HANDOFF.md and repoint to `builders skill`).

## Do NOT edit
D6 defaults, protected by tools/build_gate.py without being listed: existing tests, tools/, .github/, plugins/ (edits and
deletions; new test files are allowed) and every change under assets/ (incl. *.import). Keep this prose free of
backticks: every backticked token in this section is a forbidden path, and May edit does not lift it.
`tools/test_doc_check.py`
`features/`
`core/`
`content/`
`.agents/skills/`
`.claude/rules/code.md`
`.claude/settings.json`
`docs/decisions-log.md`
`docs/DECISIONS.md`
`CLAUDE.md`
`HANDOFF.md`
`plugins/`

## May edit
`docs/WORKFLOW.md`
`docs/HOW_WE_WORK.md`
`.claude/skills/builders/models.md`
`.claude/skills/builders/SKILL.md`
`tools/doc_check.py`
`docs/MAP.md`

## Ripple
doc_check reads WORKFLOW `## Routing` and `## Limits` (keep both intact). Other files point at the two deleted sections (step 5 greps them). SKILL.md may change only a pointer line, never the Who does what table.

## Pre-mortem
1. The new check flags the builders SKILL table itself: the exception plus the test's first assert. 2. A pointer left to a deleted heading: step 5 grep. 3. WORKFLOW still over 14 KB: `wc -c` in Proof.

## Tests
`tools/test_doc_check.py :: test_a_second_worker_routing_table_fails` (red on the base): a second table fails, the builders table passes, docs/archive is ignored.

## Checklist
- has: tools/doc_check.py :: second worker routing table
- test: tools/test_doc_check.py :: test_a_second_worker_routing_table_fails

## Proof
`RUN_KIND=py`; `wc -c docs/WORKFLOW.md` (<= 14000); `bash tools/check.sh --no-godot` raw last 15 lines; final message ends with
`Built-by: Gemini 3.8 Flash (agy)`.
