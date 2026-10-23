# Brief: holo-map-real-fix (<= 60 lines; fix pass on top of oc/holo-map-real)
You are in your own worktree on branch oc/holo-map-real-fix (made from oc/holo-map-real). Follow AGENTS.md. Load the
godot-gameplay-scripter skill. Read docs/briefs/holo-map-real.md first: this fixes its review misses.

## Why
Review + render (inbox/map_city.png): the city view is crammed in the middle, labels overlap, Haddah and Bayt Baws are
drawn outside the panel; the radar shows no districts.

## What to fix
1. features/map/view/holo_map_geo.gd ~56: project() flips y but the offset uses bounds.position, shifting the map 300 px
   down. Fit ALL districts, roads and pins into the 1200x800 canvas with an 8% margin (uniform scale, centred).
2. features/map/view/holo_map_city_preview.gd ~43: the radar mixes metres and pixels and ignores the y flip; reuse
   the same projection fitted into the radar circle (radius from its layout).
3. Labels: de-overlap the REAL label sets of both views (push apart, leader line if moved > 20 px); test on the real
   city labels and the real souq_rooftops_v4 area labels, not synthetic ones.
4. content/world/city_map.json: al_saila, zubairi, haddah, bayt_baws, tahrir get 6-10 polygon points; the test asserts
   >= 6 for every district.
5. localization: RING_ROAD and JABAL_NUQUM rows; a test that every name_key in city_map.json has a localization row.
6. Flicker period and amplitude come from city_map.json (keep 1.6 s, 0.85 + 0.15).
7. Pins: drop the "reached" dimming (no save flag exists): all area pins bright, the current one pulsing. One pin per
   place: souq_rooftops and souq_rooftops_v4 share a spot, draw one pin labelled once.
8. Area view roofs: outline + a light 45-degree hatch every 32 px at 25% alpha (not horizontal ladder lines).
9. Test: projected bounds of every district lie inside the 1200x800 canvas.
10. Renders again: inbox/map_city.png, inbox/map_area.png.

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
Steps 3, 4, 5 and 9 name their tests.

## Checklist
- file: features/map/view/holo_map_geo.gd
- file: features/map/view/holo_map_city_preview.gd
- file: content/world/city_map.json

## Proof
`bash tools/check.sh` raw last 15 lines; the two renders; final message ends with `Built-by: <model> (opencode)`.
