---
paths:
  - "**/*.gd"
---
# GDScript language server (studio plugin) and what to do when it is down
The studio plugin starts `plugins/studio/scripts/godot_lsp.py` for `.gd` files (`plugins/studio/.lsp.json`; test: tools/test_godot_lsp.py).
- LSP answers (hover, go to definition, find references) are hints: a wrong or empty answer never overrules the code or a test.
- No answer, a startup timeout or a crash (`restartOnCrash` is false): do not retry in a loop. Fall back to `Grep` on the symbol,
  `docs/MAP.md` for "where is X" and `tools/run_godot.sh -s res://tests/runner.gd -- <name>` for behaviour.
- After a new `class_name`, run `bash tools/run_godot.sh --import` first (code rules), else the server and Godot both miss the type.
- Memory floor: if `bash tools/slots.sh` shows free memory under the floor, the server may be the first thing to fail; carry on without it.
