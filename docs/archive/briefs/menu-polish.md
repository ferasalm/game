# Brief: menu-polish (<= 60 lines; after menu-skins and rpg-progression merged into claude/menus-rpg-5089fa)
You are in your own worktree on branch gemini/menu-polish (made from claude/menus-rpg-5089fa). Follow GEMINI.md, including
<review_misses>. Load the godot-gameplay-scripter skill.

## Why: the menu-skins pass has the right layout but looks flat next to Feras's mockups (opaque panels, empty faces and
icons, plain buttons, small text). Make pause, save and shop look like C:/dev/game/inbox/ui_refs/mock_pause.png,
mock_save.png, mock_shop.png (copy their look, not their names, numbers or glyphs). Current renders:
C:/dev/game/inbox/menu_pause.png, menu_save.png, menu_shop.png.

## Read first
docs/design/rpg-menus.md 0, 1, 4, 5; docs/design/ui.md 1-2; features/ui/view/ui_theme.gd, ui_panel.gd, ui_boxes.gd,
ui.gd, character_icons.gd, list_row.gd; features/ui/view/screens/pause_menu.gd, pause_party.gd, pause_hero_row.gd,
shop_*.gd, slot_picker_screen.gd, slot_detail.gd; tools/shot_menu.gd (the render tool); features/progression/logic/
progression.gd; content/progression/*.json; content/ui/style.json.

## What to build
1. Glass: menu panels use a new style colour c_glass_menu "#161230b8" (backdrop visible through them) with the brass
   frame; panels size to their content (the pause party panel ends under the last hero row, no empty half screen).
2. Faces: pause rows (160x160), shop party minis and save details show the hero's painted portrait
   (assets/portraits/<hero>_neutral.png, cropped to the head: top 38% of the image, centred square) through one new
   helper features/ui/view/portrait_faces.gd (cached, falls back to CharacterIcons.texture). The style.json `icons`
   paths point at a missing assets/icons/ folder: report it, do not invent files.
3. Item icons: find how ConsumableDef.icon resolves (grep "icon" in features/items and features/ui); where the file is
   missing draw a 96 px rarity-coloured disc with the item's first letter (one helper, reused by shop cells and
   detail); list missing icon files in your final message.
4. Title plates: screen titles sit in a brass plate (Ui.title_pair inside a framed PanelContainer, s_font_title + 8)
   with the Musnad title on both sides like the mockups; MoneyCounter top right in a framed pill.
5. Buttons and focus: big buttons (SAVE, DELETE SLOT, BACK, shop tabs) become framed pills (StyleBoxFlat corner radius
   10, border 2 px c_brass, focus border c_cyan + Ui.sweep); list rows keep ListRow. All sizes from style.json keys.
6. Text: nothing below s_font_small (20 px) on these screens; numbers in s_font_number; HP/SP bars 14 px with numbers.
7. Pause rows now show the class (ClassDef name_key via ContentDB "class", c_epithet), "Lv N" from
   Progression.level(GameState.xp[hero]) and the XP bar 360x10 c_cyan with "have/next" (remove the
   TODO(rpg-progression) hides).
8. Shop detail: per-hero comparison rows "HP 450 -> 510 (+60)" with a c_good up arrow (ItemsText helpers), quantity
   arrows < 01 > in framed pills.
9. Re-render all three with tools/shot_menu (non-headless) at 1920x1080 to the same inbox paths.

## Do NOT edit
features/world/**, content/world/**, features/combat/**, features/progression/**, features/items/logic/**,
core/save/**, assets/** (read only), docs/DECISIONS.md, HANDOFF.md, any *.import. No Arabic script anywhere.

## Tests (features/ui/tests/test_menu_polish.gd; keep every UI test passing)
portrait_faces returns a texture for zayd and bilqis and the fallback for an unknown id; the pause row shows "Lv 1"
and the class name for a fresh game and "Lv 2" after enough xp; the disc fallback is used when an icon file is
missing; no Label on pause/save/shop is smaller than s_font_small; panel colour is c_glass_menu.

## Proof
`bash tools/check.sh` raw last 15 lines; the three renders; small WIP commits; final message ends with
`Built-by: Gemini 3.8 Flash (agy)`.
