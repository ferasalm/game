# Brief: progression-pure (<= 60 lines; small; opencode Inkling :free)
You are in your own worktree on branch oc/progression-pure (made from claude/menus-rpg-5089fa). Your working directory
is the repo root of that worktree; every path below is relative to it; never read or write outside it. Follow
GEMINI.md. Load the godot-gameplay-scripter skill.

## Why
CLAUDE.md: `logic/` folders are pure (no global state). features/progression/logic/progression.gd keeps two static
mutable defaults (`default_levels`, `default_classes`) that level() and award() fall back to: hidden global state
that tests can leak between each other.

## Read first
features/progression/logic/progression.gd, level_up.gd; features/progression/tests/test_progression.gd,
test_battle_progression.gd; every caller of Progression.level / Progression.award (grep "Progression\.").

## What to build
1. Remove `static var default_levels` and `static var default_classes`. level(xp, levels_def: LevelsDef) and
   award(xp_dict, party, amount, levels_def: LevelsDef, classes: Dictionary) take their defs explicitly (no default
   null fallback; a null LevelsDef still returns level 1).
2. Update every caller to pass the defs it already has (ContentDB lookups stay in view/core code, never in logic/).
3. Type the loose parameters: `party: Array[StringName]`, `classes: Dictionary[StringName, ClassDef]`,
   `xp_dict: Dictionary[StringName, int]` where callers allow; keep each function <= 40 lines.
4. Keep behaviour identical: every existing test passes unchanged except call sites that passed nothing.

## Do NOT edit
Anything outside features/progression/**, the callers you must update, and their tests. Never: features/world/**,
content/**, features/ui/**, docs/DECISIONS.md, HANDOFF.md, any *.import.

## Tests
Add one test: two awards in a row with different LevelsDefs give each its own levels (no shared state).

## Proof
`bash tools/check.sh` raw last 15 lines; small WIP commits; final message ends with `Built-by: inkling:free (opencode)`.
