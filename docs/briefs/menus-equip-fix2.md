# Brief: menus-equip-fix2 (<= 60 lines; fix pass on top of gemini/menus-equip-fix)
You are in your own worktree on branch gemini/menus-equip-fix2 (made from gemini/menus-equip-fix). Follow GEMINI.md,
including <review_misses>. Load the godot-gameplay-scripter skill. Read docs/briefs/menus-equip-fix.md first.

## Why
Review + renders (inbox/fix_equip_zayd.png, fix_equip_bilqis.png) of menus-equip-fix found these misses.

## What to fix
1. Header card text is clipped ("(Courier) Lv 1" and "0/60" cut off): widen the card or shrink the font so all text
   fits; >= 16 px gap to INVENTORY and to the title bar; test that every label's text width fits its rect.
2. Gemstones on a fresh game: equipment_owned_list.gd ~41 and equipment_data.gd ~34 read the hilt only from
   GameState.equipment; fall back to the loadout like equipment_boxes.gd ~57-59, so aqiq_red shows its "E" chip and
   the description. Test on GameState.start_new().
3. Restore the deleted test test_subviewport_and_character_visual_turns_while_paused (test_equipment_menu.gd ~86)
   and make it pass.
4. hologram_stage.gd ~173: leader lines end at the model's real anchors (_visual.anchor_position) again; the
   no-crossing rule is kept by ordering boxes, not by fixed points; line widths from content/ui/style.json.
5. portrait_faces.gd ~9: keep the head crop for existing callers (shop_party_mini.gd, slot_detail.gd); add a new
   function for the whole-bust portrait used by the equipment header and pause cards; fix the ~25 comment.
6. equipment_data.gd ~41 worn_item: restore the "not in equipment" guard; armor must never fall back to the
   prosthetic; description and E chip agree (test for armor on a fresh game).
7. Tests that cannot fail: test_pause_menu.gd ~90 compares the real bar rects of both cards; test_equipment_menu.gd ~96
   checks the portrait rect lies inside its frame with the texture aspect kept.
8. equipment_owned_list.gd ~80: sort by String(id), not StringName.
9. slot_box.gd ~165: mouse hover must not steal focus from the list while in LIST mode.
10. Renders again: inbox/fix_equip_zayd.png, fix_equip_bilqis.png, fix_pause.png.

## Do NOT edit
`core/save/`
`core/game_state.gd`
`content/items/`
`features/map/`
`features/world/`
`tools/check.sh`
`CLAUDE.md`
`docs/DECISIONS.md`
`HANDOFF.md`

## Tests
Steps 1, 2, 3, 6 and 7 name their tests.

## Checklist
- file: features/equipment/view/hologram_stage.gd
- file: features/ui/view/portrait_faces.gd
- file: features/equipment/view/equipment_data.gd

## Proof
`bash tools/check.sh` raw last 15 lines; renders; final message ends with `Built-by: Gemini 3.8 Flash (agy)`.
