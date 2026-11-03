# Brief: m1-view (nv DeepSeek high; GDScript, RUN_KIND=godot)
You are in your own worktree on branch oc/m1-view (made from origin/m1-view-base: m1-sim, m1-touch and m1-juice merged, plus the
locked tests; pushed). Follow GEMINI.md, including <review_misses>. Load the builders skill.
Pattern: features/neon/roof/roof_scene.gd, features/neon/roof/view/roof_hud.gd, features/neon/neon_game.gd
Timebox: 45 min. First commit within 15 min, then small WIP commits.

## Why
Feras 11-02: the roof fight must be playable, real-time, on PC and phone. This part puts the sim on the screen and removes the
turn-based hand-off. Pillar served: 1 Hades-feel combat.

## Read first
The locked tests (read-only). docs/design/m1-fight-api.md (View contract), docs/design/m1-fight.md sections 1, 3, 5. RoofScene
(it hosts the view), NeonGame (the hand-off to replace), ContactRules, FightSim, FightFx, TouchControls.

## What to build
1. features/fight/view/fight_view.gd (Node): begin(setup), set_active, ended(won); 60 Hz accumulator in _physics_process (max 4
   steps a frame); builds FightInput from Input (move_* vector x1000, attack/dash/parry, aim from mouse position in plate space
   when the mouse moved last, else zero); each tick: sim.step, FightFx.play per event, then place IsoActors at Ground.to_plate,
   face from unit.facing, play clips (idle, run, attack with speed_scale so the impact frame matches the first active tick, cast
   for rifle aim, hurt, ko), y-sorted by feet.
2. features/fight/view/fight_hud.gd (Control): Rydan HP bar and a thin centre posture bar, per-guard HP and posture bars over the
   head, a defeat panel with Retry (TextDB keys FIGHT_DEFEAT, FIGHT_RETRY; Retry rebuilds the sim from the same setup), a victory
   line FIGHT_VICTORY. Font >= 18 px at 720p.
3. RoofScene: build FightSetup from the room (spawn, outline, holes, guards with kind, facing, path), add FightView and the
   TouchControls under it; hero movement and RoofPatrol are removed (the sim owns both); set_exploring(false) pauses the view;
   after `ended(true)` the sim keeps walking the hero (no foes) and `_won` is set for the cable line. The battle_requested
   signal is deleted.
4. NeonGame: delete the MapBattle hand-off (_on_battle_requested, _on_battle_ended and the stage battle); a lost fight shows
   the Retry panel, not the start screen.
5. tools/shot_neon_fight.tscn + .gd (new): a headless-safe render wrapper like tools/shot_neon_roof.tscn that scripts input
   (approach, combo, dash, parry) and writes frames to a path argument.

## Do NOT edit
D6 defaults, protected by tools/build_gate.py without being listed. Keep this prose free of backticks outside May edit.
`features/fight/logic/`
`features/fight/defs/`
`features/fight/touch/`

## May edit
`features/neon/roof/roof_scene.gd`
`features/neon/roof/roof_scene.tscn`
`features/neon/neon_game.gd`
`features/neon/neon_game.tscn`
`features/neon/roof/view/roof_patrol.gd`
`features/neon/roof/tests/test_roof_scene.gd`
`features/neon/tests/test_neon_game.gd`
`features/neon/tests/test_neon_playtest.gd`

## Ripple
RoofScene signals and test_roof_scene, test_neon_game and test_neon_playtest read battle_requested and the battle stage: the
build edits only those assertions (fixtures, reason in the commit). The turn-based folder under features/neon stays untouched. roof_patrol.gd is
deleted if nothing else uses it. Playtest capture (neon_playtest_state) keeps working: it reads the stage name.

## Pre-mortem
Player: input lag or a hitch at 60 Hz -> fixed accumulator, no allocation per tick, tested for 1000 ticks. Gate: scene wiring
breaks silently -> a test builds RoofScene, runs 600 ticks of scripted input and asserts a guard KO. Review: the view computes a
rule -> the lint test greps fight_view for hp and posture writes.

## Tests
- features/fight/tests/test_fight_view.gd :: 60 Hz steps independent of frame delta; set_active(false) steps nothing; Retry
  rebuilds identical state; actor positions equal Ground.to_plate of the sim.
- features/neon/roof/tests/test_roof_scene.gd + features/neon/tests/test_neon_game.gd :: roof boots, scripted fight reaches won,
  the cable line works after.
- features/fight/tests/test_fight_hud.gd :: bars follow hp and posture; defeat panel appears on lost; font sizes >= 18 at 720p.
- player-visible: shot_neon_fight frames show the hero in full colour (> 256 colours), the telegraph ring on a windup, and the
  hit flash; clip impact frame equals the first active tick within 1 tick.

## Checklist
- file: features/fight/view/fight_view.gd
- has: features/fight/view/fight_view.gd :: func begin
- test: features/fight/tests/test_fight_view.gd :: test_fixed_step_independent_of_delta

## Proof
`bash tools/check.sh` raw last 15 lines; renders to C:/dev/game/inbox/m1-fight-*.png; final message ends with `Built-by: DeepSeek V4.1 Flash (opencode)`.
