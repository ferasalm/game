# Brief: menus-equip-fix3 (<= 60 lines; fix pass on top of gemini/menus-equip-fix2)
You are in your own worktree on branch oc/menus-equip-fix3 (made from gemini/menus-equip-fix2). Follow AGENTS.md.
Load the godot-gameplay-scripter and ui-designer skills. Read docs/briefs/menus-equip-fix.md and
docs/briefs/menus-equip-fix2.md first: this fixes their review misses and one owner note.

## Why
Feras (2026-10-24, inbox/fix_equip_zayd.png): "the character picture looks trimmed from below": the portrait in the
equipment hero header ends flat at the chest with an empty dark band under it inside its frame. Review: connector
lines meet at shared points; several tests cannot fail.

## What to fix
1. features/equipment/view/equipment_hero_header.gd (~61-80, _face_box 96x96): the portrait fills its whole frame:
   TextureRect expand, STRETCH_KEEP_ASPECT_COVERED, anchored so the head sits in the upper third and the bust runs
   to the frame's bottom edge (no empty band, no flat cut above the frame edge); the frame stays inside the 500x140
   header. Same rule for the pause menu hero cards (features/ui/view/screens/pause_hero_row.gd).
2. Anchors: model_source.gd ~158-168 and pixel_source.gd ~153-159 answer "chest" and "hip" too (from the skeleton or
   pixel bounds, not a guessed height). hologram_stage.gd ~169-186 uses them. Every slot box has its own end point:
   Blade and Armor must not meet at one point, nor Hilt and Prosthetic (equipment_boxes.gd ~14): give each slot a
   distinct anchor (e.g. blade = right hand, hilt = belt front, armor = chest, prosthetic = right forearm, gemstones
   = hip), set in content, not code.
3. Tests that can fail (replace the weak ones):
   - test_equipment_layout.gd ~74: every header label's global rect lies inside the header's global rect.
   - test_equipment_layout.gd ~55: also flag two connectors sharing an end point (distance < 8 px).
   - test_equipment_menu.gd ~113-118: the portrait's global rect equals its frame's inner rect (+-2 px) and the
     texture covers it (no empty band): check the drawn texture rect, not a stretch_mode constant.
   - test_pause_menu.gd ~86, ~93: compare real bar widths after layout at two different HP/SP values, not the shared
     420 minimum.
   - New: the String sort in equipment_owned_list.gd ~82 gives the same order on two runs with names whose
     StringName addresses differ (LESSONS: sort by String).
   Each new test must fail on gemini/menus-equip-fix2 (run it there first; say so in the final message).
4. Renders: inbox/fix_equip_zayd.png, inbox/fix_equip_bilqis.png, inbox/fix_pause.png (tools/shot_menu.tscn).

## Do NOT edit
`core/`
`features/map/`
`features/world/`
`tools/check.sh`
`CLAUDE.md`
`docs/DECISIONS.md`
`HANDOFF.md`

## Tests
Step 3 names them; keep every existing equipment, pause and ui test green.

## Checklist
- file: features/equipment/view/equipment_hero_header.gd
- file: features/equipment/view/hologram_stage.gd
- file: features/equipment/tests/test_equipment_layout.gd
- file: features/ui/view/screens/pause_hero_row.gd

## Proof
`bash tools/check.sh` raw last 15 lines; the three renders; final message ends with `Built-by: <model> (cf)`.
