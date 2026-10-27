# Brief: menus-equip-fix (<= 60 lines)
You are in your own worktree on branch gemini/menus-equip-fix (made from origin/main). Follow GEMINI.md, including
<review_misses>. Load the godot-gameplay-scripter skill.

## Why
Feras's playtest (inbox/playtest_03.png, inbox/playtest_09.png, inbox/playtest_10.png) screenshots of the Equipment and Pause menus: "fix how bad it's made".

## Read first
features/equipment/view/*.gd, features/equipment/tests/test_equipment_menu.gd, features/ui/view/party_card.gd,
features/ui/view/screens/pause_menu.gd, features/ui/tests/test_pause_menu.gd, docs/design/rpg-menus.md.

## What to build (1920x1080 layout; every number from content/ui/style.json or the existing layout consts' source)
1. Equipment header card (portrait, name, class, HP/SP/XP) overlaps the INVENTORY panel: give it its own row; the
   portrait is shown whole (no crop), the XP bar visible; INVENTORY starts below it with >= 16 px gap.
2. Slot boxes: connector lines run from each box's inner edge to a fixed anchor on the hologram (chest, hand, hip),
   never crossing another box or each other; the selected slot is highlighted.
3. Focus: moving the cursor onto an equipped slot shows that slot's alternatives in the left list at once (no Enter
   needed); Enter moves focus into the list; Esc goes back to the slots.
4. Gemstones slot is selectable like the others and lists owned gemstones (socket rules stay as they are).
5. Pause menu party cards: portraits fill their frame (same aspect, centred, no crop of the face, same size per hero)
   like the equipment header portrait; HP/SP bars aligned on one column.
6. Renders: tools/shot_menu (or a new tools/shot_equipment.tscn) to C:/dev/game/inbox/fix_equip_zayd.png,
   fix_equip_bilqis.png, fix_pause.png.

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
- Header card rect and INVENTORY rect do not intersect; portrait rect inside its frame with the image aspect kept.
- Hovering an equipped slot fills the list without pressing confirm.
- The Gemstones slot can take focus and lists gemstones.
- No two connector lines intersect.

## Checklist
- file: features/equipment/view/equipment_menu.gd
- file: features/equipment/tests/test_equipment_menu.gd
- file: features/ui/view/screens/pause_menu.gd

## Proof
`bash tools/check.sh` raw last 15 lines; the three renders; final message ends with `Built-by: Gemini 3.8 Flash (agy)`.
