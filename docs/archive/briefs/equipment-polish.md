# Brief: equipment-polish (<= 60 lines; after menu-polish merges into claude/menus-rpg-5089fa)
You are in your own worktree on branch gemini/equipment-polish (made from claude/menus-rpg-5089fa). Follow GEMINI.md,
including <review_misses>. Load the godot-gameplay-scripter skill.

## Why: the equipment menu works, but the hero shows in full colour, not as Feras's cyan hologram; compare the render
C:/dev/game/inbox/menu_equipment.png with his mockup C:/dev/game/inbox/ui_refs/mock_equipment.png (copy its look, not
its names, numbers or glyphs).

## Read first
docs/design/rpg-menus.md 2; features/equipment/view/equipment_menu.gd, hologram_stage.gd, hologram.gdshader,
slot_box.gd, equipment_stats_panel.gd, equipment_hero_header.gd; features/art/view/model_materials.gd (how every
surface's ShaderMaterial is reached); features/ui/view/portrait_faces.gd and the menu-polish helpers (glass colour,
framed pills, icon disc fallback); tools/shot_menu.gd.

## What to build
1. Hologram: the model reads as one cyan light figure: every surface gets the hologram as an override, not a
   next_pass (monochrome c_cyan, fresnel rim brighter at the edges, scanlines 3 px moving up, alpha 0.85, unshaded,
   additive); the original painted colours must not show. Keep the idle clip and the 20 deg/s turn. A cyan grid disc
   (lines every 0.15 m, fading at the rim) under the feet, as in the mockup.
2. Slot boxes show the worn item's icon 96 px (the menu-polish disc fallback when the file is missing) and its name
   under the box (s_font_small, rarity colour); empty slot = dim ring.
3. Stats panel: a header row "Now | After" (c_muted); after-values with a c_good up arrow or c_bad down arrow.
4. Hero header: the portrait face 96x96 (portrait_faces), name, class, "Lv N", HP/SP bars and the XP bar like the
   mockup's top-left card.
5. Panels use c_glass_menu (backdrop visible), titles in the framed plate of menu-polish.
6. Re-render C:/dev/game/inbox/menu_equipment.png (non-headless, tools/shot_menu).

## Do NOT edit
features/world/**, content/world/**, features/combat/**, features/progression/**, features/items/logic/**, core/**,
features/art/view/character_skin.gdshader, assets/**, docs/DECISIONS.md, HANDOFF.md, any *.import. No Arabic script.

## Tests (features/equipment/tests/test_equipment_polish.gd)
every MeshInstance3D under the hologram stage has the hologram material as material_override; a worn blade's box shows
its name; an empty slot shows the dim ring; the stats header has Now and After; the hero header shows "Lv 1" on a
fresh game.

## Proof
`bash tools/check.sh` raw last 15 lines; the render; small WIP commits; final message ends with
`Built-by: Gemini 3.8 Flash (agy)`.
