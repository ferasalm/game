# Row 26 optional final review: low-cost pipeline v2 (Opus high, one chat)
Type `/model opus`, `/effort high`, then paste: `Row 26 review, Ops, Opus high: read docs/opus-review-row26.md first and do what it says.`
Feras asked for this as an OPTIONAL last look (11-02). The build and its proof ran in a Sonnet-high chat. Do not redo the work: look for what a second Claude would catch.

## Read first (in this order, small excerpts)
1. `.claude/skills/low-cost-pipeline/SKILL.md`, then its changelog.md and proof.md (what is claimed, what is measured).
2. `docs/briefs/row26-pipeline-v2-plan.md` (the plan, the verdicts on the three critiques in `docs/research/pipeline-v2/`, Feras's ideas and decisions).
3. `docs/runs.csv` (the last 30 rows: real tokens, usd_est, idle_min) and `python tools/part_report.py <task>` for any run you doubt.

## Review, tiered (cheapest first)
1. Gates: `bash tools/check.sh` to a file, read the last line. `python tools/test_pipeline_skill.py` (the stale-line guard).
2. Risky hunks line by line (hooks, gates, pipeline, saves are Opus's): `tools/build_pipeline.sh`, `tools/run_state.sh`, `tools/merge_run.sh`, `tools/scope_gate.py`, `tools/lock_tests.sh`, `tools/cross_review.sh` (git log on the row 26 merge commits shows each).
3. Test quality: read the locked tests of the steps (`tools/test_run_state.py`, `test_routing.py`, `test_scope_stage.py`, `test_oc_usage.py`, `test_runs_log.py`, `test_part_report.py`, `test_parts_plan.py`, `test_ripple.py`): lenient asserts, tests that pass on the base, timing bounds.
4. Contradictions: grep for stale lines after the move (`Who does what` outside routing.md, "never a Sonnet subagent", "builders skill, The loop"), and that CLAUDE.md, HANDOFF.md, DECISIONS and the skill agree.
5. The proof: do the P0-P6 results in changelog.md and runs.csv really show cost, no idle > 6 min, a seeded defect caught? Anything claimed "proven" without a row is not proven.

## Open questions worth your judgment
- Is QUIET_SEC 300 right (a slow thinker after a commit)? Is the A/B result (DeepSeek vs GLM as test writer) enough to keep GLM as the default middle tier?
- Are the model-personality routes (routing.md) supported by runs.csv yet, or only by Feras's reading? Say which.
- CAP_CF was raised to 3 by Feras (11-02): does the proof show memory headroom and no rate-limit errors? Should CAP_AGY rise?

## Output
Findings ranked, each with file:line and the smallest fix; apply the clear ones on a branch, the rest as HANDOFF Open points. End with one line in docs/decisions-log.md: signed off, or what stays open. Feras's decisions (the diagram, scripts as foremen, Sonnet subagents allowed, neurons over tokens, one skill folder) are not re-argued; critique how they are built.
