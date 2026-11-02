# Brief: row26-a-runstate (cf DeepSeek max; Python and shell, RUN_KIND=py)
You are in your own worktree on branch oc/row26-a-runstate (made from origin/worktree-row26-pipeline-v2; the base is pushed). Follow GEMINI.md, including
<review_misses>. Load the builders skill.
Pattern: tools/build_pipeline.sh, tools/test_build_pipeline.py
Timebox: 45 min. First commit within 15 min, then small WIP commits.

## Why
Feras 11-02: the low-cost pipeline records wrong things. Verified causes (docs/briefs/row26-pipeline-v2-plan.md): a crashed gate is logged FAIL, the brief is read from a mutable path 30 min after launch (row25-sync-dirty), an old PASS `.result` survives a refused launch, fix_passes reads 3 with FIX_PASSES=2, NOWORK/REFUSED/ERROR runs never reach docs/runs.csv, cost is hard-coded 0, and a builder that hangs after its last commit costs the full IDLE_MIN (row25-base-red: 25 of 31 min). Pillar served: none directly (a system that tells the truth).

## Read first
tools/build_pipeline.sh (all 175 lines), tools/test_build_pipeline.py (stubs via BUILDER_CMD; do not edit), tools/builders.conf, tools/oc_usage.py and tools/model_effort.py and tools/runs_log.py (already on the base: use them, do not change them), tools/slots.sh lines 1-50 (append-spend), tools/cf_build.sh, tools/test_run_state.py (the red tests: read-only).

## What to build
1. tools/build_pipeline.sh, right after the arguments: `rm -f "$res"`; copy the brief to `$dir/$name.brief.md` and use THAT copy for base_red.py, the prompt and build_gate.py (the original may vanish).
2. A gate output with no `VERDICT` line is word ERROR (not FAIL): the `.result` gets `ERROR HH:MM prefix/name`, a line `gate error: <last non-empty line of the gate output>`, the usual header lines, exit 1.
3. `.result` header gains `model <model id used for the build, or the builders.conf default for the builder>` and `idle_min <N>` lines (N = whole minutes lost to the idle or quiet kill, 0 when none).
4. fix_passes counts passes that ran: with FIX_PASSES=2 and a check that never passes it logs 2, never 3.
5. Quiet watchdog (QUIET_SEC, builders.conf, default 300; tests set a few seconds): in run()'s poll loop, once the worktree has >= 1 commit beyond the base, kill the builder tree when its log file has not grown for QUIET_SEC; note `quiet: <step> killed after <N>s without log output; its commits were checked` and go on to the check. A builder with no commit still gets the IDLE_MIN rule. A builder whose log keeps growing is never quiet-killed.
6. Refuse `opencode/*-free` as the model of an oc builder unless OC_ALLOW_FREE=1: `REFUSED: opencode/...-free routes are spent; use tools/cf_build.sh (or OC_ALLOW_FREE=1)`.
7. Every end path (PASS, FAIL, BREACH, ERROR, NOWORK, REFUSED) appends ONE docs/runs.csv row through `$py tools/runs_log.py append` (not `python`; no `|| true` that hides a failing call: print a WARN line instead): effort from `$py tools/model_effort.py "$eff_m"`; for builders cf and oc the tokens come from `$py tools/oc_usage.py collect --wt "$wt"` piped into `fields --in-rate $CF_INPUT_RATE --out-rate $CF_OUTPUT_RATE` (source `opencode-export`); agy and any run with 0 sessions log `?,?,?` and source `unknown`; --idle-min from item 3. REFUSED rows use minutes 0 and `?` tokens.
8. tools/cf_build.sh appends NO spend line when the pipeline exits 3 (REFUSED: it appended a junk `?` line). tools/slots.sh append-spend takes an optional 7th argument WT: when given and `oc_usage.py collect --wt WT` finds sessions, the csv line is `date,task,in,out,usd` from those numbers; otherwise the old log parsing runs unchanged. tools/cf_build.sh passes `"$wt"` (`$dir/$task`).

9. A builder that never started (oc_task.sh refused: a leftover worktree from another base, a missing opencode, exit 126) is NOWORK with the first stderr or log line as its reason (`why: <line>`), never the bare "CHECKLIST missing"; and a NOWORK or REFUSED run removes its own empty worktree and branch so a rerun with a new base starts clean (test: a leftover worktree on an older base, relaunch -> a clear reason, then a clean rerun). I write this test myself after reading the GLM tests.

## Do NOT edit
D6 defaults, protected by tools/build_gate.py without being listed. Keep this prose free of backticks outside May edit.
`tools/test_build_pipeline.py`
`tools/test_slots.py`
`tools/oc_usage.py`
`tools/model_effort.py`
`tools/runs_log.py`

## May edit
`tools/build_pipeline.sh`
`tools/builders.conf`
`tools/slots.sh`
`tools/cf_build.sh`

## Ripple
merge_run.sh and cross_review.sh read the `.result` header: only lines are added, none renamed (a later brief reads `model`). tools/test_build_pipeline.py and test_slots.py must stay green untouched. The old append-spend path stays for callers without the 7th argument (cross_review.sh until its brief). Never edit build_pipeline.sh while a live run uses it (LESSONS 3): none is running when this merges.

## Pre-mortem
- A new line in `.result` breaks a reader: slots.sh reads `builder`, `pid`, `kind` by name; keep them in place.
- The quiet watchdog kills a slow thinking model that is still working: it needs a commit first and the kill still gates the commits; QUIET_SEC is a builders.conf knob.
- oc_usage collect hangs: it has its own 60 s timeouts and exits 0; the pipeline runs it after the gate, never before.

## Tests
- tools/test_run_state.py :: every test (red on the base)

## Checklist
- file: tools/build_pipeline.sh
- test: tools/test_run_state.py :: test_a_crashing_gate_is_error_not_fail

## Proof
`bash tools/check.sh --no-godot` raw last 15 lines; final message ends with `Built-by: DeepSeek V4.1 Flash max (opencode)`.
