# Brief: retire-3d-world (remove the 3D world, prototype, holo map, puzzle yard view; <= 60 lines)
You are in your own worktree on your own branch made from claude/retire-3d-6d2a28. Follow AGENTS.md, including
<review_misses>. Load the godot-gameplay-scripter skill and the minimal-change-engineer persona.

## Why
Feras retired the old 3D game (DECISIONS 2026-10-26); tag `3d-archive` keeps it. Neon Glitch (features/neon/) never
uses the 3D world, the prototype scene, the level-1 holo map or the grey-box puzzle yard. Remove them; the shared
menus (Screens, pause, items, shop, slot picker) keep working.

## Read first
docs/archive/design-3d/retire-3d-audit.md (cuts 4 and 5). docs/archive/design-3d/retire-3d/u1_delete.txt (your 170 files) and
kept_until_sweep.txt (69 files you must NOT delete: a later sweep does). features/ui/view/ui_stack.gd,
features/ui/view/screens/pause_menu.gd, features/ui/view/screens/slot_row.gd.

## What to do
1. `git rm` every path in u1_delete.txt with its .uid / .import sibling.
2. core/content_db.gd KINDS: remove the lines whose Def file you deleted (explore_rules, storm, camera_rig,
   camera_preset, room, map_marker, city_district, map_info, and any other now-missing preload). Only those lines.
3. ui_stack.gd: stop registering the holo map screen. The pause menu already greys Map when no map screen exists
   (Screens.has_screen); the Equipment/Items tabs bar must skip a missing Map tab the same way.
4. pause_menu.gd and slot_row.gd: drop the area-name line (AreaDef / areas.json lookups); everything else stays.
5. Tests: features/world/tests, features/prototype/tests, features/map/tests, the puzzle view tests go with their
   code. In features/puzzles/tests (test_puzzle_board, test_puzzle_place), features/ui/tests (test_menu_tabs,
   test_popups) and features/combat/tests (test_abu_nabil_spar, test_battle_flow) delete only the test functions
   that need a deleted file; keep every other rule. Add one test: the tabs bar and pause menu work with no map screen.
6. tools: delete export_atlases.gd, flicker_probe.gd/.tscn, shot_battle.gd, shot_camera_v2, shot_dialogue,
   shot_focus, shot_holo_map, shot_level1, shot_puzzles, shot_souq_place, shot_tayramana, shot_workbench,
   smoke_new_game (each .gd with its .tscn). tools/fps_probe.gd: if its default scene is gone, use
   res://features/neon/neon_game.tscn.
7. Grep every removed class_name and res:// path (rooftop, PrototypeMain, HoloMap, PuzzleYard, AreaBuilder, ...):
   no kept file may name them. A file in kept_until_sweep.txt that breaks: tell it in the final commit message;
   do not delete it.
8. `python tools/map.py` (regenerates docs/MAP.md).

## Do NOT edit
`features/neon/`
`content/neon/`
`core/scene_router.gd`
`core/area_port.gd`
`core/battle_session.gd`
`core/event_bus.gd`
`core/defs/`
`features/combat/view/`
`features/combat/defs/`
`features/art/`
`features/equipment/view/equipment_menu.gd`
`features/equipment/view/hologram_stage.gd`
`features/workshop/view/`
`features/dialogue/`
`tools/bake_sprites.gd`
`tools/bake_sprites.tscn`
`assets/`
`docs/design/`
A parallel run removes Router's area/battle half and AreaPort. If a deleted world file was their only caller, fine.

## Tests
- Tabs bar and pause menu with no map screen registered (new).
- Every kept menu, puzzle-logic, combat and dialogue rule still passes.

## Checklist
- file: features/ui/view/ui_stack.gd
- file: features/ui/view/screens/pause_menu.gd
- test: features/ui/tests/test_menu_tabs.gd :: test_tabs_skip_missing_map

## Proof
`bash tools/check.sh` raw last 15 lines; small commits; final message ends with `Built-by: <model> (opencode)`.
