# Brief: agy-py-lane (HANDOFF row 12, part C)
You are in your own worktree on branch gemini/agy-py-lane (made from origin/claude/trusting-chatelet-141211). Follow GEMINI.md, including
<review_misses>. Load the minimal-change-engineer skill (build_pipeline.sh pastes it; our rules outrank its text).
Timebox: 45 min. First commit within 15 min, then small WIP commits: no commit for 25 min (IDLE_MIN) = NOWORK.

## Why
Feras 10-28: agy's lane widens to Python tools, docs and reviews. A Python-only builder run must take its builder's
slot but none of the 2 Godot slots, and run no Godot at all. Pillar: process (M1 keeps its Godot slots).

## Read first
tools/slots.sh (the RUNNING loop, can-start), tools/build_pipeline.sh (status_line, check, import_wt, the gate call,
the final .result), tools/check.sh, tools/build_gate.py (run_gate, verdict, main), tools/merge_run.sh, and the tests
to make green: tools/test_py_runs.py. Read nothing else.

## What to build
1. tools/build_pipeline.sh: env RUN_KIND = godot (default) or py; any other value refuses (exit 3) like the other
   refusals. Every .result it writes (status_line and the final one) gets a line `kind <RUN_KIND>` right after the
   pid line. Call `slots.sh can-start "$builder" "$RUN_KIND"`. For py: skip import_wt, run
   `bash tools/check.sh --no-godot`, pass `--kind "$RUN_KIND"` to `build_gate.py gate` (godot runs pass it too).
2. tools/slots.sh: read each RUNNING result's `kind` line (missing = godot; oc runs are never Godot). The agy, cf and
   oc counts count every run; count_godot counts only agy and cf runs of kind godot. `can-start <agy|cf|oc> [godot|py]`
   (default godot): agy and cf first check their own cap, refusing with `REFUSED: agy N/CAP` (or `cf`); a godot run
   then checks CAP_GODOT and the memory floor as now; a py run checks neither. oc is unchanged.
3. tools/check.sh: `--no-godot` runs docs, lint, res_graph, tool_tests and repo_untouched only (no import, no check
   slot, no tests, no boot) and prints `     no Godot: import, tests and boot skipped (--no-godot)` before the final
   line; the final line stays `all checks passed` or `N check(s) FAILED`. Without the flag nothing changes.
4. tools/build_gate.py: `gate --kind godot|py` (default godot). For py, each changed file Godot loads adds one line
   `py run changed a Godot file: <path>` and the verdict is FAIL (not BREACH): *.gd, *.tscn, *.tres, *.gdshader,
   *.import, project.godot, and anything under assets/, content/, localization/, features/, core/, scenes/, tests/.
   Use the changed-file list run_gate already builds.
5. tools/merge_run.sh: a .result with the line `kind py` never takes the fast-forward reuse: it merges and runs the
   full tools/check.sh.

## Do NOT edit
D6 defaults, protected by tools/build_gate.py without being listed: existing tests, tools/, .github/ (edits and
deletions; new test files are allowed) and every change under assets/ (incl. *.import). Keep this prose free of
backticks: every backticked token in this section is a forbidden path, and May edit does not lift it.
`tools/test_py_runs.py`
`docs/`
`.claude/`
`GEMINI.md`

## May edit
`tools/build_pipeline.sh`
`tools/slots.sh`
`tools/check.sh`
`tools/build_gate.py`
`tools/merge_run.sh`

## Ripple
- slots.sh's "agy N/CAP ..." and "godot N/CAP free ..." lines are read by tools/status.sh and test_slots.py: same format.
- .result lines (first word, builder, pid, checked) are read by slots.sh, status.sh, merge_run.sh: add kind, change none.
- check.sh with no flag runs in CI and every chat: identical behaviour. cf_build.sh passes RUN_KIND through the env.

## Pre-mortem
1. Old .result files have no kind line; read as py they would free a busy Godot slot -> missing = godot (tested).
2. --no-godot still imports or takes a check slot -> test_check_no_godot_runs_no_godot.
3. A py run edits a .gd and skips the Godot tests -> the gate fails it and merge_run reruns the full check (tested).

## Tests
tools/test_py_runs.py, red on the base, read-only: `python tools/test_py_runs.py` must print "test_py_runs: 7 tests
passed"; tools/test_slots.py, test_build_pipeline.py and test_build_gate.py stay green. Player-visible: none (tools).

## Checklist
- has: tools/slots.sh :: can-start
- has: tools/check.sh :: --no-godot
- has: tools/build_gate.py :: --kind
- has: tools/build_pipeline.sh :: RUN_KIND
- has: tools/merge_run.sh :: kind py

## Proof
`bash tools/check.sh` raw last 15 lines; final message ends with `Built-by: Gemini 3.8 Flash (agy)`.
