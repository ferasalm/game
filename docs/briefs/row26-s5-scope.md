# Brief: row26-s5-scope (cf DeepSeek max; shell and Python, RUN_KIND=py)
You are in your own worktree on branch oc/row26-s5-scope (made from origin/row26-s5-base; the base is pushed). Follow GEMINI.md, including
<review_misses>. Load the builders skill.
Pattern: tools/build_gate.py, tools/run_state.sh
Timebox: 45 min. First commit within 15 min, then small WIP commits.

## Why
Feras 11-02: the test-first stage (GLM max writes the red tests, the head reads and locks them, DeepSeek builds against them) was run by hand five times today: a hand-built branch, a regenerated MAP and DOCMAP, a push. Tools make it repeatable and measurable. Pillar served: none directly (a trustworthy build system).

## Read first
tools/test_scope_stage.py (the red tests, read-only: they define every contract), tools/build_gate.py (reuse runnable_new_tests, new_tests_on_base, is_test, change_status; import them, do not copy), tools/build_pipeline.sh and tools/run_state.sh (the run_state helpers: result_head, log_row, leftovers), tools/builders.conf.

## What to build
1. `tools/scope_gate.py check --wt DIR --base REF --brief FILE` (<= 120 lines, functions <= 40 lines): changed files are base...HEAD of DIR. Print a checklist and a last line `VERDICT SCOPED` (exit 0) or `VERDICT REJECT` (exit 1). REJECT, naming the path, when: a file other than a test file (is_test) or a generated doc (docs/MAP.md, docs/DOCMAP.md, *.uid) is added, changed or deleted (`product code in a test run: <path>`); an existing test file is modified or deleted; no test file was added (`no new test file`); a new py or gd test file passes on the base (`<path> passes on the base: it proves nothing`; reuse new_tests_on_base).
2. tools/build_pipeline.sh: with `EXPECT_RED=1`, after the build (and its leftovers commit) skip check, fix passes and build_gate: run scope_gate.py instead and write the result with `result_head`, the gate output and the commits, first word SCOPED or REJECT (the gate verdict), log the runs.csv row with that word, exit 0 only for SCOPED. A builder that never started still ends NOWORK as today. Nothing changes without EXPECT_RED.
3. `tools/lock_tests.sh SCOPE_TASK NEW_BASE_BRANCH` (cwd = the checkout; worktrees in wt_dir): refuse unless `<wt_dir>/<task>.result` starts with SCOPED (`needs a SCOPED result`); create NEW_BASE_BRANCH at oc/SCOPE_TASK's tip, run `python tools/map.py` and `python tools/doc_graph.py` in a temporary worktree of it when those tools exist there, commit the refreshed docs (message `locked tests: generated docs refreshed`), push the branch to origin, remove the temporary worktree, print `LOCKED <branch> <sha>`. Never touch the caller's checkout or branch.

## Do NOT edit
D6 defaults, protected by tools/build_gate.py without being listed. Keep this prose free of backticks outside May edit.
`tools/run_state.sh`
`tools/oc_usage.py`

## May edit
`tools/build_pipeline.sh`

## Ripple
build_pipeline.sh is run by every builder: the EXPECT_RED branch must be unreachable without the variable (tools/test_build_pipeline.py, test_run_state.py and test_py_runs.py must stay green untouched). Never edit build_pipeline.sh while a live run uses it: none is running when this merges. docs/MAP.md and DOCMAP.md refresh themselves.

## Pre-mortem
- EXPECT_RED leaks into a normal run and skips the check: it is read once, from the environment, and a test runs a normal PASS beside it.
- lock_tests.sh moves the caller's branch or leaves a temporary worktree: it works in a temporary worktree only and removes it, tested.
- A REJECT run is merged: merge_run needs PASS and `VERDICT PASS`, so SCOPED and REJECT can never merge.

## Tests
- tools/test_scope_stage.py :: every test (red on the base)

## Checklist
- file: tools/scope_gate.py
- file: tools/lock_tests.sh
- test: tools/test_scope_stage.py :: test_lock_tests_makes_the_hand_base_from_a_scoped_run

## Proof
`bash tools/check.sh --no-godot` raw last 15 lines; final message ends with `Built-by: DeepSeek V4.1 Flash max (opencode)`.
