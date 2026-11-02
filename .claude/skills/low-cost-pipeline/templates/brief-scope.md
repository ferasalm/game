# Brief: <task>-tests (SCOPE RUN: a worker writes ONLY the red tests; RUN_KIND=py)
You are in your own worktree on branch oc/<task>-tests (made from origin/<base>; the base is pushed). Follow GEMINI.md, including
<review_misses>. Load the builders skill.
Pattern: <the nearest existing test file, so the worker reuses its helpers>
Timebox: 40 min. First commit within 15 min, then small WIP commits.

## Why
<the owner's words>. This run writes ONLY the failing tests for docs/briefs/<task>.md (read it fully: its What to build is the spec). A different model implements them next and cannot edit them. Weak tests are the usual defect: assert exact outputs, never "ran without error".

## Read first
docs/briefs/<task>.md, the files it changes, the Pattern file (import its helpers; do not copy-paste them).

## What to build
ONE new test file `tools/test_<x>.py` (<= 200 lines, functions <= 40 lines). One test per rule, named for the rule, stubs only (no network, no real opencode or gh). List each test and what it asserts, exactly.

## Do NOT edit
D6 defaults, protected by tools/build_gate.py without being listed. Write NO product code. Keep this prose free of backticks outside May edit.

## May edit
none

## Ripple
none: tests only. They are red on the base because the spec is unbuilt; do not run check.sh to turn them green.

## Pre-mortem
- A test passes on the base (proves nothing): run each once and confirm it fails for the stated reason before committing.
- Timing tests flake under load: generous bounds, never tightened later.

## Tests
- tools/test_<x>.py :: every test (red on the base)

## Checklist
- file: tools/test_<x>.py

## Proof
Last 15 lines of the test run (expect FAIL lines); final message ends with `Built-by: <model> (opencode)`.
