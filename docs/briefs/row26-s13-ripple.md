# Brief: row26-s13-ripple (cf DeepSeek high; Python only, RUN_KIND=py)
You are in your own worktree on branch oc/row26-s13-ripple (made from origin/row26-s13-base; the base is pushed). Follow GEMINI.md, including
<review_misses>. Load the builders skill.
Pattern: tools/part_report.py, tools/oc_usage.py
Timebox: 30 min (<= 45). First commit within 15 min, then small WIP commits.

## Why
Feras 11-02: two builder runs ended BREACH because the brief missed existing tests the change forces (a test pinning the runs.csv header; three tests building merge_run fixtures). The head needs the list of those tests BEFORE launch, to put their unavoidable edits in May edit. Pillar served: none directly (fewer wasted runs).

## Read first
tools/test_ripple.py (the red tests, read-only: they define the output), tools/part_report.py (house style and how a brief section is read), tools/build_gate.py section_paths (reuse the backticked-path parsing).

## What to build
`tools/ripple.py BRIEF [--root DIR]` (<= 100 lines, functions <= 40 lines, docstring first; default root = the current checkout's top level):
1. Read the brief's `## May edit` paths (backticked; `none` or none listed = nothing to scan) and the test paths in its `## Tests` section (the locked ones, skipped in the result).
2. Existing test files = every `test_*.py` under tools/ and tests/ and every `test_*.gd` under tests/ and features/, found by walking the root (skip .git, .godot, .check, .claude/worktrees, docs/archive).
3. A test file is listed when its text contains an edited file's full repo path, or its basename, as a whole token (the characters before and after are not letters, digits, `_`, `-` or `.`): `a.py` matches `'a.py'` and `tools/a.py` but not `metadata.py` or `a.py_helpers`. Never list the edited file itself or a locked test.
4. Print `RIPPLE <n> test file(s) name the files this brief edits:` then one line per test, sorted, `  <path>  (names <edited basenames, comma separated>)`, at most 20 lines, then `  ... and <k> more` when longer. No test: print only `RIPPLE 0`. Exit 0 always (information, not a gate).
Pass paths as arguments, never through a shell string; read files with errors="replace".

## Do NOT edit
D6 defaults, protected by tools/build_gate.py without being listed. Keep this prose free of backticks outside May edit.

## May edit
none

## Ripple
none: a new stand-alone tool; the skill and the head call it. docs/MAP.md and DOCMAP.md refresh themselves.

## Pre-mortem
- A huge or binary file in tests/: read with errors="replace" and skip files over 1 MB.
- Windows path separators in the output: print forward slashes.
- Matching the basename of a very common file (README.md) lists half the tests: acceptable, the cap and the sort keep it short.

## Tests
- tools/test_ripple.py :: every test (red on the base)

## Checklist
- file: tools/ripple.py
- test: tools/test_ripple.py :: test_a_test_that_names_an_edited_file_is_listed_with_that_file

## Proof
`bash tools/check.sh --no-godot` raw last 15 lines; final message ends with `Built-by: DeepSeek V4.1 Flash high (opencode)`.
