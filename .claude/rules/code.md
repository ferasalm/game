---
paths: ["**/*.gd", "**/*.tscn", "**/*.tres", "tools/**", "tests/**"]
---
# Code rules (Claude and builders; build_pipeline pastes this file into every builder prompt)

## Stack
- Godot 4.7.2, Godot 4 syntax only, statically typed everywhere (an untyped declaration is an error).

## Shape
- <= 200 lines a file, <= 40 lines a function.
- A `## purpose` line within the first 6 lines of every .gd file (it feeds docs/MAP.md).
- Where is X: grep docs/MAP.md (generated), not `ls -R`. After adding files: `python tools/map.py`.
- After new class_names, and first in a fresh worktree: `bash tools/run_godot.sh --import` (else "Could not find type").

## Architecture
- `logic/` folders are pure: no nodes, scene tree, autoloads, input or await. View code never computes rules.
- Content is JSON read into read-only Def classes. Changing numbers live in state objects. No gameplay numbers in code.
- Saves go through GameState and migrate through SaveCodec one version at a time.
- No node lookups by path: use `@export` or `%UniqueName`.
- Player text = localization keys read through TextDB; add rows to an existing localization/<feature>.csv.

## Tests and checks
- Every rule and every fixed bug gets a test: tests/test_*.gd; helpers in tests/ must not start with `test_`.
- Never remove or weaken a check to make it pass.
- Never write "...", "rest unchanged", TODO, stubs or placeholder values. Write the real content or report BLOCKED.
- Check: `bash tools/check.sh`, then read the FAIL lines. Exit 124 with no FAIL line is the 600 s timeout, not a test.
- One test file: `bash tools/run_godot.sh -s res://tests/runner.gd -- <name>`.
- A check counts only when its output was read.
