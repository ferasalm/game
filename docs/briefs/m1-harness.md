# Brief: m1-harness (nv DeepSeek max; GDScript, RUN_KIND=godot)
You are in your own worktree on branch oc/m1-harness (made from origin/m1-harness-base: m1-sim merged, plus the locked tests; pushed).
Follow GEMINI.md, including <review_misses>. Load the builders skill.
Pattern: features/combat/harness/balance.gd (read for the shape of a headless runner; do not edit it)
Timebox: 45 min. First commit within 15 min, then small WIP commits.

## Why
Feras 11-02: the fight must be neither too easy nor too hard and the parry must matter (acceptance F6). The sim is deterministic,
so bots that play it prove the design in CI before Feras's thumbs do. Pillar served: 1 Hades-feel combat.

## Read first
The locked tests (read-only). docs/design/m1-fight.md section 7, FightSim, FightSetup, content/fight/*.json, the roof room in
content/neon/rooms.json.

## What to build
1. features/fight/harness/fight_bot.gd (RefCounted, pure): `act(snapshot, tick) -> FightInput` for three policies: MASHER (attack
   every tick toward the nearest foe, never defends), DASHER (attack, dash away from any telegraph in its last 14 ticks, never
   parries), PARRIER (reads `telegraph` events: parry so the perfect window covers the strike tick, finishes broken guards,
   otherwise combos). Bots use only the snapshot and events, never hidden state.
2. features/fight/harness/fight_runner.gd: `run(policy, seeds: Array[int], max_ticks) -> Array[Dictionary]` (won, ticks, hp left,
   perfects, finishers) and a printed table (win rate, median seconds, hp left) like balance.gd; seeds vary guard spawn offsets
   by +-40 px and reaction jitter only through the seeded RNG.
3. A tools-free entry: `bash tools/run_godot.sh -s res://tests/runner.gd -- fight_balance` runs it through the test below.

## Do NOT edit
D6 defaults, protected by tools/build_gate.py without being listed. Keep this prose free of backticks outside May edit.
`features/fight/logic/`
`features/fight/defs/`
`content/fight/`
`features/combat/`

## May edit
none

## Ripple
none: new files in features/fight/harness and tests only. If a band fails, the fix is a content number in content/fight/, made by
the head (Opus) after reading the table, never by loosening the bands.

## Pre-mortem
Player: the bots pass but the fight is dull -> bands also require the PARRIER to use >= 2 perfects and >= 1 finisher per win.
Gate: 60 seeds x 3 policies is slow -> 30 seeds, each <= 4000 ticks, headless; the test prints elapsed. Review: bands tuned to
the bots' bugs -> the bot reads only the snapshot (a lint test greps fight_bot.gd for FightWorld.units writes).

## Tests
- features/fight/tests/test_fight_bots.gd :: MASHER loses >= 60% of 30 seeds; DASHER wins 30-70%; PARRIER wins >= 80% with median
  20-45 s (1200-2700 ticks) and >= 2 perfects and >= 1 finisher per win; PARRIER beats DASHER by >= 15 points (the parry matters);
  every run ends within max_ticks (no stalls); the same seed repeats exactly.
- features/fight/tests/test_fight_runner.gd :: the table has one row per policy; hp left never negative.
- player-visible: median PARRIER win time 20-45 s and the first guard KO happens after tick 600 (the fight is not over at once).

## Checklist
- file: features/fight/harness/fight_bot.gd
- has: features/fight/harness/fight_runner.gd :: func run
- test: features/fight/tests/test_fight_bots.gd :: test_parry_matters

## Proof
`bash tools/check.sh` raw last 15 lines; final message ends with `Built-by: DeepSeek V4.1 Flash (opencode)`.
