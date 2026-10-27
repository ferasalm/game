# Retire the 3D game: audit, removal plan, lessons (2026-10-26)
DECISIONS 2026-10-26: audit 3D-only vs shared, then remove 3D-only code, assets and tests; git tag `3d-archive`
keeps the whole 3D game. Neon Glitch (`features/neon/`, main scene `neon_game.tscn`) must play the same after it.

## Method (import graph, not guesses)
A script read every tracked file (1656 without .uid/.import) and drew an edge for each `res://` path, `uid://`,
class_name token, autoload name, `ContentDB.get_def/ids("<kind>")` call (to that kind's JSON files) and Def
`references()` kind (JSON -> Def -> referenced kinds). Reach from (a) = `features/neon/**` + project.godot +
`tools/bake_sprites.*` + `tools/shot_neon_*`; (b) = the shared roots below. Tests are never roots: a test belongs
to the class of what it tests. Registry fan-out (ContentDB loading every JSON, runner.gd finding every test,
AssetManifest checking every asset) is not counted as use.

## Classification (folder level; file lists in docs/design/retire-3d/)
| Area | Class | Note |
|---|---|---|
| features/neon/, content/neon/, assets/sprites/neon, assets/textures/neon, assets/video | a | the game |
| core/ (EventBus, GameState, ContentDB, TextDB, AudioDirector, save/, defs/) | a/b | battle_session, area_port: c |
| features/combat/logic, defs, harness; combat/view: command menu, menu chips, flee button, style, timeline bar/ghost/track art, vfx_sprite/textures | a/b | Neon's map battle uses these |
| features/combat/view: arena, BattleStage, battle camera, 3D HUD, runner, event players, shatter, vfx_player (42 files) | c | the 3D battle stage |
| features/progression, items, jambiyah, prosthetics, dialogue, workshop logic, audio | b | RPG layer (plan: carries over) |
| features/ui (UI kit, Screens stack, pause/items/shop/slot/sabil/defeat screens), equipment + workshop menus | b | menus carry over; their 3D hologram is c |
| Router (core/scene_router.gd) | b, trimmed | saves, title/new game, busy state stay; area port + 3D battle half go |
| features/art/view (CharacterVisual, ModelRig, retarget) + content/art | a | tools/bake_sprites makes Neon's sprites from them |
| assets/characters Rodin models (rydan, concession_enforcer, zayd, bilqis, abu_nabil, survey_drone) + UAL clips, skins | a | bake sources; all kept (Bilqis, Abu Nabil, drone get baked later) |
| features/puzzles/logic, defs, light_lock/water_net content and logic tests | b | pure; whether level-1 puzzles return is open (plan) |
| features/world/** (rooftop, interact, interior, weather, player, patrol, views, painted world) | c | the 3D world |
| features/prototype/**, content/prototype (except flow_rules) | c | the 3D prototype scene |
| features/map/** (holo map of level 1's areas), content/ui/map.json, content/world/* | c | |
| features/puzzles/view/** (grey-box yard), content/puzzles/puzzle_yard.json | c | |
| assets/textures/painted/oil, wash, figures (3D facade and figure paint) | c | painted/skin stays (model skins) |
| 3D render and probe tools (shot_level1, shot_arena, shot_holo_map, shot_models, ...) | c | shot_neon_*, bake_sprites, shot_menu stay |
| 3D budget assertions (test_model_defs budgets), 3D stage/world tests (86 of 151 test files) | c | rig and retarget tests stay |

## Where shared code reaches the 3D game (the cuts)
1. `tools/bake_sprites.gd` -> PaintedLook, Diorama, look.json -> PaintedMaterials -> TowerHouse, PropMesh, all
   oil/wash textures. Cut: the baker builds its own environment and light (pixel-identical bake, verified).
2. AudioDirector -> MusicDeck -> flow_rules (content/prototype/flow.json) `arena_id` -> arenas.json -> ArenaDef ->
   look, tile, skyline, AreaDef. Cut: drop arena_id; remove the arena, battle_camera, battle_juice, transition kinds.
3. Router -> BattleSession -> BattleStage, and Router -> AreaPort. Cut: Router keeps flow + saves; DialogueEffects'
   battle effect emits an EventBus request instead of calling Router.start_battle.
4. Screens (ui_stack) -> HoloMap; equipment HologramStage and WorkshopHologram (3D model in a SubViewport). Cut: no
   map screen registered (the pause menu already greys Map when absent); the holograms draw the hero's Neon sprite.
5. PauseMenu -> AreaDef, SlotRow -> areas.json (area names). Cut: no area name line.
After 1-5 the remaining world defs/views (docs/design/retire-3d/kept_until_sweep.txt, 69 files) have no kept user
and go in the sweep, with the painted textures and orphaned base meshes (checked against model_materials paths).

## Removal plan (3 DeepSeek runs in parallel, then a sweep)
| Run | Brief | Owns |
|---|---|---|
| retire-3d-world | docs/briefs/retire-3d-world.md | u1_delete.txt (170: world, prototype, map, puzzle view), ui_stack, pause/slot rows, world tools |
| retire-3d-battle | docs/briefs/retire-3d-battle.md | u2_delete.txt (45: 3D stage, BattleSession, AreaPort), Router, DialogueEffects, flow_rules, battle tools |
| retire-3d-bake | docs/briefs/retire-3d-bake.md | bake_sprites decoupling, both holograms, model budget test, model/prop tools |
Then Claude: merge the three, rerun the graph, delete what fell out (kept_until_sweep + assets + manifest
entries), ContentDB KINDS, docs pointers, one check.sh, the Neon render, MAP.md from a clean worktree, main.
Gate before main: `git diff --stat main -- features/neon` is empty.

## What the 3D game taught us (bottlenecks -> changes for Neon)
Numbers: 556 commits in 7 days; 192 touched code now retired; 57 of 69 briefs were 3D-era; 86 of 151 test files.
| Bottleneck | Evidence | Change for Neon (proposal; Feras decides) |
|---|---|---|
| The look changed three times after systems were built on it | painted 3D -> 2D redesign -> Neon in 5 days; a third of all commits retired | Look gate: no system work in a scene until Feras OKs a render of it from the play camera |
| Shared code wired to one game mode | Router, menus, flow_rules, the sprite baker all pulled in the 3D world | Shared code never names a scene, look or mode; a lint rule: logic/defs/ui may not reference features/neon or a mode folder |
| Builders weakened tests and assets to go green | a model shrunk for a budget test, two art tests loosened | Briefs list tests and assets as Do NOT edit; the gate flags removed asserts and binary changes as BREACH |
| Test weight | 86 scene-heavy test files, a 600 s cap, 2 suites machine-wide | Pure logic tests first; scene tests one or two per feature; the suite stays under 5 minutes |
| Visual quality is not caught by check.sh | cones for herbs, gems for a sabil; renders judged late | Builders wire code only; looks come from Feras's plates and Flow; every visual brief ends in a render Claude judges |
| Memory and stalls | 4 runs froze the PC; agy sat 55 min; opencode hung on stdin | <= 3 runs, no Godot of ours while Feras plays; timeouts on every child; DeepSeek for code |
| Merge friction in registries | ContentDB KINDS and MAP.md conflicts in most merges | Defs register their own kind (KINDS built from a folder scan) so parallel runs stop colliding |
| Slow feedback from playtests | notes arrive as chat text after a session | A playtest capture key (screenshot, his circles, a state dump into inbox/) |
