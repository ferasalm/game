# Brief: retire-3d-battle (remove the 3D battle stage; <= 60 lines)
You are in your own worktree on your own branch made from claude/retire-3d-6d2a28. Follow AGENTS.md, including
<review_misses>. Load the godot-gameplay-scripter skill and the minimal-change-engineer persona.

## Why
Feras retired the old 3D game (DECISIONS 2026-10-26); tag `3d-archive` keeps it. Neon Glitch fights on the map
(features/neon/battle/) and never uses the 3D BattleStage. Remove the 3D stage; keep every combat rule and test.

## Read first
docs/archive/design-3d/retire-3d-audit.md (cuts 2 and 3). docs/archive/design-3d/retire-3d/u2_delete.txt (your 45 files).
core/scene_router.gd, core/battle_session.gd, features/dialogue/dialogue_effects.gd, core/defs/flow_rules_def.gd.

## What to do
1. `git rm` every path in u2_delete.txt with its .uid / .import sibling.
2. core/content_db.gd KINDS: remove "arena", "battle_camera", "battle_juice", "transition" (only those lines).
3. Router (core/scene_router.gd): remove the 3D half: stage_created, stage, _port, _session, register_area,
   unregister_area, start_battle, _return_to_area, _capture_frame and whatever only they use. Keep the states,
   flow_changed, save_dir, saves (save_slot, load_slot, has_save, has_any_save, newest_slot, last_slot), new_game,
   go_to_title, quit_game, set_busy, can_save, take_skip_title, scene_reloader. unstuck: keep the method; without an
   area it only resets the busy state.
4. core/event_bus.gd: add `signal battle_requested(request: BattleRequest)`. DialogueEffects' start_battle effect
   emits it instead of calling Router.start_battle (the Neon game will host it later). Keep its parsing.
5. core/defs/flow_rules_def.gd + content/prototype/flow.json: remove arena_id (field, read, references()).
6. Tests: delete the tests whose subject is gone (test_arena, test_battle_camera, test_battle_stage,
   test_battle_view3d, test_battle_hud_style, test_battle_hud_v2, test_battle_hud_v3, test_battle_item_menu, test_vfx
   if it only tests vfx_player). In test_abu_nabil_spar, test_battle_flow, test_battle_menu_support,
   test_pause_safety, test_battle_progression and features/workshop/tests/test_workshop_loot.gd keep every rule:
   drive BattleSim / BattleOutcome directly instead of a stage; delete only cases that test the stage itself.
   Add one test: DialogueEffects "start_battle:<encounter>" emits EventBus.battle_requested with that encounter.
7. tools: delete shot_arena.gd, shot_battle.gd, shot_hud.gd, shot_scene.gd, shot_shatter.gd, vfx_gallery.gd.
8. Grep every removed class_name (BattleStage, BattleSession, AreaPort, ArenaDef, BattleCameraDef, JuiceDef,
   TransitionDef, BattleHud, BattleRunner, VfxPlayer, ...) and res:// path: no kept file may name them.
9. `python tools/map.py` (regenerates docs/MAP.md).

## Do NOT edit
`features/neon/`
`content/neon/`
`features/world/`
`features/prototype/`
`features/map/`
`features/puzzles/`
`features/ui/`
`features/art/`
`features/equipment/`
`features/workshop/view/`
`tools/bake_sprites.gd`
`tools/bake_sprites.tscn`
`assets/`
`content/world/`
`docs/design/`
A parallel run deletes every path in docs/archive/design-3d/retire-3d/u1_delete.txt (world, prototype, map). If one of those
files breaks because of your removal (it names AreaPort, BattleStage, Router.start_battle...), `git rm` it too, and
repeat until everything parses: identical deletions merge cleanly. Never edit a u1_delete.txt file, and never delete
a file outside both lists except the tests and tools named above.

## Tests
- DialogueEffects start_battle emits EventBus.battle_requested (new).
- The kept combat, progression and workshop rules still pass without a stage.

## Checklist
- file: core/scene_router.gd
- has: core/event_bus.gd :: signal battle_requested
- has: core/defs/flow_rules_def.gd :: func references
- test: features/dialogue/tests/test_dialogue_effects.gd :: test_start_battle_emits_battle_requested

## Proof
`bash tools/check.sh` raw last 15 lines; small commits; final message ends with `Built-by: <model> (opencode)`.
