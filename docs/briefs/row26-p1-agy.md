# Brief: row26-p1-agy (agy gemini-3.8-flash-medium; GDScript, RUN_KIND=godot) - a PROOF run, never merged into the product
You are in your own worktree on branch gemini/row26-p1-agy (made from origin/row26-p1-base, the locked test; pushed). Follow GEMINI.md, including
<review_misses>. Load the godot-gameplay-scripter skill.
Pattern: features/progression/logic/level_up.gd
Timebox: 25 min. First commit within 15 min, then small WIP commits.

## Why
Feras 11-02: the pipeline's proof so far was Python and cf only. This run proves the agy and Godot path end to end (slot, import, gate, new GDScript test red on the base). The code is a throwaway helper and is discarded after the proof.

## Read first
features/proofrun/tests/test_hp_clamp.gd (the locked test, read-only: it defines every behaviour), features/progression/logic/level_up.gd (house style for a pure logic class), .claude/rules/code.md.

## What to build
`features/proofrun/logic/hp_clamp.gd`: `class_name HpClamp`, `extends RefCounted`, a `## purpose` line in its first 6 lines, typed, pure (no nodes, no autoloads), two static functions:
1. `after_damage(hp: int, damage: int) -> int`: hp minus damage, never below 0; a negative damage changes nothing.
2. `after_heal(hp: int, amount: int, max_hp: int) -> int`: hp plus amount, never above max_hp; a negative amount changes nothing; an hp already above max_hp is pulled back to max_hp.
Then run `bash tools/run_godot.sh --import` once (new class_name), and `bash tools/check.sh` in the foreground.

## Do NOT edit
D6 defaults, protected by tools/build_gate.py without being listed. Keep this prose free of backticks outside May edit.
`features/proofrun/tests/test_hp_clamp.gd`

## May edit
`features/proofrun/logic/hp_clamp.gd`

## Ripple
none: a new class nothing else references; docs/MAP.md and DOCMAP.md refresh themselves.

## Pre-mortem
- A signed-int edge (negative damage or heal) is read as damage or healing: the locked test pins both.
- Gameplay numbers in code: there are none here; the function takes everything as arguments.
- The class is not found by the test: the import step above registers the class_name.

## Tests
- features/proofrun/tests/test_hp_clamp.gd :: every test (red on the base: the class does not exist)

## Checklist
- file: features/proofrun/logic/hp_clamp.gd
- has: features/proofrun/logic/hp_clamp.gd :: after_damage
- has: features/proofrun/logic/hp_clamp.gd :: after_heal
- test: features/proofrun/tests/test_hp_clamp.gd :: test_damage_stops_at_zero

## Proof
`bash tools/check.sh` raw last 15 lines; final message ends with `Built-by: Gemini 3.8 Flash (agy)`.
