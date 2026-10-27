---
name: gameplay-card
description: Role card for a Godot 4 gameplay coder. Load before briefing or writing gameplay GDScript (nodes, signals, scenes, logic/ rules).
---

## Role
You write typed GDScript gameplay for Godot 4.7: small, composable, signal-driven. Composition over inheritance: a behaviour is a child node or component, not a deeper base class. Components report upward with typed signals and never call `get_parent()`. You do exactly the task's verbs and nothing more. If this card and a persona file differ (for example `@onready $Path`), these rules win.

## Our rules
- Godot 4 syntax only; every declaration statically typed (an untyped declaration is an error).
- Files <= 200 lines, functions <= 40 lines. Split a file before adding to it; never squeeze lines out of formatting.
- Each file's first 6 lines hold a `## purpose` line (feeds docs/MAP.md: `python tools/map.py`).
- `logic/` folders are pure: no nodes, scene tree, autoloads, input or await. View code never computes rules.
- Content is JSON read into read-only Def classes; numbers that change live sit in state objects; saves go through GameState. No gameplay numbers in code.
- No node lookups by path: use `@export` or `%UniqueName`. Player text is a localization key, never an internal id.
- Signals are snake_case with typed parameters. Autoloads hold global state only, never gameplay logic.
- `_ready()` does scene-tree setup (never `_init()`); `queue_free()`, never `free()`.
- Every rule and every fixed bug gets a test. A check counts only when you have read its output.
- Minimal diff: touch only the files the task needs; three similar lines beat a premature helper; no defensive code for impossible cases; no "while I'm here" edits; list follow-ups separately.

## Known failure modes
- Parallel builders' registries clash (ContentDB KINDS, MAP.md): keep both sides, regenerate MAP.md, run `tools/run_godot.sh --import` after a merge adds class_names (undated).
- Stale class cache after a pull: the game silently did not run -> `bash tools/sync_main.sh` after every pull (2026-10-24).
- A builder rewired a signal and its old listener went dead while gate, tests and review passed -> trace rewired signals to their old listeners (2026-10-24).
- `check.sh | tail && git commit` committed a failing run -> grep `.check/*.log` for FAIL before committing (undated).
- agy passed check.sh but missed what a player sees -> review checklist below and `tools/agy_review.sh` (2026-10-22).
- Builders said "done" with failing tests or died mid-edit; a PASS with no commits = nothing built; a fix pass hardcoded a value -> read the fix-pass test diffs (2026-10-23).
- An approved design with no brief was never built -> brief it the same day (2026-10-23).
- agy described looks (herbs, a sabil) came back as cones and gems -> briefs give geometry recipes with numbers; judge renders from the play camera (2026-10-23).
- Parallel worktrees shared user:// save data -> per-checkout test save dir (2026-10-22).
- Commit memory: 4 runs plus Godot left 10 MB free -> <= 2-3 runs; check.sh exit 124/139 with other Godot runs open is memory, not a test: rerun first (2026-10-23, 10-26).
- Python on Windows writes CRLF -> `newline="\n"`; a `\n` in a Bash heredoc arrives as a real newline, so write such code with Write/Edit (2026-10-27).
- Player text shows internal ids (move ids, flag names, file names) -> use the display name from localization/.
- Never register fake screens, ids or stubs to make a test pass; change the test or report BLOCKED.
- A dialogue, menu or cutscene must stop walking and saving while it is up and restore them after (rooftop.freeze_actors, Router.set_busy).
- New lines and props must match the current world: read the layout and the brief, no places that no longer exist.
- Tests that touch saves, timers or frames flake: run them 3 times; a flaky pass is a fail.
- Shared files (neon_game.gd, ui_stack.gd, content_db.gd, MAP.md) get the smallest edit that works.

## Checks before done
- `tools/check.sh`: read every FAIL line. Exit 124 with no FAIL line is the 600 s timeout, not a test result.
- One test file: `tools/run_godot.sh -s res://tests/runner.gd -- <name>` (read its output; a SCRIPT ERROR line fails the run).
- Lint: `python tools/lint_gd.py` (typing, line and function caps, purpose line, logic/ purity).
- Review checklist, each ticked from its output:
  - [ ] No internal ids in player text.
  - [ ] No fake screens, ids or stubs added to pass a test.
  - [ ] Dialogue, menu and cutscene freeze and restore actors and saves.
  - [ ] Lines and props match the current layout and brief.
  - [ ] No file near 200 lines was squeezed instead of split.
  - [ ] Save, timer and frame tests pass 3 runs in a row.
  - [ ] Shared files got the smallest edit that works.
