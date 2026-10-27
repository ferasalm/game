# Brief: holo-map-city-look (<= 60 lines; look pass on top of gemini/holo-map-real-fix2)
You are in your own worktree on branch gemini/holo-map-city-look (made from gemini/holo-map-real-fix2). Follow
GEMINI.md. Load the ui-designer and technical-artist skills. Read docs/briefs/holo-map-real.md first.

## Why
Feras (2026-10-24): "Sana'a map still looks poorly drawn, try to be inspired by" inbox/concept_city_map.jpg. Open
that picture and match its look in the CITY view (the area view stays as it is). Today the city view is thin
outlines and small labels; the reference is a dense neon schematic.

## Look recipe (from the reference; numbers are for the 1200x800 canvas)
1. Schematic layout, not projected geography: each district in content/world/city_map.json gets a "schematic"
   block in canvas units (centre, shape, colour id) placed like the reference: the Old City a big circle in the
   middle-right (radius ~190), Bab al-Yaman on its south-east rim with a target reticle, Tahrir a fan of radial
   street grid wrapping the west side, Haddah a green block south-west, Bayt Baws a tower cluster south, al-Hasaba
   north (where the airport sits in the reference), al-Saila a channel through the Old City, Zubairi a street from
   the west, Jabal Nuqum purple contour lines on the east edge, the ring road a double neon loop around everything.
   The current area pin sits at its real place inside the Old City. Old geo polygons stay for the radar and tests.
2. Neon lines: every outline and road is drawn 3 times (width 7 at 12% alpha, width 3 at 35%, width 1.5 at 100%)
   for a glow; additive blend (CanvasItemMaterial BLEND_ADD) on a dark navy fill (#0a1424 at 85%).
3. Old City: orange-red (#ff5a2a) glowing disc; inside it a seeded maze: 7 concentric rings with random gaps plus
   radial walls (fixed seed in content), lines 1.5 px; a soft radial gradient fill 30% alpha.
4. Tahrir: cyan (#3fe0ff) grid of radial lines and arcs (12 spokes x 8 arcs) clipped to its fan shape. Haddah:
   green (#4cff6a) irregular blocks, 40% fill. Bayt Baws: 4-6 tall cyan tower rectangles with a bright core.
   al-Hasaba: teal outline with one yellow (#ffe040) runway-like stripe. Ring road: blue (#4a6cff) + magenta
   (#c040ff) pair, 6 px apart, with two roundabout circles where roads meet it.
5. Jabal Nuqum: 10-14 nested wobbly contour lines in violet (#7a4cff), alpha falling inward, from seeded noise.
6. Labels: English name in caps (font size 18, letter spacing 1) and its Musnad line under it (Noto Sans Old South
   Arabian, size 20, cyan) in a dark box (#08101c 80%) with a 1 px cyan border; de-overlap as fix2 does. Musnad
   text: a musnad_key per district in localization/screens.csv; transliterate the Arabic consonants of each name
   into Old South Arabian letters (U+10A60-U+10A7F) and list the mapping in your final message.
7. HUD dressing: bright corner brackets on the panel, a faint 40 px background grid, a compass ring with "N"
   top-right, and a top-left caption "SANA'A METROPOLIS // SECTOR-15" + the coordinates line (localization keys).
8. All colours, sizes, seeds and counts live in content/world/city_map.json (a "look" item), none in code.
   Files stay <= 200 lines and functions <= 40: split the drawing into new view files (e.g. holo_city_old_town.gd,
   holo_city_districts.gd, holo_city_hud.gd).

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
Every district has a schematic block inside the canvas; label rects do not intersect (real names, real font);
every name_key and musnad_key has a localization row; look values load from content (a missing key fails).
Keep all map tests green.

## Checklist
- file: content/world/city_map.json
- file: localization/screens.csv
- file: features/map/tests/test_holo_map_city.gd

## Proof
`bash tools/check.sh` raw last 15 lines; renders inbox/map_city.png and inbox/map_area.png (tools/shot_holo_map.tscn)
next to the reference; final message ends with `Built-by: <model> (agy)`.
