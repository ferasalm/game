# Brief: holo-map-real (<= 60 lines)
You are in your own worktree on branch oc/holo-map-real (made from origin/main). Follow AGENTS.md. Load the
godot-gameplay-scripter skill. Only features/map/, content/map*/ (or where the map's content lives), localization.

## Why
Feras's playtest (inbox/playtest_06.png, inbox/playtest_07.png): the city view (Y) "does not look like the real map of Sana'a"; make it holographic and pinpoint the
areas in the game. The area view draws dashed lines from the top-left corner to every roof (a bug), roofs look like
ladders and labels overlap.

## Read first
features/map/view/holo_map*.gd, features/map/tests/test_holo_map.gd, the map's content JSON (grep "district").

## Real geography (approximate WGS84, from public maps; good enough for a stylised map, keep it in content)
Old City walled core centre 15.3550N 44.2150E (~1.3 km E-W, ~1.0 km N-S, irregular oval); Bab al-Yaman south gate
15.3495N 44.2135E; Souq al-Milh inside the Old City 15.3540N 44.2160E (level 1 = its rooftops); al-Saila riverbed
street runs N-S on the Old City's west edge ~44.2110E from 15.3650N to 15.3420N; Tahrir Square 15.3530N 44.2070E;
al-Hasaba district north ~15.3850N 44.2100E; Zubairi Street E-W ~15.3400N from 44.1900E to 44.2250E; Haddah district
south-west ~15.3000N 44.1800E; Bayt Baws hill village south ~15.2850N 44.2000E; Jabal Nuqum mountain east ~15.3600N
44.2450E; the Sixty Metre ring road loops ~3-4 km around the centre.

## What to build
1. City view: project these points (equirectangular, north up) into the canvas; draw districts as soft irregular
   polygons (6-10 points each, from content), the Old City wall outline, al-Saila and Zubairi as glowing lines, the
   ring road dashed, Jabal Nuqum as 3 contour rings. Holographic style: cyan lines (#23E6F0), 2 px glow, scanlines,
   slight flicker (from content), labels never overlapping (push apart; test it).
2. Pins: every game area in content gets a pin at its real location (level 1 at Souq al-Milh) with a pulsing ring on
   the current area; areas not reached yet are dim.
3. Area view bug: no line may start at the canvas origin; crossings draw between their two landings only.
4. Roof plans: outline + one hatch every >= 24 px (not ladders); labels de-overlapped like the city view.
5. Renders: C:/dev/game/inbox/map_city.png and map_area.png (tools/shot_holo_map.tscn).

## Do NOT edit
`core/`
`features/equipment/`
`features/ui/view/screens/`
`features/world/`
`tools/check.sh`
`CLAUDE.md`
`docs/DECISIONS.md`
`HANDOFF.md`

## Tests
- Projected district centres keep the real order: al-Hasaba north of the Old City, Haddah and Bayt Baws south,
  Tahrir west of the Old City, Bab al-Yaman south of Souq al-Milh.
- No two label rects overlap in either view; no drawn segment starts at (0,0).

## Checklist
- file: features/map/view/holo_map_canvas.gd
- file: features/map/tests/test_holo_map.gd

## Proof
`bash tools/check.sh` raw last 15 lines; the two renders; final message ends with `Built-by: <model> (opencode)`.
