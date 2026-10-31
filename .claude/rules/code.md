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
- A content test feeds real JSON text through JSON.parse_string, not only a Dictionary literal (2026-10-31).
- Never remove or weaken a check to make it pass.
- Never write "...", "rest unchanged", TODO, stubs or placeholder values. Write the real content or report BLOCKED.
- Check: `bash tools/check.sh`, then read the FAIL lines. Exit 124 with no FAIL line is the 600 s timeout, not a test.
- One test file: `bash tools/run_godot.sh -s res://tests/runner.gd -- <name>`.
- A check counts only when its output was read.

## Godot traps (moved from docs/LESSONS.md 2026-10-28; add dated lines here)
- JSON numbers load as float and lists as Array: `is int` or `is PackedStringArray` rejects real content, a Dictionary
  literal in a test hides it -> content reads through DefReader (`extends Def`), never its own from_dict (2026-10-31).
- `"abc".contains("")` is false in 4.7; a `const` Dictionary can't hold class_name refs (use preload); `match` is a
  keyword (`var match` fails) (2026-10-19/22).
- A scene added in a SceneTree script's `_initialize()` has no `_ready()` yet: tests start from the first `_process()`.
- Godot exits 0 on a runtime error; run_godot.sh fails the run on a SCRIPT ERROR/ERROR line, and headless get_image()
  prints one -> tests inject the grab (2026-10-26).
- A lambda assigning an outer local changes nothing (captured by value) -> hold it in an Array (2026-10-26).
- Commit every `.uid`, never read it; never write *.import (Godot's CSV import breaks a fresh clone: CSVs keep the
  "keep" importer, test_text_db) (2026-10-19/22).
- `move_and_slide` does nothing when `_physics_process` is called by hand -> move_and_collide + slide (2026-10-21).
- Sorting StringNames compares addresses (rows flipped between runs) -> sort by String (2026-10-21).
- load() of a .webp in a .gdignore folder (assets/textures/painted/) returns null -> Image.load_webp_from_buffer.
- `find_children(pattern, "MyClass")` never matches a script class_name -> walk the children, test `is MyClass`.
- A tween pauses with its node: a UiScreen closed while another covered it stayed frozen -> close() re-enables
  processing (2026-10-23).
- A test counting processes by name machine-wide is flaky with parallel checkouts -> mark the test's children (10-27).
