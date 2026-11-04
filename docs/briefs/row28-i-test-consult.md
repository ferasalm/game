# Brief: row28-i-test-consult (agy; shell and Python, RUN_KIND=py)
You are in your own worktree on branch gemini/row28-i-test-consult (made from origin/main). Follow GEMINI.md, including
<review_misses>. Load the builders skill.
Pattern: tools/nv_audit.sh, tools/test_nv_audit.py
Timebox: 30 min (<= 45). First commit within 15 min, then small WIP commits.

## Why
Feras 11-04: the head writes the red tests and may consult agy, DeepSeek or GLM for test ideas in isolated one-shot chats; the implementing builder never sees them. Pillar served: combat feel wins ties (better tests of mechanics).

## Read first
tools/nv_audit.sh (a one-shot model call), tools/agy_task.sh, tools/test_nv_audit.py.

## What to build
1. `tools/consult_tests.sh <part-spec-file> [model]` (default agy gemini-3.8-flash-high): sends only the spec file plus the line "List edge cases and failing-test ideas, one per line, no code" to a one-shot call with no repo context and no tools; prints the ideas to stdout only.
2. It writes nothing under the repo, never into a brief or a builder prompt; with `--out` it writes only inside the scratchpad path given on the command line (refuses a path inside the repo).
3. Free providers only (tools/free_providers.txt applies); a paid model needs PAID_OK=1.
4. One paragraph in builders/SKILL.md: the head uses the ideas to write tests; the ideas file is never pasted to the builder.

## Do NOT edit
D6 defaults, protected by tools/build_gate.py without being listed. Keep this prose free of backticks outside May edit.

## May edit
`.claude/skills/builders/SKILL.md`

## Ripple
none beyond a new stand-alone tool; the builders skill paragraph is the only shared file.

## Pre-mortem
- Ideas leak into a builder prompt: build_pipeline.sh pastes only the brief, skills, patterns and code rules; a test greps the assembled prompt in SKIP_BUILD mode for a planted ideas marker.
- The call has repo context: the test runs from a temp dir with a stub model and checks the stub saw only the spec.
- A model invents requirements: the head reads ideas as hints, not facts (LESSONS: free models invent numbers).

## Tests
- tools/test_consult_tests.py :: stub model sees only the spec, repo-path out refused, planted marker never in a built prompt (red on the base). Player-visible: not applicable.

## Checklist
- file: tools/consult_tests.sh
- has: tools/consult_tests.sh :: Edge cases
- test: tools/test_consult_tests.py :: test_stub_sees_only_the_spec

## Proof
`bash tools/check.sh --no-godot` raw last 15 lines; final message ends with `Built-by: Gemini 3.8 Flash (agy)`.
