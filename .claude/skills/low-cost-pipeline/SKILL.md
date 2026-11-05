---
name: low-cost-pipeline
description: The whole build workflow of this repo in one folder: a Claude head (Opus or Sonnet, high) plans, decides and writes the red tests, cheap workers (agy gemini-3.8-flash, DeepSeek V4.1 Flash, GLM-5.3-flash) write code in parallel, scripts report back in 15 lines. Use when a chat must plan a batch, delegate, build, review, merge or resume a pipeline task.
---
# Low-cost pipeline (Feras 11-01, v2 11-02): one folder owns the workflow
The head is any Claude chat at high effort (`claude --model opusplan`: Opus plans, Sonnet high executes). The head decides and
adjudicates; cheap workers do the bulk; every other stage is a script. Claude tokens are the scarce thing; free-tier model calls are not (rate limits are their only cap).
Files here: [routing.md](routing.md) who does what, [foremen.md](foremen.md) reports and context hygiene,
[mechanical.md](mechanical.md) the no-reasoning lane, [proof.md](proof.md) proof runs and how to read the scoreboard,
[changelog.md](changelog.md) one line per upgrade, [templates/](templates/) the three brief shapes.

## Resume (a fresh head, cold)
0. Start the chat in its own worktree: `claude --model opusplan -w <name>` (not in C:\dev\game and then entering one: that lists every project skill twice, measured 11-02).
1. `bash tools/status.sh`, then read the plan file named in HANDOFF.md or the prompt (for row 26: docs/briefs/row26-pipeline-v2-plan.md). State lives in files, never in chat memory.
2. `bash tools/slots.sh` (what runs, memory), `python tools/part_report.py <task>` per finished part (15 lines each).
3. Take the next unfinished step of the plan; tell Feras one line (step, who runs it).

## Plan a batch (before any launch)
- Split by FILES, not features: every part owns a disjoint May edit set and its own locked red test; only generated files (MAP.md, DOCMAP.md, runs.csv, doc_graph_allow.txt) may be shared. Parts that need another's output run after it. State the merge order (leaves first, wiring last).
- `python tools/ripple.py <brief>` lists existing tests that name the files you will touch: put their unavoidable fixture edits in May edit with a reason (two BREACHes on 11-02 were this miss).
- `python tools/parts_plan.py brief1.md brief2.md ...` must print OK (overlap, contradictions, shared tests).
- Same model may run several times at once (caps in tools/builders.conf, per builder family); parallel parts cost free-tier requests (NVIDIA ~40 a minute, CAP_NV), not Claude tokens.
- Pick each part's worker from routing.md; pre-mortem in three lines; no open design questions in a brief.

## Flow of one part
1. Brief from the right template (templates/); the DeepSeek-max critic reads spec and brief into a file; the head fixes the real gaps. The critic is a different family than the test writer.
2. Red tests: the head writes them (DECISIONS 11-04) on a `<task>-tests` branch; test ideas may come from an isolated one-shot consult (row 28 part i) or a scope run (`EXPECT_RED=1 RUN_KIND=py bash tools/nv_build.sh <task>-tests <brief> <base> deepseek`, FIX_PASSES=0, SCOPED or REJECT) whose every test the head READS and edits or rejects. Then `bash tools/lock_tests.sh <task>-tests <task>-base` (the tests branch becomes the hand's base; the gate protects them).
3. Build: `RUN_KIND=py bash tools/nv_build.sh <task> <brief> <task>-base [deepseek|glm|model]` (the family's chain, routing.md; agy: `bash tools/build_pipeline.sh agy ...`), run_in_background. Never pass a base holding another part's red test.
4. Read `python tools/part_report.py <task>`: PASS -> review; FAIL/NOWORK/ERROR -> read the one named reason; BREACH -> read the breach (usually a fixture edit the brief missed: review the diff, merge by hand).
5. Review: `bash tools/cross_review.sh <task> <brief> <base>` (reviewer = other family than the author, set in builders.conf); flags go to a file; confirm each against the code. When the file says the run goes to Claude (DeepSeek runs), launch the studio:review-code subagent (Agent tool, effort xhigh) on the diff instead.
6. Merge one part at a time: `python tools/parts_plan.py --branches oc/a oc/b`, then `bash tools/merge_run.sh <task>` (prefix and VERDICT PASS come from the .result), regenerate MAP and DOCMAP on a conflict (generated files only), `bash tools/check.sh` to a file, read its last line BEFORE any push.
7. Kaizen: `python tools/kaizen_report.py` (20 lines from runs.csv: pass rate, minutes, idle, tokens, cost per worker/effort, `tune:` hints), then one line in changelog.md.

## Hard rules
- The head reads at most the 15-line reports, the locked tests in full, and risky hunks (hooks, gates, pipeline, saves) line by line. Redirect every long command to a file and read an offset or `tail -n 15`.
- Never edit a tool a live run executes (bash reads scripts as they run): `bash tools/slots.sh` shows 0 runs first.
- A red test lives on its own part's base branch, never on a base shared with siblings (base_red refuses it).
- Stuck twice on one step: ask Feras (AskUserQuestion, with a pick); `/advisor` only with his OK (CLAUDE.md duty 6).
- A result's first word decides: PASS, FAIL, NOWORK, BREACH, ERROR (SCOPED/REJECT for a scope run). stdout of opencode proves nothing.
- Unknown cost is `?`, never 0. Read runs.csv, not memory.
