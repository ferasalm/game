# Brief: m1-hero (cf DeepSeek max; GDScript, RUN_KIND=godot)
You are in your own worktree on branch oc/m1-hero (made from origin/m1-hero-base, the locked tests on top of m1-defs; pushed). Follow
GEMINI.md, including <review_misses>. Load the builders skill.
Pattern: features/neon/logic/iso_walk.gd, features/neon/roof/logic/contact_rules.gd, features/neon/roof/tests/test_contact_rules.gd
Timebox: 45 min. First commit within 15 min, then small WIP commits.

## Why
Feras 11-02: Hades movement, a 3-hit combo, a dash with i-frames and a Sekiro parry with posture. The player-facing half of the
sim; if it feels bad nothing else matters. Pillar served: 1 Hades-feel combat.

## Read first
The locked tests (read-only). docs/design/m1-fight.md sections 1, 2, 4 and docs/design/m1-fight-api.md (signatures to match
exactly). The m1-defs files: features/fight/logic/ data types and features/fight/defs/. IsoWalk and IsoDir in features/neon/logic.

## What to build
In features/fight/logic/, one class per file (<= 200 lines, functions <= 40), pure, integers only, every number from the defs:
1. Ground: plate <-> ground conversion (y / IsoWalk.Y_SQUASH), step_walkable through IsoWalk.step in plate space.
2. InputBuffer: push, take(kind, tick, window), clear; a taken press cannot be taken twice.
3. AimAssist: pick the best foe in the cone and range (score = angle + distance; ties by id), facing_toward the 8 IsoDir rows.
4. Posture: add (returns true on the tick it breaks), regen after the no-contact delay, reset_after_finisher.
5. DefenceRules.resolve: the table in spec section 4 for a target in guard, deflect, perfect, dash i-frames or none, using the
   target's state and tick; returns the Dictionary of m1-fight-api.md.
6. Trauma: add, tick, shake (trauma squared), decays per second from rules.
7. HeroMachine.step: states idle, move, step1..step3, dash, parry (startup, deflect, guard, recover), hurt, broken, dead; buffered
   presses chain combo steps and dash-cancel recovery; lunge toward the aim target; emits attack_started, dash, riposte; returns
   the active Hitbox list (first_active true on the first active tick only). No Engine, Input or node access.

## Do NOT edit
D6 defaults, protected by tools/build_gate.py without being listed. Keep this prose free of backticks outside May edit.
`features/fight/defs/`
`content/fight/`

## May edit
none

## Ripple
none: new files in features/fight/logic only; nothing else calls them until m1-sim.

## Pre-mortem
Player: the combo drops presses or a dash eats a hit it should not -> tests press on every tick of each phase and assert the
state. Gate: a float creeps into the sim -> a lint test greps features/fight/logic for float, randf, Time and Engine. Review: parry
windows off by one -> tests assert tick 0, 5, 6, 11, 12 of the window by name.

## Tests
- features/fight/tests/test_ground.gd :: round trip within 1 milli-px; a step into a wall slides.
- features/fight/tests/test_input_buffer.gd :: a press 8 ticks old is taken, 9 is not; taken once.
- features/fight/tests/test_aim_assist.gd :: nearest in cone wins; outside cone or range returns null; tie by id.
- features/fight/tests/test_posture.gd :: breaks exactly at max; regen waits 90 ticks; finisher reset to 40.
- features/fight/tests/test_defence_rules.gd :: all five rows of the table, the perfect/normal boundary at tick 5 vs 6.
- features/fight/tests/test_hero_machine.gd :: combo chain 1-2-3, a miss on 3 returns to idle, dash cancels recovery but not
  startup, i-frames ticks 1-9 only, mercy ticks after a hit, parry whiff recovery blocks dash, hero never leaves the walk polygon.
- features/fight/tests/test_trauma.gd :: decays to 0, never negative, shake <= trauma squared.
- player-visible: step 1 first_active tick equals startup + 1 so the clip impact frame can match (acceptance M3).

## Checklist
- file: features/fight/logic/hero_machine.gd
- has: features/fight/logic/defence_rules.gd :: static func resolve
- test: features/fight/tests/test_hero_machine.gd :: test_combo_chain

## Proof
`bash tools/check.sh` raw last 15 lines; final message ends with `Built-by: DeepSeek V4.1 Flash (opencode)`.
