# Brief: equipment-menu (<= 60 lines; run AFTER rpg-progression AND menu-skins merge)
You are in your own worktree on branch gemini/equipment-menu (made from claude/menus-rpg-5089fa). Follow GEMINI.md,
including <review_misses>. Load the godot-gameplay-scripter skill (.agents/skills/) if one fits.

## Why: Feras approved an equipment menu of its own (rpg-menus.md 2): a turning cyan hologram hero, slots around it.
## Read first
C:/dev/game/inbox/ui_refs/mock_equipment.png (layout target; Feras's Gemini mockup: copy its layout, not its names, numbers or glyphs);
docs/design/rpg-menus.md 0 and 2 (THE SPEC: rects at 1920x1080, focus rules); rpg-systems.md 6-8; features/ui/view/
ui_screen.gd, ui_stack.gd, menu_backdrop.gd, ui.gd, ui_panel.gd, list_row.gd, prompt_strip.gd, ui_rarity.gd;
features/equipment/logic/equipment_options.gd (keep its rules); features/items/logic/gear.gd (Gear.build_hero,
GearState), inventory.gd (equip); features/progression/logic/ (Progression.level); features/art/view/character_visual.gd
(CharacterVisual.new() + set_sprite(hero) builds the 3D model; play(&"idle")); core/game_state.gd (equipment, xp,
sockets).

## What to build
1. features/equipment/view/equipment_menu.gd: class EquipmentMenu extends UiScreen, ID &"equipment", backdrop_id
   &"equipment". Ui.screen_root(); layout exactly rpg-menus.md 2: tabs (80,40) 1760x64 EQUIPMENT | ITEMS | MAP (LB/RB;
   ITEMS opens Screens &"items" in place, MAP is disabled until the holo-map brief), title pair EQUIP_TITLE +
   EQUIP_TITLE_MUSNAD; hero header (80,124) 520x96 (name c_brass, class c_epithet, "Lv N", XP bar 480x10 c_cyan); owned
   list (80,240) 420x620 of ListRow with an "E" chip on the worn item; stats (1400,140) 440x560; description bar
   (80,900) 1760x90; PromptStrip (0,1020) [A] Equip [B] Back [Q/E] Hero [LB/RB] Tab.
2. Slot boxes 150x150 (features/equipment/view/slot_box.gd: icon 96 + label above, c_cyan outline 2 px; focused =
   c_brass 3 px + Ui.sweep): BLADE (600,180), HILT (600,420), GEMSTONES (600,660: 3 sockets 44x44, read only from
   GameState.sockets[worn hilt], empty = dim ring, locked = hidden), ARMOR (1210,180), PROSTHETIC (1210,420). Heroes
   without a slot (EquipmentOptions.parts_for) hide that box (Bilqis: only ARMOR and PROSTHETIC).
3. features/equipment/view/hologram_stage.gd: a SubViewportContainer at (560,140) 800x760 holding a transparent
   SubViewport (own_world_3d true, transparent_bg true), a Camera3D framing a 1.8 m figure, one DirectionalLight3D
   (flat), the hero's CharacterVisual playing idle, turning 20 deg/s (process_mode ALWAYS: the tree is paused), a cyan
   grid disc under the feet (a flat CylinderMesh 0.9 m, unshaded, c_cyan alpha 0.3). Overlay
   features/equipment/view/hologram.gdshader on the model surfaces (spatial, unshaded, blend_add: c_cyan fresnel rim,
   scanlines 3 px moving up, alpha 0.85) via ModelMaterials' material list (set next_pass; never edit
   character_skin.gdshader). Leader lines: Line2D 2 px c_cyan from each box edge to the projected body point
   (CharacterVisual.anchor_position: hand, belt, chest, arm; Camera3D.unproject_position).
4. Focus: d-pad between slot boxes; A on a box moves focus to its owned list; A on an item wears it at once through
   Inventory.equip into GameState.equipment (no Confirm step); focusing an item updates the stats preview; B returns
   to the boxes, B again closes. Q/E switch hero.
5. Stats rows (label | now | arrow | after, after c_good if higher, c_bad if lower): HP, SP, ATK, DEF, AGI, LCK, WT,
   then Hit %, Crit %, Flee % vs an AGI-40 foe (BattleRolls' pure formulas; read only). "Now" = BattleLoader.hero_from_state(hero, GameState) (features/combat/harness/battle_loader.gd: the
   real GearState build; reuse it, do not copy it), "after" = with the focused item swapped in.
6. Register: in ui_stack.gd BOTH `register(EQUIPMENT_ID, ...)` and `register(WORKSHOP_ID, ...)` return EquipmentMenu.new()
   (only those two lines; workshop-menu takes WORKSHOP_ID later). Delete
   features/ui/view/screens/equipment_host.gd, features/equipment/view/equipment_screen.gd, equipment_page.gd,
   equipment_demo.* and their tests' screen parts (keep the EquipmentOptions tests). Pause "Equipment" opens it.
7. Text keys (English) in localization/screens.csv; EQUIP_TITLE_MUSNAD,𐩱𐩡𐩲𐩵𐩠 (copy these exact letters).

## Do NOT edit
features/world/**, content/world/**, features/combat/**, features/items/logic/**, features/progression/**,
core/game_state.gd, core/save/**, ui_stack.gd except the two register lines,
features/art/view/character_skin.gdshader, docs/DECISIONS.md, HANDOFF.md, any *.import. No Arabic script anywhere.

## Tests (features/equipment/tests/test_equipment_menu.gd)
Screens.open(&"equipment") gives an EquipmentMenu; Bilqis shows 2 boxes, Zayd 5; A on an item writes GameState.equipment;
an item not owned never lists; the preview after-value equals Gear.build_hero with the swap; sockets show the worn hilt's
stones and hide locked ones; Q/E cycles heroes; B twice closes and restores focus; the SubViewport exists with a
CharacterVisual child and keeps turning while paused; rects match the spec within 2 px.

## Proof
`bash tools/check.sh` raw last 15 lines; render C:/dev/game/inbox/menu_equipment.png (a .tscn wrapper like
tools/shot_dialogue.tscn, non-headless); small WIP commits; final message ends with `Built-by: Gemini 3.8 Flash (agy)`.
