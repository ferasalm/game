# Brief: holo-map-real-fix2 (<= 60 lines; fix pass on top of oc/holo-map-real-fix)
You are in your own worktree on branch gemini/holo-map-real-fix2 (made from oc/holo-map-real-fix). Follow GEMINI.md.
Load the godot-gameplay-scripter and technical-artist skills. Read docs/briefs/holo-map-real.md and
docs/briefs/holo-map-real-fix.md first: this fixes what the second render still shows.

## Why
Render after the fix pass (inbox/map_city.png, 2026-10-24 04:03): every district now sits inside the panel, but the
old city (Souq al-Milh Rooftops, al-Saila, Old City, Bab al-Yaman, Tahrir, Zubairi) is a 150 px knot in the middle
while Haddah and Bayt Baws fill the lower left. Its labels sit on top of each other ("al-Saila" over "Old City",
"Bab al-Yaman" under the player pin). Roads draw as thick hollow boxes (the T shape), not lines. The area view is fine.

## What to fix
1. features/map/view/holo_map_geo.gd: add a radial compression around the current area's centre before fit():
   d' = R * d / (d + k), with k and the centre taken from content/world/city_map.json ("radial_k" metres, default 1500).
   Directions stay true; the old city fills about half the panel; Haddah and Bayt Baws stay inside, nearer the edge.
   Use it for districts, roads, pins and the radar (holo_map_city_preview.gd) alike.
2. Labels (features/map/view/holo_map_labels.gd and holo_map_city_view.gd): de-overlap with the REAL glyph rects
   (font.get_string_size at the drawn font size, plus 4 px padding) and the player pin rect as a fixed obstacle;
   iterate until no two rects intersect (cap 64 passes); moved > 20 px gets a 1 px leader line.
3. Roads: draw each road as a polyline (draw_polyline, 2 px, cyan 70% alpha), never as a rect or polygon outline.
4. Tests (features/map/tests/test_holo_map_city.gd): with the real city_map.json and the real localized names at the
   real font size, (a) no two city label rects intersect and none covers the player pin; (b) the old-city districts'
   projected bounds span >= 35% of the canvas width; (c) every district stays inside the 1200x800 canvas.
   Each test must fail on the pre-fix code (run it once before the fix and say so in your final message).
5. Renders again with tools/shot_holo_map.tscn: inbox/map_city.png, inbox/map_area.png.

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
Step 4 names them; keep every existing map test green.

## Checklist
- file: features/map/view/holo_map_geo.gd
- file: features/map/view/holo_map_labels.gd
- file: features/map/tests/test_holo_map_city.gd
- file: content/world/city_map.json

## Proof
`bash tools/check.sh` raw last 15 lines; the two renders; final message ends with `Built-by: <model> (agy)`.
