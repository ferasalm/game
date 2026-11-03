# Brief: m1-guards (nv DeepSeek max; GDScript, RUN_KIND=godot)
You are in your own worktree on branch oc/m1-guards (made from origin/m1-guards-base, the locked tests on top of m1-defs; pushed).
Follow GEMINI.md, including <review_misses>. Load the builders skill.
Pattern: features/neon/roof/view/roof_patrol.gd, features/neon/roof/logic/contact_rules.gd, features/neon/roof/tests/test_contact_rules.gd
Timebox: 45 min. First commit within 15 min, then small WIP commits.

## Why
Feras 11-02: two guards with clear roles, a baton and a rifle, that teach dash, parry and the posture break. The enemy half of
the sim. Pillar served: 1 Hades-feel combat (readable telegraphs).

## Read first
The locked tests (read-only). docs/design/m1-fight.md sections 3 and 4, docs/design/m1-fight-api.md. The m1-defs types and defs.
features/neon/roof/view/roof_patrol.gd (the existing path walk, to be replaced by the machine) and contact_rules.gd.

## What to build
In features/fight/logic/, pure, integers, one class per file, numbers from FightGuardDef:
1. Sight: sees(guard, hero, rules) (range and half cone, never through the unit's back), is_behind(guard, hero) for the ambush rule.
2. GuardMachine.step(world, unit): states patrol (follow path, pause at ends), alert (turn, approach), baton loop (windup,
   strike, recover, cooldown, every third attack a 2-hit string), rifle loop (keep range and strafe, aim, lock, shot, recover),
   flinch (only outside windup and strike, armor otherwise), stagger (after a deflect), broken (posture full), ko (dissolve
   ticks then dead). An alert guard alerts an ally within the alert radius; being hit alerts too.
3. Telegraph events: `telegraph` at windup/aim start with value = ticks, and `shot` with the locked line when the rifle fires;
   the aim line tracks Rydan until lock_before ticks remain, then freezes in locked_dir.
4. Each active attack returns a Hitbox (arc for the baton, line for the rifle) with first_active on its first tick.
5. Reflected shot: a flag the resolver reads (unit.note[&"reflect"]) when the hero perfect-deflected that shot.

## Do NOT edit
D6 defaults, protected by tools/build_gate.py without being listed. Keep this prose free of backticks outside May edit.
`features/fight/defs/`
`content/fight/`
`features/neon/roof/`

## May edit
none

## Ripple
none: new files in features/fight/logic only; RoofPatrol stays until m1-view replaces it.

## Pre-mortem
Player: a windup too short to read or a shot that cannot be dodged -> tests assert the telegraph lasts the content windup and
the rifle line locks lock_before ticks before the shot. Gate: AI loops forever -> a test runs 3000 ticks and every state is left.
Review: ambush and sight disagree about "behind" -> both use the same helper, tested with four facings.

## Tests
- features/fight/tests/test_sight.gd :: sees inside the cone, not outside, not behind; is_behind for four facings.
- features/fight/tests/test_guard_baton.gd :: patrol -> alert on sight; windup lasts the content ticks and emits telegraph; strike
  box active 5 ticks; recover then cooldown; every third attack a string; a light hit in windup does not flinch (armor), in
  recover it does; deflect moves it to stagger; posture full -> broken then back after broken_ticks.
- features/fight/tests/test_guard_rifle.gd :: keeps 300-500 px; aim 36 ticks; line locks 12 ticks before the shot; the shot box
  is a line of width 24; recover 60.
- features/fight/tests/test_guard_alert.gd :: a hit alerts a guard; an alerted guard alerts one within 600 px, not 601.
- features/fight/tests/test_guard_ko.gd :: ko stays ko: no state change, no hitbox, for 600 ticks; dead after 60 dissolve ticks.
- player-visible: telegraph tick counts are >= 15 for baton and >= 30 for rifle (readable at 60 fps, acceptance M3).

## Checklist
- file: features/fight/logic/guard_machine.gd
- has: features/fight/logic/sight.gd :: static func sees
- test: features/fight/tests/test_guard_ko.gd :: test_ko_stays_ko

## Proof
`bash tools/check.sh` raw last 15 lines; final message ends with `Built-by: DeepSeek V4.1 Flash (opencode)`.
