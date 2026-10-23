# Brief: holo-map (<= 60 lines; run ONLY AFTER gemini/level1-blockout-fix merges AND equipment-menu merges)
You are in your own worktree on branch oc/holo-map (made from claude/menus-rpg-5089fa). Follow GEMINI.md, including
<review_misses>. Load the godot-gameplay-scripter skill (.agents/skills/) if one fits.

## Why
Feras approved a holographic map (rpg-menus.md 6, his reference 09): the area's floor plan glowing cyan with markers,
and a city view of Sana'a's districts.

## Read first
C:/dev/game/inbox/ui_refs/mock_map.png (layout target; Feras's Gemini mockup: copy its layout, not its names, numbers or glyphs);
docs/design/rpg-menus.md 0 and 6 (THE SPEC: rects at 1920x1080); docs/design/world.md (district names);
features/world/defs/area_def.gd (width, depth, is_walkable, tile_id_at, places, places_of, and the crossings the
blockout added: grep "crossing"), place_def.gd (id, kind, pos, cell); features/ui/view/ui_screen.gd, menu_backdrop.gd,
ui.gd, ui_panel.gd, prompt_strip.gd; features/equipment/view/equipment_menu.gd (its tabs); core/game_state.gd (area,
flags); the Router / rooftop API that gives the live player position (grep "player_position" or Player.global_position
through an AreaPort query; read only).

## What to build
1. Content: content/world/map_markers.json kind "map_marker" (MapMarkerDef: place id -> kind npc | vendor | quest,
   plus quest rows {flag, place}; a quest marker shows while its flag is unset); content/world/city_map.json kind
   "city_district" (CityDistrictDef: id, name_key, polygon in metres as [[x, z], ...], is_old_city): Old City, Bab
   al-Yaman, al-Saila, Zubairi, Haddah, Bayt Baws, Tahrir, al-Hasaba (rough shapes are fine: [PLACEHOLDER]);
   content/ui/map.json kind "map_info": coordinates text "15 21'04\"N 44 12'32\"E", sector key. New files only: never
   edit content/world/areas.json or props.
2. Pure logic features/map/logic/map_plan.gd: plan(area: AreaDef) -> walkable cells as merged Rect2i runs (one
   rect per row run), crossings as segments, place labels; fit(plan, Rect2(360,140,1200,800)) -> scale + offset
   keeping aspect; markers(area, markers, flags) -> Array of {kind, cell}. No nodes, no autoloads.
3. features/map/view/holo_map.gd: HoloMap extends UiScreen, ID &"map", backdrop_id &"map"; title MAP_TITLE +
   MAP_TITLE_MUSNAD,𐩱𐩡𐩭𐩧𐩺𐩷𐩠 (copy these exact letters); area name and "SANA'A SECTOR 01" right; a Control at
   (360,140) 1200x800 drawing in _draw(): cell outlines c_cyan 2 px, fill c_cyan at 8%, crossings dashed, place
   labels s_font_small; markers 36 px with a soft glow: player c_cyan diamond (live position, updated in _process
   with process_mode ALWAYS), NPC c_good ring, vendor c_brass cart, quest c_qam_amber "!"; scanlines via
   features/map/view/holo_scan.gdshader (canvas_item, 3 px lines moving up, alpha 0.15); legend (80,140) 260x260;
   coordinates (80,960) c_cyan s_font_small; city circle (1560,720) 300x300 with the district outlines and a ring
   round the Old City. [Y] swaps the big panel to the full city map (every district outline + name, the player's
   district ringed and pulsing on t_pulse) and back. PromptStrip [Y] City / Area [B] Back.
4. Wiring: register &"map" in ui_stack.gd (one new line); pause "Map" entry (PauseLogic: add the entry; smallest edit)
   and the equipment menu's MAP tab open it. Text keys in localization/screens.csv (English only).

## Do NOT edit
content/world/areas.json, content/world/props/**, features/world/** (read only), features/combat/**,
features/equipment/** except enabling the MAP tab, core/save/**, docs/DECISIONS.md, HANDOFF.md, any *.import. No Arabic
script anywhere.

## Tests (features/map/tests/test_holo_map.gd)
plan() of a 3x2 test area returns the walkable cells only; fit keeps aspect inside the panel; a quest marker shows
while its flag is unset and hides once set; vendor marker for a shop place; the screen opens by id &"map" and from
pause; [Y] toggles city/area; city_map.json loads 8 districts with >= 3 points each; the player marker follows a moved
position.

## Proof
`bash tools/check.sh` raw last 15 lines; renders C:/dev/game/inbox/menu_map_area.png and menu_map_city.png on the
five-roof area (a .tscn wrapper, non-headless); small WIP commits; final message ends with `Built-by: <model> (opencode)`.
