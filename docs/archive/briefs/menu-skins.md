# Brief: menu-skins (<= 60 lines; runs beside rpg-rolls-flee; first menu brief)
You are in your own worktree on branch gemini/menu-skins (made from claude/menus-rpg-5089fa). Follow GEMINI.md, including
<review_misses>. Load the godot-gameplay-scripter skill (.agents/skills/) if one fits.

## Why: Feras approved painted menus (docs/design/rpg-menus.md): every menu pauses over a painted backdrop (or the blurred world), and the pause, save and shop screens take the layouts of his reference pictures.
## Read first
C:/dev/game/inbox/ui_refs/mock_pause.png, mock_save.png, mock_shop.png (layout target; Feras's Gemini mockup: copy its layout, not its names, numbers or glyphs);
docs/design/rpg-menus.md sections 0, 1, 4, 5 (THE SPEC: rects at 1920x1080, style keys); docs/design/ui.md 1-2;
features/ui/view/ui_screen.gd, ui_stack.gd, ui.gd, ui_panel.gd, list_row.gd, party_card.gd, money_counter.gd,
prompt_strip.gd, ui_rarity.gd, screens/pause_menu.gd, pause_party.gd, shop_screen.gd, shop_detail.gd,
slot_picker_screen.gd, confirm_dialog.gd; features/ui/logic/pause_logic.gd; features/art/view/model_materials.gd
(load_texture: the .gdignore'd webp path); core/content_db.gd (KINDS); assets/manifest.json.

## What to build
1. Content: content/ui/backdrops.json, kind "backdrop" (BackdropDef in features/ui/defs/: id, path, dim 0-1 default
   0.35): rows pause, items, equipment, workshop, shop, save, map, path assets/textures/ui_bg/<id>.webp. Register the
   kind in ContentDB.KINDS. The 7 webp files, .gdignore and manifest entries already exist (1376x768, painted).
2. features/ui/view/menu_backdrop.gd (class MenuBackdrop extends Control, full rect, mouse_filter ignore): setup(id)
   loads the webp like ModelMaterials.load_texture (FileAccess bytes -> Image.load_webp_from_buffer); TextureRect
   expand, stretch_mode KEEP_ASPECT_COVERED, then a ColorRect black at alpha `dim`. Missing file -> fallback: copy the
   current viewport texture (get_viewport().get_texture().get_image(), taken in open() BEFORE the screen is added),
   draw it through features/ui/view/menu_blur.gdshader (canvas_item, 2 box-blur passes, radius from style key
   s_backdrop_blur 6) and a ColorRect c_scrim. Headless (no image) -> c_glass_deep fill. Never the clear world.
3. UiScreen gains `var backdrop_id: StringName = &""`; when set, open() puts a MenuBackdrop as the FIRST child.
   Pause sets &"pause", ItemsScreen &"items", ShopScreen &"shop", SlotPickerScreen &"save". Confirm dialogs keep their
   scrim (no backdrop).
4. Pause reskin (rpg-menus.md 1): command panel (80,80) 420x760 with Ui.panel(Ui.text("PAUSE_HEADING"),
   Ui.text("PAUSE_HEADING_MUSNAD")); entries stay PauseLogic's (ListRow height s_list_row_h, focus sweep); info box
   (80,880) 420x100: area name, MoneyCounter, play time (PauseLogic clock text); party panel (540,80) 1300x900, one row
   per hero h 200: face 160x160 (CharacterIcons.texture), name c_brass s_font_title, then a class line, "Lv N" and an XP bar 360x10
   c_cyan: rpg-progression is not built yet, so make them empty, hidden nodes with `TODO(rpg-progression)` (keep space), HP and SP bars 420x14 from PartyCard parts; KO row greyed + "KO" c_bad. PromptStrip at (0,1020).
5. Save/Load reskin (rpg-menus.md 5): title "SAVE GAME"/"LOAD GAME" + the existing SLOT_TITLE_*_MUSNAD keys at
   (560,60) 800x90; three rows 900x190 at (440,180) with thumbnail 300x170, "SLOT 01", area, play time "14h 32m",
   date; details panel (1380,180) 460x620; buttons SAVE|DELETE SLOT|BACK 280x72 at (500,880). Thumbnail: on save
   capture the viewport at 480x270 to user://slots/<n>.png (SaveService owns the slot paths; add the png beside it; the
   ConfirmDialog flows of test_slot_picker.gd keep working). Delete asks ConfirmDialog default No.
6. Shop reskin (rpg-menus.md 4): title from ShopDef keeper + SHOP_HERB_STALL_MUSNAD; grid 3 columns cells 220x170 at
   (80,140) 720x560 (icon 96, name, price c_brass, rarity glow, sold out dim); keeper box (80,720) 620x260 with the
   dialogue portrait + greeting typed; detail (840,140) 560x760 with a per-hero COMPARISON; quantity/owned/money
   after (1440,140) 400x420 (c_bad when < 0); party mini cards (1440,600). Shop rules (Shop, ShopService) unchanged.
7. New style.json keys: s_backdrop_blur 6. New text keys in localization/screens.csv (English only) for every label.

## Do NOT edit
features/world/**, content/world/**, features/combat/**, content/combat/**, core/battle_session.gd, features/items/logic/**,
core/game_state.gd, core/save/save_codec.gd, features/equipment/**, docs/DECISIONS.md, HANDOFF.md, any *.import.
No Arabic script anywhere; Musnad only from existing *_MUSNAD keys.

## Tests (features/ui/tests/test_menu_skins.gd; keep every test in features/ui/tests passing)
backdrops.json loads 7 rows; a missing webp gives the fallback (blur or glass fill), never a bare world; backdrop is
child 0 of pause/items/shop/save; pause party row has the hidden Lv/XP nodes; KO row says "KO";
save thumbnail path is written on save and read in the row; shop money-after is c_bad when short; every rect matches
its spec within 2 px at 1920x1080.

## Proof
`bash tools/check.sh` raw last 15 lines; renders of pause, save and shop (tools/shot_dialogue.tscn as the pattern, a
.tscn wrapper, never `-s` on a Node script) to C:/dev/game/inbox/menu_pause.png, menu_save.png, menu_shop.png; small
WIP commits; final message ends with `Built-by: Gemini 3.8 Flash (agy)`.
