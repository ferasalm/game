# Brief: <task> (copy to docs/briefs/<task>.md; <= 60 lines; tools/test_template.py keeps the gate's headings here)
You are in your own worktree on branch <gemini|oc>/<task> (made from origin/main; push the base first). Follow GEMINI.md, including
<review_misses>. Load the <skill> skill (name one; build_pipeline.sh pastes .agents/skills/<skill> into the prompt).
Timebox: <N> min (<= 45). First commit within 15 min, then small WIP commits: no commit for 25 min (IDLE_MIN) = NOWORK.

## Why
<the owner's words, one or two lines>. Pillar served (docs/VISION.md): <one pillar; combat feel wins ties>.

## Read first
<spec files, MAP.md greps, the exact files and functions to start from>

## What to build
1. <numbered, testable steps; numbers and text come from content and localization, never code>

## Do NOT edit
D6 defaults, protected by tools/build_gate.py without being listed: existing tests, tools/, .github/ (edits and
deletions; new test files are allowed) and every change under assets/ (incl. *.import). Keep this prose free of
backticks: every backticked token in this section is a forbidden path, and May edit does not lift it.
<one backticked path per line for anything else (a folder ends in /, globs allowed); an edit = BREACH>

## May edit
<backticked paths inside the D6 defaults the task must touch, one per line; empty = none. Shared files: smallest edit>

## Ripple
<what else this change touches: every listener, signal, key, id and save field it renames or rewires; every place
the changed asset appears (docs/design/systems-map.md), each with how the build keeps it working>

## Tests
<written first by Claude, red on the base, read-only for the builder. One line per rule or bug. At least one
player-visible test: what the player sees (the portrait inside every frame it appears in, colour count above a floor,
a light changes the pixels around it, the win rate inside the balance band over 200 fights), not only the simulation>

## Checklist
- file: features/combat/logic/battle_sim.gd
- has: features/combat/logic/battle_sim.gd :: func lands_before
- test: features/combat/tests/test_battle_rolls.gd :: test_crit_chance_formula
- key: localization/combat.csv :: MOVE_DESC_BREAKER

## Proof
`bash tools/check.sh` raw last 15 lines; renders (if any) to C:/dev/game/inbox/<name>.png; final message ends with
`Built-by: Gemini 3.8 Flash (agy)` (opencode: `Built-by: <model> (opencode)`).
