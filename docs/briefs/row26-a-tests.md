# Brief: row26-a-tests (SCOPE RUN: GLM-5.3 max writes ONLY the red tests; RUN_KIND=py)
You are in your own worktree on branch oc/row26-a-tests (made from origin/worktree-row26-pipeline-v2; the base is pushed). Follow GEMINI.md, including
<review_misses>. Load the builders skill.
Pattern: tools/test_build_pipeline.py
Timebox: 40 min. First commit within 15 min, then small WIP commits.

## Why
Feras 11-02: tools/build_pipeline.sh will be changed by docs/briefs/row26-a-runstate.md (read it fully: its "What to build" items 1-8 are the spec). This run writes ONLY the failing tests for that spec. A different model implements them next, and cannot edit them. Weak or lenient tests are the usual defect: assert exact outputs, never `is not None` or "ran without error".

## Read first
docs/briefs/row26-a-runstate.md, tools/build_pipeline.sh, tools/test_build_pipeline.py (reuse its helpers `toy`, `pipeline`, `result`, `put`, `sh`, `git`, `child_env` by importing them from test_build_pipeline; do not copy-paste them), tools/oc_usage.py, tools/model_effort.py, tools/runs_log.py, tools/builders.conf.

## What to build
ONE new file `tools/test_run_state.py` (<= 200 lines, functions <= 40 lines), plain `test_*` functions, ending with the `run_cases` block used by tools/test_runs_log.py. Stub builders and gates only (BUILDER_CMD; no network, no opencode). One test per rule, named for the rule:
1. `test_a_crashing_gate_is_error_not_fail`: a toy whose gate crashes (e.g. the brief is deleted by the stub builder AFTER launch must NOT crash it, see 2; so crash the gate another way: make `tools/build_gate.py` in the toy raise) -> first word ERROR, a `gate error:` line, exit != 0.
2. `test_the_brief_is_copied_at_launch`: the stub builder deletes the original brief; the run still ends PASS and `<wt_dir>/<task>.brief.md` exists.
3. `test_a_refused_launch_removes_the_old_pass_result`: a stale PASS `.result` for the task, then a launch that is refused (slots full): afterwards no `.result` file.
4. `test_fix_passes_count_the_passes_that_ran`: FIX_PASSES=2 and a check that never passes -> the runs.csv row says fix_passes 2.
5. `test_result_header_has_model_and_idle_min`: PASS run -> `model <id>` and `idle_min 0` lines, and `builder`, `pid`, `kind` still present.
6. `test_a_builder_that_commits_then_hangs_is_quiet_killed_early`: QUIET_SEC=3, IDLE_SEC=600; the stub commits then sleeps 60 s with no output -> the run ends in under 40 s, the commit is gated, note line starts `quiet:`, `idle_min` line exists.
7. `test_a_builder_that_keeps_logging_is_not_quiet_killed`: QUIET_SEC=3; the stub commits, then prints a line every second for 8 s, then finishes -> no `quiet:` note.
8. `test_a_builder_with_no_commit_still_gets_the_idle_rule`: IDLE_SEC=4, QUIET_SEC=2, the stub never commits -> NOWORK.
9. `test_opencode_free_models_are_refused`: builder oc with model `opencode/deepseek-v4.1-flash-free` -> exit 3 and a REFUSED line naming cf_build.sh; with OC_ALLOW_FREE=1 it is not refused for that reason.
10. `test_every_end_path_appends_one_runs_csv_row`: PASS, FAIL, NOWORK and REFUSED runs each add exactly one row (set the file with RUNS_CSV or the repo's docs/runs.csv in the toy, whichever runs_log's default resolves to there), with the matching gate word, `?` tokens and source `unknown` when no opencode session exists.
11. `test_append_spend_prefers_the_sessions_of_a_worktree`: call `bash tools/slots.sh append-spend LOG task 0.30 1.20 CSV WT` with a stub OC_BIN that lists/exports one session of 1000 in / 200 out -> the csv line is `<date>,task,1000,200,0.00` (usd 0.00054 rounds to 0.00 at two decimals; assert the first four fields exactly); with no WT the old log parsing result (`?`) is unchanged.

## Do NOT edit
D6 defaults, protected by tools/build_gate.py without being listed. Keep this prose free of backticks outside May edit. Write NO product code: not build_pipeline.sh, not any tool.

## May edit
none

## Ripple
none: tests only. They are red on the base because the spec is unbuilt; do not run check.sh to turn them green.

## Pre-mortem
- A test passes on the base (proves nothing): run each with `python tools/test_run_state.py` once and confirm it fails for the stated reason before committing.
- Timing tests flake under load: use the generous bounds above, never tighten them.
- A test hits the real opencode or the network: stubs only.

## Tests
- tools/test_run_state.py :: every test (red on the base)

## Checklist
- file: tools/test_run_state.py

## Proof
Print the last 15 lines of `python tools/test_run_state.py` (expect FAIL lines); final message ends with `Built-by: GLM-5.3 max (opencode)`.
