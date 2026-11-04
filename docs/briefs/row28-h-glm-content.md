# Brief: row28-h-glm-content (head + agy for scripts; Python and docs, RUN_KIND=py)
You are in your own worktree on branch gemini/row28-h-glm-content (made from origin/main after part a). Follow GEMINI.md, including
<review_misses>. Load the builders skill.
Pattern: tools/nv_build.sh, tools/test_nv_build.py
Timebox: 30 min (<= 45). First commit within 15 min, then small WIP commits.

## Why
Feras 11-04: GLM-5.3-flash does level design, technical art, dialogue and narrative (designs and JSON data, never core code); Feras keeps art direction. Pillar served: combat feel wins ties through level and encounter data.

## Read first
tools/nv_build.sh, .claude/skills/low-cost-pipeline/routing.md (content row), docs/CANON.md headings, the narrative-designer and level-designer persona files.

## What to build
1. `tools/content_build.sh <task> <brief> <base>`: calls nv_build.sh pinned (4th arg) to openrouter/z-ai/glm-5.3-flash (PAID_OK=1 required, the refusal names docs/SPEND.md), with CONTENT=1 so the build gate allows only content paths.
2. Allowed outputs, enforced by a path list in builders.conf (CONTENT_PATHS): `content/`, `localization/`, `docs/design/`, `docs/briefs/` outputs. Any .gd file or tools/ path in the diff is a BREACH.
3. After the build, content_build.sh prints a line telling the head to run the review-canon agent on the diff before merge (names, dialogue, CANON drift); it does not merge.
4. docs: one paragraph in routing.md names who calls it (the head, with Feras's OK per run) and the output format (JSON through DefReader or localization CSV rows, never code).

## Do NOT edit
D6 defaults, protected by tools/build_gate.py without being listed. Keep this prose free of backticks outside May edit.

## May edit
`tools/builders.conf`
`.claude/skills/low-cost-pipeline/routing.md`

## Ripple
build_gate.py is protected and defines BREACH: content_build.sh only passes CONTENT_PATHS in the brief's May edit, never edits the gate. Localization rows go into an existing CSV (code.md).

## Pre-mortem
- GLM writes lore that drifts: the review-canon step is printed on every run and HANDOFF notes it as a merge precondition.
- Paid run without OK: the PAID_OK check refuses before any call; a test pins it.
- A content file breaks a Def reader: check.sh runs the content tests; the brief names the Def class to read.

## Tests
- tools/test_content_build.py :: refuses without PAID_OK, pins the model, prints the review line (red on the base). Player-visible: the content test feeds real JSON text through JSON.parse_string (code.md).

## Checklist
- file: tools/content_build.sh
- has: tools/builders.conf :: CONTENT_PATHS
- test: tools/test_content_build.py :: test_refuses_without_paid_ok

## Proof
`bash tools/check.sh --no-godot` raw last 15 lines; final message ends with `Built-by: Gemini 3.8 Flash (agy)`.
