# Brief: items-menu-fix (<= 60 lines; fix pass on oc/items-menu-fix = oc/items-menu merged onto oc/menus-equip-fix4)
You are in your own worktree on branch oc/items-menu-fix (it already exists: Claude merged oc/items-menu onto
oc/menus-equip-fix4 in commit 31299a9, keeping fix4's art and pause files). Follow AGENTS.md. Load the ui-designer
and godot-gameplay-scripter skills. Read docs/briefs/items-menu.md first.

## Why
Review and renders (inbox/items_menu.png, inbox/items_target.png, 2026-10-24) plus Feras's key decision.

## What to fix
1. Keys (Feras, DECISIONS 2026-10-24): Q/E (LB/RB) switch the hero again in the Equipment menu (equipment_menu.gd
   ~86-88 forwards them to tabs now; restore cycle_hero and the "hero" prompt ~29-32). Tab / Shift+Tab (LT/RT) and
   mouse clicks switch the Equipment / Items / Map tabs (equipment_tabs_bar.gd). Prompts at the bottom show both.
   Tests: Q/E change the hero; Tab changes the tab; a real click on a tab button (emit its pressed signal or a
   mouse event, not press_tab()) changes the tab (test_menu_tabs.gd ~13).
2. Whole-party items: qishr_cup (content/items/consumables.json target all_allies) uses ITEMS_USE_PARTY: one confirm
   heals every living hero; the preview shows the gain on every card at once; no card is greyed as "full" while
   another hero can still gain. Test with a full Zayd and a hurt Bilqis.
3. Preview on the bar (brief item 3): the gain is a green segment on the HP (or SP) bar itself from current to
   current+gain (capped at max), not a separate thin bar (party_card.gd ~151-166). Remove the separate bar; it also
   overflows the card's bottom border in items_target.png.
4. Portraits: the hero cards show the painted bust (PortraitFaces.bust, as the pause cards do), not the letter
   discs "Z"/"B". Cards are larger (fill about 60% of the Use-on panel width side by side, centred vertically).
5. Hint text: "Focus an item to preview it." must not show while an item is focused; "Choose a hero card to use it
   on." shows only in target mode.
6. Ui.toast takes a localization key (toast_host.gd ~4): items_screen.gd ~128, ~133 pass keys, not translated text.
   Delete the dead ItemsText.preview (items_text.gd ~6). test_items_menu.gd ~23: expected value is a literal.
7. features/map/view/holo_map.gd ~45 "Souq al-Milh" literal -> its existing localization key. Change nothing else in
   features/map/.
8. Renders: inbox/items_menu.png, inbox/items_target.png, inbox/fix_equip_zayd.png (tools/shot_menu.tscn).

## Do NOT edit
`core/save/`
`core/game_state.gd`
`features/art/`
`features/world/`
`tools/check.sh`
`CLAUDE.md`
`docs/DECISIONS.md`
`HANDOFF.md`

## Tests
Steps 1, 2, 6 name them; every new test must fail before your fix. Keep all equipment, ui, items and pause tests green.

## Checklist
- file: features/equipment/view/equipment_menu.gd
- file: features/ui/view/party_card.gd
- file: features/ui/view/screens/items_screen.gd

## Proof
`bash tools/check.sh` raw last 15 lines; the three renders; final message ends with `Built-by: <model> (cf)`.
