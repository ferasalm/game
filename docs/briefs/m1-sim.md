# Brief: m1-sim (cf DeepSeek max; GDScript, RUN_KIND=godot)
You are in your own worktree on branch oc/m1-sim (made from origin/m1-sim-base: m1-defs, m1-hero and m1-guards merged, plus the
locked tests; pushed). Follow GEMINI.md, including <review_misses>. Load the builders skill.
Pattern: features/fight/logic/hero_machine.gd, features/fight/logic/guard_machine.gd (from the merged parts)
Timebox: 45 min. First commit within 15 min, then small WIP commits.

## Why
Feras 11-02: the fight is one real-time sim, deterministic, so a bot can play it in CI and a bug replays exactly. This part wires
the hero and guard machines into FightSim and resolves hits. Pillar served: 1 Hades-feel combat.

## Read first
The locked tests (read-only). docs/design/m1-fight-api.md (FightSim and HitResolver), docs/design/m1-fight.md sections 2-5.
DefenceRules, HeroMachine, GuardMachine from the merged parts.

## What to build
1. HitResolver.resolve in features/fight/logic/hit_resolver.gd: for each Hitbox and each living target on the other side, test
   arc (distance and angle) or line (distance to segment); ask DefenceRules; apply hp, posture, both units' hit-stop (frozen),
   knockback along the hitbox dir through Ground.step_walkable, flinch, mercy; ambush x2 and posture break on an unaware guard
   hit from behind; finisher x3 on a broken guard then posture reset; riposte x1.5 and its end; reflect a perfect-deflected
   shot to its shooter; ko at 0 hp; emit hit, guarded, deflected, perfect, evaded, posture_broken, finisher, hurt, ko.
2. FightSim in features/fight/logic/fight_sim.gd: _init(setup) builds units (hero and guards at the plate spawns converted by
   Ground, guards with their path), step(input) in the order of m1-fight-api.md, world(), result() (won when no guard lives,
   lost when the hero is dead, then it stops stepping), snapshot() (copies for the view). Seeded RNG, no wall clock.
3. Determinism: the same setup, seed and input list give the same event list (the test hashes it).

## Do NOT edit
D6 defaults, protected by tools/build_gate.py without being listed. Keep this prose free of backticks outside May edit.
`features/fight/defs/`
`content/fight/`

## May edit
none

## Ripple
none: new files only; nothing outside features/fight/logic calls FightSim until m1-view.

## Pre-mortem
Player: a hit lands twice (one hitbox on many ticks) or never -> first_active boxes hit once per attack, tested per attack.
Gate: two runs differ -> the determinism test runs the same 2000-tick script twice. Review: hit-stop deadlock (both frozen forever)
-> a test asserts frozen only ever counts down and every unit moves again within hitstop + 1 ticks.

## Tests
- features/fight/tests/test_hit_resolver.gd :: arc inside and outside by 1 milli-px; line width edge; one hit per attack; ambush
  x2 only unaware and behind; finisher x3 then posture 40; riposte x1.5 once; reflect damages the shooter; knockback stops at a wall.
- features/fight/tests/test_fight_sim.gd :: spawn positions; scripted win (hero kills both guards); scripted loss (hero stands
  still, dies, result lost, sim stops); ko stays ko over 600 ticks (playtest 25); no unit ever outside the walk polygon.
- features/fight/tests/test_fight_determinism.gd :: same setup and inputs twice = identical event hash.
- features/fight/tests/test_fight_hitstop.gd :: hit-stop freezes exactly attacker and target for the content ticks, nobody else.
- player-visible: a scripted baton windup emits `telegraph` at least 15 ticks before its first `hit` event.

## Checklist
- file: features/fight/logic/fight_sim.gd
- has: features/fight/logic/fight_sim.gd :: func step
- has: features/fight/logic/hit_resolver.gd :: static func resolve
- test: features/fight/tests/test_fight_determinism.gd :: test_same_inputs_same_events

## Proof
`bash tools/check.sh` raw last 15 lines; final message ends with `Built-by: DeepSeek V4.1 Flash (opencode)`.
