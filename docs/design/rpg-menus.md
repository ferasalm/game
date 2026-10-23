# RPG menus (v1, 2026-10-23; approved by Feras; layouts judged against inbox/ui_refs/01-09)
Systems: docs/design/rpg-systems.md. Look: docs/design/ui.md sections 1-2 (components, focus sweep, motion) with ONE
change: titles pair English with **Musnad** (DECISIONS 2026-10-22), never Arabic script; ui.md's Arabic title pairs
are void. Rects are (x, y) WxH at 1920x1080; colours are content/ui/style.json keys. Every screen is a UiScreen on
Screens (it pauses the tree), built from the existing helpers: UiPanel, ListRow, PartyCard, MoneyCounter,
PromptStrip, ConfirmDialog, Toast, UiRarity. Hologram accents use c_cyan; brass stays the frame colour.

## 0. Backdrops (every menu) and the camera zoom
- content/ui/backdrops.json, kind "backdrop": id = screen id (pause, items, equipment, workshop, shop, save, map),
  path = assets/textures/ui_bg/<id>.webp, dim (0-1, default 0.35). Loaded through the .gdignore'd webp path
  (Image.load_webp_from_buffer, like ModelMaterials.load_texture); each file gets a manifest entry.
- Missing file -> fallback: the last rendered frame of the world (viewport texture copied on open), blurred (a
  canvas_item shader, 2 passes) and darkened by c_scrim. The world never shows unblurred behind a menu.
- Backdrop TextureRect full screen, layer under the screen's panels, `stretch_mode` keep-aspect-covered.
- Camera zoom (shop, workshop, sabil): pressing interact eases the world camera in t_focus_zoom 0.6 s to the spot's
  framed shot (content: spot "focus" {offset, look_at, fov}), then opens the menu; on close it eases back
  t_focus_zoom. Input is blocked during the ease. Reuses the dialogue framing helper.

## 1. Pause / main menu (ref 02)
```
(80,80) 420x760 command panel, title "MENU" + Musnad      (540,80) 1300x900 party panel, one row per hero (h 200)
 1 Items  2 Equipment  3 Map  4 Load  5 Title  6 Quit      row: face 160x160 | name (c_brass, s_font_title) + class
 (rows s_list_row_h, focus sweep)                           (c_epithet) | "Lv 3" + XP bar 360x10 (c_cyan, "120/280")
(80,880) 420x100 info box: area name, riyal (MoneyCounter),  | HP bar + SP bar 420x14 with numbers (PartyCard parts)
 play time 01:24:07                                         KO row: face greyed, "KO" c_bad
(0,1020) PromptStrip: [A] Select  [B] Resume
```
Load, Title, Quit keep their ConfirmDialogs (PauseLogic). Equipment opens the new equipment screen, Map the map.

## 2. Equipment (refs 08, 03, 01): hologram hero in the centre, slots around
```
(80,40) 1760x64 tabs: EQUIPMENT | ITEMS | MAP (LB/RB; Items and Map open those screens in place)
(80,124) 520x96 hero header: name (c_brass), class (c_epithet), "Lv 3", XP bar 480x10 c_cyan; Q/E switch hero
(80,240) 420x620 owned items of the focused slot: ListRow (rarity colour, "E" chip on the worn one); A = wear
(560,140) 800x760 SubViewport 800x760, transparent: the hero's 3D model (CharacterVisual, idle clip), turning
   20 deg/s, lit flat, hologram shader: c_cyan fresnel rim, scanlines 3 px moving up, alpha 0.85; a cyan grid disc
   under the feet. Thin c_cyan leader lines (2 px) from each slot box to its body point (hand, belt, chest, arm).
Slot boxes 150x150 (icon 96 + label above, c_cyan outline 2 px; focused = brass 3 px + sweep):
   BLADE (600,180)  HILT (600,420)  GEMSTONES (600,660: 3 sockets 44x44 in a row, read only, empty = dim ring)
   ARMOR (1210,180)  PROSTHETIC (1210,420)
(1400,140) 440x560 stats: rows label | now | arrow | after (after c_good if higher, c_bad if lower): HP, SP, ATK,
   DEF, AGI, LCK, WT, then derived: Hit %, Crit %, Flee % (vs an AGI-40 foe)
(80,900) 1760x90 description bar: item name (rarity) + desc + effect line (perk, ability move)
(0,1020) PromptStrip: [A] Equip  [B] Back  [Q/E] Hero  [LB/RB] Tab
```
Focus: slot boxes (d-pad moves between them), A on a slot moves focus to the item list, A on an item wears it (the
stats preview follows the focused item), B returns to the slots. Bilqis has no Blade, Hilt or Gemstones: those boxes
are hidden. The workshop bench no longer opens this screen (EquipmentHost is replaced).

