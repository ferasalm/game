# Brief: retire-3d-bake (sprite baker and menu holograms off the 3D world; <= 60 lines)
You are in your own worktree on your own branch made from claude/retire-3d-6d2a28. Follow AGENTS.md, including
<review_misses>. Load the godot-gameplay-scripter skill and the minimal-change-engineer persona.

## Why
Feras retired the old 3D game (DECISIONS 2026-10-26). Neon draws characters as baked sprites, none in 3D at runtime
(DECISIONS 2026-10-24). Two shared pieces still pull the 3D world in: the sprite baker and the menu holograms.

## Read first
docs/archive/design-3d/retire-3d-audit.md (cuts 1 and 4). tools/bake_sprites.gd (its header has the run command),
features/world/view/diorama.gd (make_environment, make_sun), features/world/view/painted_look.gd (begin),
features/equipment/view/hologram_stage.gd, features/workshop/view/workshop_hologram.gd, content/neon/sprites.json.

## What to do
1. Before any edit, bake one sheet as the reference: run bake_sprites (not headless) for model `rydan`, state
   idle:8:1.0, into C:/dev/game/inbox/bake_ref/. Only one Godot process of yours at a time.
2. tools/bake_sprites.gd: stop using PaintedLook, Diorama, LookDef and ContentDB "look". Build the WorldEnvironment
   and the key light in the baker itself (or a new tools/bake_light.gd), copying the values the "painted_b" look
   gives today (background clear, tonemap, exposure, adjustments, sun direction/colour/energy). Constants are fine in
   a tool. Bake the same sheet into C:/dev/game/inbox/bake_new/ and compare every frame with Pillow: max channel
   difference <= 2. Write the number in the commit message. If it is higher, fix the light; never loosen the check.
3. Menu holograms: HologramStage (equipment) and WorkshopHologram stop building a 3D model in a SubViewport. Keep
   both class names and their public methods; they now show the hero's Neon idle sprite facing the camera (row 6,
   frame 0 of the "idle" sheet in content/neon/sprites.json, via NeonSpriteSetDef), scaled to fit their rect.
   Body anchor points the menus ask for come from fractions of that rect (head, chest, hand, belt), as content.
   Heroes without a Neon sprite set show their portrait (Portraits) instead.
4. features/art/tests/test_model_defs.gd: models are offline sprite sources now. Remove only the runtime budget
   assertions (triangles, texture size) in test_the_bodies_keep_the_rig_and_the_budgets; keep the rig checks.
5. tools: delete shot_models.gd and shot_prop.gd/.tscn. shot_menu.gd keeps working with the new holograms.
6. Tests: update test_equipment_menu, test_equipment_polish, test_equipment_layout and test_workshop_menu only where
   they assert the 3D stage; add one test: the hologram shows the Neon sprite texture for rydan and a portrait for
   a hero without a sprite set.
7. `python tools/map.py` (regenerates docs/MAP.md). Render the equipment menu with tools/shot_menu.tscn into
   C:/dev/game/inbox/menu_equipment_2d.png.

## Do NOT edit
`features/neon/`
`content/neon/sprites.json`
`assets/`
`features/art/view/`
`features/world/`
`features/combat/`
`features/ui/`
`features/prototype/`
`features/map/`
`core/scene_router.gd`
`core/event_bus.gd`
`core/defs/`
`docs/design/`
`tools/art/`
Content for the anchor fractions goes in a new file content/ui/hologram_2d.json with its own Def; register its
kind with one new line in core/content_db.gd KINDS (the only core edit).

## Tests
- The equipment and workshop holograms build without any 3D node (no SubViewport, no Node3D) (new).
- Bake reference vs new bake: max channel difference <= 2 (in the commit message, not a Godot test).

## Checklist
- file: tools/bake_sprites.gd
- file: features/equipment/view/hologram_stage.gd
- file: features/workshop/view/workshop_hologram.gd
- test: features/equipment/tests/test_equipment_menu.gd :: test_hologram_is_a_neon_sprite

## Proof
`bash tools/check.sh` raw last 15 lines; renders to C:/dev/game/inbox/; small commits; final message ends with
`Built-by: <model> (opencode)`.
