# Brief: neon-battle (Neon Glitch turn-based fight on the iso map; <= 60 lines)
You are in your own worktree on your own branch made from neon/first-playable. Follow AGENTS.md / GEMINI.md, including
<review_misses>. Load the godot-gameplay-scripter skill.

## Why
DECISIONS: battles on the map where you meet the enemy (Chrono Trigger style), the existing timeline kept, the hero
fights alone. First playable: Rydan vs two prison guards on Feras's painted prison roof, no arena swap.

## Read first
docs/design/first-playable.md section 3. features/neon/ (IsoActor, IsoWalk, IsoDir, NeonRoomDef). How the 3D stage
drives the rules: features/combat/view/battle_stage.gd, battle_runner.gd, battle_event_player.gd (read only), and
features/combat/harness/battle_loader.gd (from_db, party_from_state, make_sim_for). Encounter: neon_prison_guards.

## What to build (all in features/neon/battle/ + content/neon/battle_view.json + localization/neon_battle.csv)
1. `map_battle.gd` (class MapBattle, Node): `func begin(world: Node2D, room: NeonRoomDef, hero: IsoActor,
   foes: Array[IsoActor], contact: Vector2, ambush: bool) -> void`, `signal ended(won: bool)`. It builds the sim
   with BattleLoader.from_db(ContentDB, room.encounter), party_from_state(GameState, [&"zayd"]) ("zayd" is Rydan's
   code id), make_sim_for(party, seed, 1 if ambush else 0). Foe actors map to enemy units in order.
2. Pure `logic/map_formation.gd` (class MapFormation): `static func spots(contact: Vector2, foes: int, outline,
   holes) -> Dictionary` -> {"hero": Vector2, "foes": Array[Vector2]}: hero 120 px right-down of contact, foes 140
   px left-up, 110 px apart along the iso diagonal, each moved inside the floor with IsoWalk.nearest_free.
3. Start: 0.3 s glitch flash (a CanvasLayer ColorRect shader: RGB split + scanlines), letterbox bars slide in, fighters
   "run" to their spots (tweens) and face each other, then idle. End: bars out, losers stay down ("ko" last frame).
4. Play the sim in wait mode like BattleStage: step a few ticks per frame; when a hero waits, open the existing
   BattleCommandMenu (features/combat/view/battle_command_menu.gd) on a CanvasLayer and send its `chosen` to
   sim.choose; enemies are chosen by the sim. Event playback per TimelineEvent kind: a melee act = run to 70 px in
   front of the target, "attack", on IsoActor.impact apply the hit (freeze both 0.07 s, target "hurt", a popping
   damage number, small camera shake), run back; a tech move = "cast" + a coloured flash at the target; ko = "ko".
5. HUD (CanvasLayer): reuse BattleTimelineBar if it builds from the sim alone, else a slim own bar (icons per unit
   along a track, COMMAND mark at 7000/10000); Rydan's HP/SP bar bottom-left (Hades-like: slanted, ink border,
   teal SP, red HP); foe HP bars over their heads. Sizes and colours in content/neon/battle_view.json (+ a Def
   registered by a one-line KINDS edit in core/content_db.gd, the only core edit allowed).
6. Victory: "VICTORY" stamp, XP and riyal from the outcome applied as BattleSession does (read how), `ended(true)`.
   Defeat: "Retry" restarts the same fight from the pre-battle snapshot; `ended(false)` only on Quit.
7. `battle_demo.tscn`: the prison plate (NeonRoomDef.plate) + y-sorted World + Rydan + two guards, begin() on ready.

## Do NOT edit
`features/neon/defs/`
`features/neon/logic/`
`features/neon/view/`
`features/neon/roof/`
`features/neon/start/`
`features/combat/`
`content/combat/`
`content/neon/rooms.json`
`content/neon/sprites.json`
`assets/`
Only core edit: one KINDS line in core/content_db.gd.

## Tests (features/neon/battle/tests/)
- MapFormation: spots stay on the floor, foes are left-up of the hero, spacing.
- MapBattle headless with an auto-choosing hero (sim.auto_choose): the fight ends, ended fires once, the winner side
  stands, a ko'd actor shows "ko"; a melee act applies its damage only at the impact signal.

## Checklist
- file: features/neon/battle/map_battle.gd
- file: features/neon/battle/battle_demo.tscn
- has: features/neon/battle/map_battle.gd :: signal ended
- has: features/neon/battle/logic/map_formation.gd :: static func spots
- test: features/neon/battle/tests/test_map_battle.gd :: test_auto_battle_ends_once
- key: localization/neon_battle.csv :: NEON_BATTLE_VICTORY

## Proof
`bash tools/check.sh` raw last 15 lines; render tools/shot_neon_battle.tscn (wrapper like tools/shot_dialogue.tscn)
-> C:/dev/game/inbox/neon_battle.png mid-fight with the HUD; small WIP commits.
