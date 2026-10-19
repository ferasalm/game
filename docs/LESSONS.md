# Lessons (curated; symptom -> cause -> fix; dated; max 80 lines)

## 1. You can do this yourself
- Godot 4.7.2 for Linux downloads from GitHub releases in a cloud session (tools/godot.sh, ~3 s); api.github.com
  answers 403 through the proxy, release downloads work (2026-10-19).
- Run Godot headless with tools/run_godot.sh: it fails on any SCRIPT ERROR or ERROR line even when Godot exits 0
  (2026-10-19).

## 2. Traps (Godot)
- Test runner found 0 tests -> `"abc".contains("")` is false in Godot 4.7 -> guard empty strings (2026-10-19).
- Parse error "isn't a constant expression" -> a `const` Dictionary can't hold class_name references -> use
  `preload("res://...")` (2026-10-19).
- A scene added in a SceneTree script's `_initialize()` had no `_ready()` yet -> run tests from the first
  `_process()` (tests/runner.gd) (2026-10-19).
- A test with a runtime error still counts as passed by the runner; only the SCRIPT ERROR line fails the run ->
  never trust the summary line alone; read check.sh's FAIL lines (2026-10-19).
- Godot 4.4+ writes a `.uid` next to every script and scene -> commit them, never read them (2026-10-19).
- `tests/test_*.gd` files are run as tests -> helper files in a tests/ folder must not start with `test_` (2026-10-19).

## 3. From reem-bot and feras-career (verified there)
- A check that only prints never fails -> every check exits non-zero; probe each new rule with one bad case.
- A subagent costs 150-290k tokens -> delegate only when the worker reads far more than its brief (reem-bot).
- Sync counts are wrong on a shallow clone -> the session hook unshallows first (reem-bot 2026-10-13).
- A superseded rule lives on in a doc or prompt string -> grep for it when a decision changes (reem-bot).
- Effort can't change mid-chat and a subagent can't outrank the chat's model (feras-career 2026-10-18).
- Gemini research contains invented numbers -> ideas and norms only, never facts (feras-career; here too).

## 4. Cheaper routes
- One test file: `tools/run_godot.sh -s res://tests/runner.gd -- timeline`.
- Where is X: grep docs/MAP.md (generated), not `ls -R`.
