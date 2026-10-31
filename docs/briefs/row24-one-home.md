# Row 24: one home, tidy, integrity audit (chat brief; rules and the one-home map: docs/briefs/system-v3.md)
Department: Ops. Model: Sonnet high, auto mode. Skills: builders. Persona: none.
Goal: every rule has one home, the repo holds only what is live, and we know the state of the game code before M1.
Read: docs/briefs/system-v3.md, this file, the builders skill. Grep for the rest.
May edit: `docs/`, `CLAUDE.md`, `plugins/`, `tools/`, `HANDOFF.md`.
Do NOT edit: `features/`, `core/`, `content/`, `assets/`, `.agents/skills/`, `.claude/rules/code.md`. No game code changes in this row. Never reword docs/decisions-log.md or decisions lines; never add a rule while moving one.

## Parts (a, b and c run side by side, one builder each)
a. agy docs run (`RUN_KIND=py`): apply the one-home map. WORKFLOW to 14 KB or less: step 3, Model routing on Pro and Builder loop become pointers to the builders skill; keep Routing (doc_check reads it), Protocols: Review and Limits. models.md drops its Routing table, keeps the evidence. HOW_WE_WORK: diagram v3 (Sonnet executes, Opus plans and gates, two plugins, the row flow). Add one doc_check line that fails on a second worker routing table, with a test you write first.
b. cf fast: archive finished briefs to `docs/archive/briefs/` (keep TEMPLATE, live briefs, anything a tool reads) and old audits to `docs/archive/audits/`; fix references.
c. agy read-only audit, `docs/audits/2026-11-02-integrity.md`, no code changes: dead scenes and scripts (tools/res_graph.py), exactly what row 4 archives from the turn-based battle, files past the code rules, numbers in code that belong in content JSON, player text outside TextDB, tests that only check a mock. Each finding: file, line, evidence.
d. Digest of c, made twice, 30 lines or fewer: Haiku medium (Agent tool) and GLM-5.3-flash (cf_probe.py). You confirm the top 10 items by grep and score both. Record in models.md. That is the calibration of Haiku medium as a reader and of GLM for bulk text: GLM needs 8 of 10 right, else it stays off and the builders table says so. Real findings become input lines for row 3, not fixes here.
e. agy: dead tools removed only with zero references, proven by grep (candidates: tools/agy_review.sh, tools/musnad.py, tools/smoke_keeper.*). Row 20's leftovers: session_stats dates by entry and tighter guard regex; builders/lessons.md to 40 lines; Gameplay lessons.md + research-queue.md; doc_check warns on bytes; frame_score blank-line slot.
f. You: the HANDOFF cleanup Open point (empty row18-routing folder, b5_tests.log, base-xr-salvage, merged remote branches). Look at each target first. The worktree guard refuses some of it: one PowerShell call from C:\dev\game. Show Feras the branch list if anything looks unmerged.

## Stop rules
Late: e's row 20 items, then tidy b, park first; a and c never. Auto mode refuses a change: stop, ask Feras with the exact diff. Same step failed twice: call the advisor. 3 rounds: report. Budget: 80 main-chat calls.

## Done when
`bash tools/check.sh` all passed and read; WORKFLOW <= 14 KB; one worker routing table; the audit and the calibration recorded; Open point closed or carried; pushed to `system-v3`.

## Report
15 lines or fewer: parts with status, runs with their one-line results, calibration scores, top audit findings, questions for Feras. No merge to main, no sync; row 24 done, row 25 next; the next prompt ready to paste, naming Opus high.
