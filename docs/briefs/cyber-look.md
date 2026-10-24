# Brief: cyber-look (<= 60 lines; after render-clean merges)
You are in your own worktree on branch gemini/cyber-look (made from origin/main). Follow GEMINI.md, including
<review_misses>. Load the technical-artist skill and the godot-shader-developer skill. agy is not creative: follow the numbers below exactly.

## Why
Feras's playtest (inbox/playtest_04.png, inbox/playtest_05.png): "why are red bricks dominant? where is the cyberpunk aesthetic... neon lights and cyberpunk
colours?" and "why is there a wall?" (a neighbour tower's bare facade fills the view right behind the R4/R5
parapets at roof height). Target: his concept art, saved by him as C:/dev/game/inbox/concept_cyber_sanaa.png (tower-
houses with magenta and cyan neon crowns, cables, storm, megacity glow) and inbox/concept_neon_street.png.
Decisions: painted route B, Musnad-only signs, 60 FPS on the Iris Xe laptop (docs/DECISIONS.md).

## Read first
docs/MAP.md greps: facade_painter, facade_spec, masonry, building_def, sign_spec, skyline_def, paint_def, storm.
content/world/buildings or areas.json (souq_rooftops_v4 blocks), content/world/skyline.json, storm.json, palette.

## What to build (all numbers in content)
1. Facade palette (sampled from Feras's references inbox/concept_bricks_tower.png and concept_bricks_rooftops.png,
   2026-10-24: "the bricks should not look red"): brick a desaturated grey-brown #574A48 with light bricks #6A6266
   and dark #4A383A, mortar #271E23; gypsum friezes and window frames a rain-cooled off-white #A6B3B9; basalt
   #383237. Night ambient cool teal; warm only in lit windows. No frame from the play camera may read as red.
2. Neon crowns: every tower-house roof edge in the area and the near skyline gets an emissive strip 0.08 m tall at the
   parapet top: magenta #FF2BD6 (60%) or cyan #23E6F0 (40%), energy 3.0, picked by a seeded hash; a soft OmniLight
   (range 4 m, energy 0.6, same colour) on 1 in 3 roofs only (budget).
3. Cables: 3-6 sagging black cables (0.03 m radius, 12 segments, sag 0.6 m) between neighbouring towers per roof.
4. Holo signs: 4 Musnad neon signs (existing SignSpec) on R1-R5 side walls, cyan/magenta, slow 0.5 Hz flicker.
5. Megacity glow: skyline far band gets cyan/magenta window emission (30% of windows) and a purple horizon glow.
6. Wet roofs: floor roughness 0.25 where wet spots are, so neon reflects (screen-space reflection only if >= 60 FPS).
7. The wall: the tower faces that stand within 1.5 m of a playable roof edge and rise more than 2.5 m above it get
   windows, a frieze and a neon strip like every other facade, or are lowered to <= 2.5 m above the roof.
8. Rain: no streak may render closer than 1.5 m to the camera (a huge diagonal streak crossed render_clean_r1.png);
   streak length and near-clip distance from storm.json.
9. Sabil (R2, the prop "sabil" in content/world/props*): a qamariya half-moon window of stained glass (0.9 m wide,
   0.45 m tall semicircle above the spout niche: white gypsum tracery 0.04 m, 7 glass panes red #D8322E, amber
   #F2A93B, green #2FA36B, blue #2E6FD8 cycling) glowing from behind (emission 2.0), as on every Sana'a sabil.
10. Feras (2026-10-24, rc.jpg): "where are the neon lights, why are the buildings red bricks" - judge every render
   against inbox/concept_cyber_sanaa.png before finishing: neon on every roof edge in frame, no red-dominant frame.
11. Renders from the play camera: inbox/cyber_r1.png, cyber_r2_sabil.png, cyber_r4.png, cyber_r5.png; fps_probe numbers in the final message.

## Do NOT edit
`core/`
`features/ui/`
`features/equipment/`
`features/map/`
`tools/check.sh`
`CLAUDE.md`
`docs/DECISIONS.md`
`HANDOFF.md`

## Tests
- Every roof edge of souq_rooftops_v4 has a neon strip; colours only from the two content neon colours.
- No facade within 1.5 m of a roof edge rises > 2.5 m above it without windows (the wall rule).

## Checklist
- file: content/world/storm.json
- file: content/world/skyline.json

## Proof
`bash tools/check.sh` raw last 15 lines; renders; fps numbers; final message ends with `Built-by: Gemini 3.8 Flash (agy)`.
