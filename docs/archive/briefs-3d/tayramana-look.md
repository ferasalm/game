# Brief: tayramana-look (<= 60 lines; the tayramana flow is merged; this pass is its look)
You are in your own worktree on branch gemini/tayramana-look (made from claude/level1-review). Follow GEMINI.md, including
<review_misses>. Load the technical-artist skill.

## Why
Feras's spec (level-1.md 6): a Sana'ani tayramana, a rooftop room with large qamariya windows, a Yemeni majlis of low
cushions along the walls, warm lamp light; the party sits and shares qishr. Review of the first build's renders
(C:/dev/game/inbox/tayramana_door.png, tayramana_window.png): both shots are the same view, the walls are missing (a
black void), no lit qamariya arches, flat unlit colours (bright red, purple, orange slabs), the party stands, and the
"E: sit" prompt fills the shot.

## Read first
docs/design/level-1.md section 6; content/world/rooms.json; features/world/interior/ (RoomBuilder, room_mesh_builder.gd,
TayramanaFlow); features/world/view/painted_materials.gd and surface_materials.gd (the painted look the roofs use);
content/world/props.json (the sabil's qamariya: coloured glass parts); tools/shot_tayramana.gd;
C:/dev/game/inbox/level1_concept_roofs.png (the lit tayramana on the right tower: warm glow behind arched windows).

## What to build
1. Four walls (7 x 5 x 3 m) in limewashed gypsum with the painted materials, a wood-beam ceiling, a carpet floor.
2. Qamariya: a half-round coloured-glass arch (7 colour segments, emissive) above each of the large windows on three
   walls; a low window opening under each arch with night sky behind.
3. Majlis: cushions 0.25 m high along two long walls with armrests every 1.2 m; muted textile colours (madder red, indigo,
   ochre; no pure saturated slabs); the brass tray, jamana pot and cups on a low centre tray, not a big orange square.
4. Light: two warm lamps (OmniLight, colour ~#ffb070) plus the qamariya glow; ambient low; the room reads warm against
   the cold storm outside.
5. The two framed shots in rooms.json are distinct: door corner looking at the window wall, window corner looking at
   the door wall; both frame the seated party at chest height, never inside a face.
6. Seated: in the renders the party kneels on the cushions (the sit pose the flow already sets); no interact prompt
   while seated or in the renders.
7. Numbers and colours live in content (rooms.json, props.json); code changes only where the builder lacks a feature.

## Do NOT edit
`features/combat/`
`features/puzzles/`
`features/world/logic/follow_cam.gd`
`features/world/view/follow_camera_rig.gd`
`content/world/areas.json`
`content/dialogue/`
`docs/design/`
`HANDOFF.md`
`docs/DECISIONS.md`

## Tests
Four walls and a ceiling exist; three qamariya arches with 7 emissive segments each; the two framed shots differ in
position by >= 3 m and look at different walls; lamp lights exist and are warm; no prompt is visible while seated.

## Proof
`bash tools/check.sh` raw last 15 lines with 0 failed; renders (non-headless, 960x540) of both framed shots with the
party seated to C:/dev/game/inbox/tayramana_door.png and tayramana_window.png; small WIP commits; final message ends
with `Built-by: Gemini 3.8 Flash (agy)`.
