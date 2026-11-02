---
name: low-cost-pipeline
description: The whole build workflow of this repo in one folder: a Claude head (Opus or Sonnet, high) plans and decides, cheap workers (DeepSeek V4.1 Flash, GLM-5.3, agy gemini-3.8-flash) write tests and code in parallel, scripts report back in 15 lines. Use when a chat must plan a batch, delegate, build, review, merge or resume a pipeline task.
---
# Low-cost pipeline (Feras 11-01, v2 11-02): one folder owns the workflow
The head is any Claude chat at high effort (`claude --model opusplan`: Opus plans, Sonnet high executes). The head decides and
adjudicates; cheap workers do the bulk; every other stage is a script. Claude tokens are the scarce thing, neurons are not.
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
- Same model may run several times at once (caps in tools/builders.conf, per builder family); parallel parts cost neurons, not Claude tokens.
- Pick each part's worker from routing.md; pre-mortem in three lines; no open design questions in a brief.

## Flow of one part
1. Brief from the right template (templates/); the DeepSeek-max critic reads spec and brief into a file; the head fixes the real gaps. The critic is a different family than the test writer.
2. Scope: `EXPECT_RED=1 RUN_KIND=py bash tools/cf_build.sh <task>-tests <brief> <base> <GLM or DeepSeek model>` (FIX_PASSES=0). Result SCOPED or REJECT. The head READS EVERY TEST (weak tests are the usual defect), edits or rejects, then `bash tools/lock_tests.sh <task>-tests <task>-base` (the tests branch becomes the hand's base; the gate protects them).
3. Build: `RUN_KIND=py bash tools/cf_build.sh <task> <brief> <task>-base [model]` (agy: `bash tools/build_pipeline.sh agy ...`), run_in_background. Never pass a base holding another part's red test.
4. Read `python tools/part_report.py <task>`: PASS -> review; FAIL/NOWORK/ERROR -> read the one named reason; BREACH -> read the breach (usually a fixture edit the brief missed: review the diff, merge by hand).
5. Review: `bash tools/cross_review.sh <task> <brief> <base>` (reviewer = other family than the author, set in builders.conf); flags go to a file; confirm each against the code.
6. Merge one part at a time: `python tools/parts_plan.py --branches oc/a oc/b`, then `bash tools/merge_run.sh <task>` (prefix and VERDICT PASS come from the .result), regenerate MAP and DOCMAP on a conflict (generated files only), `bash tools/check.sh` to a file, read its last line BEFORE any push.
7. Kaizen: one line in changelog.md (what to cut or tune), from runs.csv.

## Hard rules
- The head reads at most the 15-line reports, the locked tests in full, and risky hunks (hooks, gates, pipeline, saves) line by line. Redirect every long command to a file and read an offset or `tail -n 15`.
- Never edit a tool a live run executes (bash reads scripts as they run): `bash tools/slots.sh` shows 0 runs first.
- A red test lives on its own part's base branch, never on a base shared with siblings (base_red refuses it).
- Stuck twice on one step: ask Feras (AskUserQuestion, with a pick); `/advisor` only with his OK (CLAUDE.md duty 6).
- A result's first word decides: PASS, FAIL, NOWORK, BREACH, ERROR (SCOPED/REJECT for a scope run). stdout of opencode proves nothing.
- Unknown cost is `?`, never 0. Read runs.csv, not memory.
