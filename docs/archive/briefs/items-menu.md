# Brief: items-menu (<= 60 lines; after menus-equip-fix merges)
You are in your own worktree on branch oc/items-menu (made from oc/menus-equip-fix3). Follow AGENTS.md and GEMINI.md
<review_misses>. Load the ui-designer skill and the godot-gameplay-scripter skill.

## Why
Feras's playtest (inbox/playtest_08.png): the Items menu "looks so plain, does not show character cards, how the item would affect, and does
not show the top right part shown in equipment where the player can switch from equipment to map and items (can
switch from equipment to map or items, but can't switch back). There are no quick switch buttons."

## Read first
The items screen (grep "Items" in features/ui/view/screens/ and docs/MAP.md), features/equipment/view/
equipment_tabs_bar.gd, equipment_menu.gd, features/map/view/holo_map.gd, features/ui/view/party_card.gd,
docs/design/rpg-menus.md.

## What to build
1. One shared tabs bar (Equipment, Items, Map) on all three screens, same place and look as Equipment's; the current
   tab highlighted; clicking or confirming a tab switches screens from ANY of the three, both ways.
2. Quick switch: LB/RB and Q/E (keyboard) cycle the three tabs on every screen; the prompt strip shows them.
3. Items screen layout like Equipment: item list left; party cards right (portrait, name, HP/SP bars), the selected
   item's effect previewed on each card (e.g. "+120 HP" green bar segment, "cures confusion"), greyed for heroes it
   cannot help; description box at the bottom.
4. Enter on an item, then choose a hero card to use it (field-usable items only); counts update.
5. Renders: inbox/items_menu.png, items_target.png.

## Do NOT edit
`core/save/`
`core/game_state.gd`
`content/items/`
`features/world/`
`tools/check.sh`
`CLAUDE.md`
`docs/DECISIONS.md`
`HANDOFF.md`

## Tests
- From each of the three screens, each other tab is reachable by tab confirm and by LB/RB.
- The effect preview on a hero card equals the item's heal amount clamped by missing HP.

## Checklist
- file: features/equipment/view/equipment_tabs_bar.gd

## Proof
`bash tools/check.sh` raw last 15 lines; renders; final message ends with `Built-by: Gemini 3.8 Flash (agy)`.
