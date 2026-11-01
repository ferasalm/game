# Brief: check-parallel
You are in your own worktree on branch gemini/check-parallel (made from origin/main). Follow GEMINI.md, including
<review_misses>. Load the minimal-change-engineer skill (Ops has no research persona; our rules outrank its text).
Pattern: tools/check.sh, tools/test_kill_tree.py
Timebox: 40 min. First commit within 15 min, then small WIP commits: no commit for 25 min (IDLE_MIN) = NOWORK.

## Why
Feras 10-31: check.sh takes too long. Measured: ~14 min, of which 11-12 min is Python tool tests run one at a time, 484 s in
test_build_pipeline.py and 143 s in test_py_runs.py, on an 8-core PC. Pillar served (docs/VISION.md): combat feel wins ties
(a shorter check means more fix rounds on M1).

## Read first
tools/check.sh, the last 6 lines of tools/test_build_pipeline.py and tools/test_py_runs.py, check_toy() in tools/test_py_runs.py.

## What to build
1. New tools/tool_tests.py, standard library only, <= 120 lines, a `#!/usr/bin/env python3` line, a one-line purpose docstring:
   - `workers()` -> int: env `TEST_WORKERS` when set, else `min(4, os.cpu_count() or 1)`.
   - `run_cases(tests, label, jobs=None)`: runs a list of test functions in a ThreadPoolExecutor of `jobs or workers()`. Every
     test runs even when another fails. Each failure prints `FAIL <function name>` and its traceback. All passed: prints
     `<label>: <n> tests passed` and returns. Any failure: `sys.exit(1)`.
   - `find_tests(root="tools")` -> sorted list of every test_*.py under root, forward slashes, as `find tools -name 'test_*.py' | sort` gives.
   - `run_files(paths, log_dir, serial=(), jobs=None)` -> list of `(path, returncode, seconds)`: each path runs as
     `sys.executable path` with stdin DEVNULL, stdout and stderr to `<log_dir>/tool_<path with / as _>.log`. Paths not in `serial`
     run side by side in `jobs or workers()` threads; then each path in `serial` runs alone, one after another, because each holds its
     own pool. Result order = input order.
   - `main()`: `SERIAL = ("tools/test_build_pipeline.py", "tools/test_py_runs.py")`; runs find_tests() into `.check`; for each failed
     path prints `--- <path>`, the last 8 lines of its log, then, after all of them, one `FAIL tool test: <path>` line each; prints
     `slowest: <n> s <path>` for the 3 slowest; returns 1 on any failure, else 0.
2. tools/test_build_pipeline.py and tools/test_py_runs.py: only the `__main__` block changes: same `tests = ...` line, then
   `run_cases(tests, "<file name without .py>")`, importing it there from tool_tests. No test body, helper or time limit changes.
3. tools/check.sh:
   - `step()` prints the seconds a step took: `ok   docs (1 s)` and `FAIL docs (12 s) (.check/docs.log)`, with bash `$SECONDS`.
   - The `tool_tests()` function becomes: run `$py tools/tool_tests.py`, then `$py tools/oc_agents.py --check`; both always
     run, and it returns non-zero when either fails. Its comment line says this.
4. tools/test_py_runs.py check_toy(): add `tool_tests.py` to the list of stub Python checks, so its toy keeps working.
5. `git add` the new files, then `python tools/map.py`, before your first check.

## Do NOT edit
D6 defaults, protected by tools/build_gate.py without being listed: existing tests, tools/, .github/ (edits and
deletions; new test files are allowed) and every change under assets/ (incl. *.import). Keep this prose free of
backticks: every backticked token in this section is a forbidden path, and May edit does not lift it.
`content/`
`features/`
`core/`
`tools/build_pipeline.sh`
`tools/lib.sh`
`.github/`

## May edit
`tools/check.sh`
`tools/tool_tests.py`
`tools/test_build_pipeline.py`
`tools/test_py_runs.py`
`docs/MAP.md`

## Ripple
check.sh is called by build_pipeline.sh, merge_run.sh and CI (Linux, `python3`: keep `$py`). `ok   <name>` must still start each
passing line (test_py_runs greps it) and `all checks passed` stays the last line. Log names stay `.check/tool_<path>.log`.
test_py_runs imports helpers from test_build_pipeline: importing it must not run anything. A new test file is still picked up by itself.

## Pre-mortem
A failing thread reads as a pass: test it, a raised AssertionError must give exit 1 and name the test. Toy tests with wall-clock limits
(`< 40` s) flake under load: no limit may be raised; Claude runs both files 3 times before merging. Two test files that share a
path clash when run side by side: if you see one, put it in SERIAL and say so in your final message; never loosen a test.

## Tests
New file tools/test_tool_tests.py, same runner block as tools/test_kill_tree.py, no network, no Godot, under 10 s. One test per rule:
run_cases with three tests, the middle one failing: all three ran, exit 1, `FAIL` and the name in the output; run_cases all
passing prints `demo: 3 tests passed`; two tests that each sleep 1 s finish in under 1.8 s with jobs=2; workers() reads TEST_WORKERS;
find_tests finds a nested test file in a temp folder and skips other files; run_files writes each log and returns the returncodes in
input order; a serial path never overlaps a side-by-side one (each appends start and end stamps to a temp file).

## Checklist
- file: tools/tool_tests.py
- has: tools/tool_tests.py :: def run_cases
- has: tools/tool_tests.py :: def run_files
- has: tools/check.sh :: tools/tool_tests.py
- test: tools/test_tool_tests.py :: test_run_cases_runs_every_test_and_exits_1_on_a_failure

## Proof
`bash tools/check.sh --no-godot` raw last 15 lines, with the seconds per step; final message ends with
`Built-by: Gemini 3.8 Flash (agy)`.
