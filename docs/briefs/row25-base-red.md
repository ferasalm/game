# Brief: row25-base-red (pipeline run, cf DeepSeek high; fixes from the row 25 review lenses)
You are in your own worktree on branch oc/row25-base-red (made from origin/system-v4; the base is pushed). Follow GEMINI.md, including
<review_misses>. Load the builders skill.
Pattern: tools/base_red.py
Timebox: 25 min (<= 45). First commit within 15 min, then small WIP commits.

## Why
Three reviewers found real gaps in `tools/base_red.py` (the launch guard that refuses a base holding a foreign red tool test): it matches a test by file name only, so a brief naming `tools/a/test_x.py` wrongly excuses a red `tools/b/test_x.py`; it has no end boundary, so `test_a.py.bak` excuses `test_a.py`; and a run killed by `timeout` leaves its throwaway worktree registered forever. Pillar served: none directly (tooling that keeps parallel builder runs honest).

## Read first
tools/base_red.py (63 lines) and tools/test_base_red.py (the new tests are red on the base).

## What to build
1. `foreign()`: a failing test counts as named when the Tests section holds its full repo path (the path is not preceded by a path character or a word character or `-`), or, when the section names the file only by a bare name (no directory before it), by basename. A directory in the section that differs from the failing test's directory does not excuse it.
2. End boundary: a name followed by a word character, `-`, or `.` plus a word character (`.bak`, `.py.orig`) does not count; a name followed by a sentence period, comma, space, `)`, backtick or end of line does.
3. Stale cleanup: at the start of `main()`, remove every worktree registered in this repo whose path lies in a `base_red*` directory under `tempfile.gettempdir()` and whose directory is older than 30 minutes (a live run lasts at most BASE_RED_SEC = 600 s, so a fresher one belongs to a concurrent launch and stays); use `git worktree remove --force`, then `shutil.rmtree(..., ignore_errors=True)` on that `base_red*` directory, then `git worktree prune`. Read `git worktree list --porcelain`. A fault here must not fail the run.
4. Keep the file at <= 200 lines, every function <= 40 lines, and the docstring true (add one line on the stale cleanup).

## Do NOT edit
Existing tests and tools/test_base_red.py (locked red tests).

## May edit
`tools/base_red.py`

## Ripple
`tools/build_pipeline.sh` calls base_red.py with `<brief> <base>` and reads exits 0, 1, 2 (unchanged); `tools/test_build_pipeline.py` does not exercise base_red's matching. No other caller.

## Pre-mortem
- A real brief names its tests with a leading directory or bare names: both forms still claim (tests 1, 2 and the existing ones).
- Cleanup removes a live concurrent run: the 30-minute age rule and the fresh-worktree test stop it.
- A regex slip excuses nothing or everything: the four punctuation cases are in the tests.

## Tests
- tools/test_base_red.py :: test_a_brief_naming_another_directorys_test_claims_nothing (red on the base)
- tools/test_base_red.py :: test_a_longer_file_name_claims_nothing (red)
- tools/test_base_red.py :: test_a_worktree_left_by_a_killed_run_is_removed (red)
- tools/test_base_red.py :: test_a_bare_name_still_claims_by_basename and test_a_fresh_worktree_of_a_concurrent_run_stays (green before and after)
Player-visible: none (tool only).

## Checklist
- has: tools/base_red.py :: foreign

## Proof
`bash tools/check.sh --no-godot` raw last 15 lines; final message ends with `Built-by: DeepSeek V4.1 Flash high (opencode)`.