## 3. Workshop (ref 05)
```
(80,40) 1760x64 tabs: UPGRADE | GEMSTONES | CRAFTING (LB/RB); MoneyCounter right (1600,48)
(80,140) 460x760 left: UPGRADE: owned gear list (ListRow, "+2" chip);  GEMSTONES: owned stones (ListRow, rarity);
   CRAFTING: recipes (ListRow, output name x count)
(580,140) 760x620 centre: the item: Upgrade/Gemstones show Zayd's jambiyah in a SubViewport (hilt + blade meshes,
   turning) or the item icon 256 px; Gemstones shows the hilt's sockets as 3 circles 96 px under it (focus = brass)
(1380,140) 460x620 right panel "PREVIEW": stat rows now -> after; for Crafting the output's description
(580,780) 760x120 MATERIALS REQUIRED: icon 48 + name + "have/need" (c_good when enough, c_bad when short) + riyal
(760,920) 400x80 big button (UPGRADE / SET STONE / CRAFT), disabled with the reason when short
(0,1020) PromptStrip: [A] Confirm  [X] Remove stone  [B] Back  [LB/RB] Tab
```
Upgrades stop at +3 ("MAX" chip). Setting a stone that sits in another hilt moves it. Toasts: "Keen Blade +2",
"Crafted Sulaimani Agate".

## 4. Shop (refs 04, 06)
```
(80,40) 1760x80 title "ABU NABIL'S STALL" + Musnad; MoneyCounter (1600,56)
(80,720) 620x260 keeper: portrait 220x260 (the dialogue portrait) + his line (Amiri, typed) in a glass box
(80,140) 720x560 item grid 3 columns, cells 220x170: icon 96, name, price (riyal glyph, c_brass); rarity = cell glow
   colour; sold out = dim; tabs [Buy][Sell] above the grid (LB/RB)
(840,140) 560x760 detail: icon 160, name (rarity), desc, effect; COMPARISON: what changes (HP +60 -> ...) per hero
(1440,140) 400x420 quantity, owned, money after (c_bad when < 0); (1440,600) 400x300 party mini cards (HP/SP)
(0,1020) PromptStrip: [A] Buy  [X] Sell tab  [B] Leave
```
The same screen serves the bench shop (stones, armor) with the smith's line.

## 5. Save / Load (ref 07)
```
(560,60) 800x90 title "SAVE GAME" (or "LOAD GAME") + Musnad; subtitle "Select a slot"
(440,180) 900x620 three slot rows 900x190: thumbnail 300x170 (captured 480x270 at save time, user://slots/<n>.png),
   "SLOT 01", area name, play time "14h 32m", date "2026-10-23 22:45"; empty = "- EMPTY SLOT -" centred, dim
(1380,180) 460x620 details of the focused slot: bigger thumbnail 440x248, area, party levels, riyal, play time
(500,880) three buttons 280x72: SAVE (or LOAD) | DELETE SLOT | BACK
(0,1020) PromptStrip: [A] Save  [X] Delete  [B] Back
```
Overwrite and Delete ask ConfirmDialog (default No). Load mode hides Save and greys empty slots.

## 6. Holographic map (ref 09)
```
(80,40) 1760x64 tabs (as Equipment) or the title "MAP" + Musnad; area name and "SANA'A SECTOR 01" right
(360,140) 1200x800 hologram: the area's floor plan from AreaDef (walkable tiles and roofs as c_cyan 2 px outlines,
   fill c_cyan at 8%, crossings as dashed lines, the area's place labels); markers 36 px with a soft glow:
   player (c_cyan diamond), NPC (c_good ring), vendor (c_brass cart), quest (c_qam_amber "!"); scanline shader
(80,140) 260x260 legend: the four markers + words
(80,960) coordinates "15 21'04"N 44 12'32"E" (content), c_cyan small
(1560,720) 300x300 city circle: Sana'a district outlines (content/world/city_map.json polygons, metres), a ring
   round the player's district (now the Old City); [Y] switches to the full city map
City map: the same panel shows every district outline and name (Old City, Bab al-Yaman, al-Saila, Zubairi, Haddah,
Bayt Baws, Tahrir, al-Hasaba ...; content), the player's district ringed and pulsing; [Y] back to the area.
(0,1020) PromptStrip: [Y] City / Area  [B] Back
```
Markers come from content/world/map_markers.json: place id -> kind, plus quest rows (flag -> place id; the marker
shows while the flag is unset). The player marker follows the live position.

## 7. Backdrop prompts for Feras (Gemini; 1920x1080; save as inbox/ui_bg_<id>.png)
Shared tail for every prompt: "Painted digital oil illustration, soft flat light, the Qarnaw route-B look (Hades-like
painted surfaces, ink outlines), cyberpunk old Sana'a in 2150 at night, NO text, NO letters, NO signs with writing,
NO people in focus, 16:9, 1920x1080."
- pause: wide view over the five rooftops in the night storm, tower-houses with glowing qamariya, neon magenta/cyan
  on parapets, the megacity on the horizon; dark quiet sky in the right two thirds.
- items: close still life on a rug: a satchel, herb bundles, a qishr cup, brass lamp light; dark empty centre.
- equipment: inside the tayramana (majlis): cushions, carved gypsum arches, stained-glass windows, a server rack
  with cyan lights; the floor centre empty and dark for a hologram.
- workshop: the jambiyah smith's bench room: a small forge glow left, tools, cables, a holo blueprint, stained glass;
  dark centre.
- shop: Abu Nabil's market roof: teal and cream striped awning, hanging herbs, jars, warm lamps, rain; dark left half.
- save: aerial view of the five roofs with the sabil fountain lit, rain, rope bridge; darker middle band.
- map: a dark rooftop observatory with a round holo table glowing cyan, the city's lights far below; centre empty.
