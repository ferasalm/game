# Brief: holo-map-city-look-fix (<= 60 lines; fix pass on top of gemini/holo-map-city-look)
You are in your own worktree on branch gemini/holo-map-city-look-fix (made from gemini/holo-map-city-look). Follow
GEMINI.md. Load the ui-designer and technical-artist skills. Read docs/briefs/holo-map-city-look.md first and open
inbox/concept_city_map.jpg (Feras's reference) next to your render inbox/map_city.png (Claude rendered it 06:20).

## What the render still misses
1. Old City maze: the disc is a plain orange glow; the reference shows dense maze walls (concentric rings with gaps +
   radial walls) clearly. Draw the maze at full brightness (#ff6a3a, 1.5-2 px, glow pass) over a darker disc fill so
   it reads at 640 px wide.
2. Labels inside the Old City (AL-SAILA, OLD CITY, SOUQ AL-MILH ROOFTOPS, BAB AL-YAMAN) stack in a column over the
   disc and hide it. Place them like the reference: OLD CITY label in the disc's upper half, BAB AL-YAMAN beside its
   target reticle on the east rim (the reticle is missing: draw it, 3 rings + cross, pulsing), the current-area name
   only as the player pin's tooltip-style tag, al-Saila along its channel. Leader lines stay <= 1 px.
3. Tahrir: the radial street grid is too faint to see; draw spokes and arcs at 70% alpha with the glow pass.
4. Jabal Nuqum contour lines run past the map panel's right edge over the frame: clip every city drawing to the
   panel rect (the 1200x800 canvas), e.g. a clip_children parent or by clipping polylines.
5. Numbers in code: the gate counts 93 lines (centres like Vector2(760, 420), radii, segment counts in
   holo_city_districts.gd, holo_city_hud.gd, holo_city_look.gd). Move layout and look numbers into the "look" and
   "schematic" items of content/world/city_map.json; code keeps only 0, 1, 2, 0.5 and loop math.
6. Render again: inbox/map_city.png, inbox/map_area.png (tools/shot_holo_map.tscn).

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
Every city drawing point lies inside the canvas after clipping (test the clip rect is set); label rects do not
intersect each other or the Old City title; a test that the maze has >= 7 rings from content. Keep all map tests green.

## Checklist
- file: content/world/city_map.json
- file: features/map/view/holo_city_districts.gd

## Proof
`bash tools/check.sh` raw last 15 lines; the two renders; final message ends with `Built-by: <model> (agy)`.
