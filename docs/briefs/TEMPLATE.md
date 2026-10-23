# Brief: <task> (copy to docs/briefs/<task>.md; <= 60 lines)
You are in your own worktree on branch <gemini|oc>/<task> (made from claude/night-sanaa). Follow GEMINI.md, including
<review_misses>. Load the <skill> skill (name one; build_pipeline.sh pastes .agents/skills/<skill> into the prompt).

## Why
<the owner's words, one or two lines>

## Read first
<spec files, MAP.md greps, the exact files or functions to start from>

## What to build
1. <numbered, testable steps; numbers and text come from content and localization, never code>

## Do NOT edit
<one backticked path per line (a folder ends in /, globs allowed); tools/build_gate.py turns any edit
of them into BREACH; shared files go in prose below them: smallest edit>

## Tests
<one line per rule or bug that must get a test>

## Checklist
- file: features/combat/logic/battle_sim.gd
- has: features/combat/logic/battle_sim.gd :: func lands_before
- test: features/combat/tests/test_battle_rolls.gd :: test_crit_chance_formula
- key: localization/combat.csv :: MOVE_DESC_BREAKER

## Proof
`bash tools/check.sh` raw last 15 lines; renders (if any) to C:/dev/game/inbox/<name>.png; small WIP commits; final
message ends with `Built-by: Gemini 3.8 Flash (agy)` (opencode: `Built-by: <model> (opencode)`).
