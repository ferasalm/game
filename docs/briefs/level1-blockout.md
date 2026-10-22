# Brief: level1-blockout (<= 60 lines)
You are in your own worktree on branch gemini/level1-blockout (made from claude/night-sanaa). Follow GEMINI.md,
including <review_misses>. Load the level-designer skill (.agents/skills/level-designer).

## Why
Owner 2026-10-23: "multiple roofs of multiple buildings like before, but don't pack them with extra shops, rooms
(keep the Tayramana)", crossings by board, bridge, leap, zipline, cable. Spec: docs/design/level-1.md sections 2, 3,
7 (the layout), 5 (look notes only; the dressing pass comes later). This is a GREY-BOX: shapes, heights, places.

## Read first
docs/design/level-1.md (all); docs/design/rooftop-v3.md sections 4-5 (unstuck and walk-graph rules: they apply per
roof); docs/MAP.md lines for area_def, tile_def, place_def, area_builder, area_dressing, canyon_builder, walk_graph,
follow_cam, follow_camera_rig, camera_rig_def; content/world/areas.json, tiles.json, buildings.json, camera.json.

## What to build
1. A new area "souq_rooftops_v4" replacing the rooftop's current area (keep the old one in areas.json, unused):
   the five roofs R1-R5 at the floors of level-1 section 2 (floor tiles per roof height, e.g. roof_r1 ... roof_r5 in
   tiles.json), parapets on every edge except crossing ends, the alleys and al-Saila street between them (canyon
   builder or hidden street tiles), each roof's tower-house body below it (buildings.json, qamariya colours as in
   level-1 section 5), the water tower on R5 (a tank prop with a red beacon and a cyan ring light).
2. Places: spawn on R1; Abu Nabil's stall + keeper and the sabil on R2; a door place on the tayramana's south face on
   R3 (target "tayramana", prompt WORLD_PROMPT_ENTER, a log line only: the tayramana brief wires it); patrols A on R4
   and C on R5 (existing encounter ids), the drone sweep lane over the X4 gap (patrol_drone); a "valve" place on R5
   (prompt WORLD_PROMPT_TURN, no action yet); safe spots on every roof.
3. Crossings X1-X5 as a new place kind "crossing" {id, kind: board|bridge|zipline|leap|cable, from [x,z], to [x,z],
   one_way}: a visible stand-in mesh each (plank, plank bridge with rails, a cable with a handle, a chalk mark, a cable
   bundle), an interact prompt at each usable end (keys WORLD_PROMPT_CROSS_<KIND>), and for now the move is an
   instant move of the party to the other end with a 0.3 s fade (the set moves come in the crossings brief).
4. Walk graph: a height step > 0.1 m splits regions, so each roof is its own region joined only by crossing edges
   (one-way for X3). Tests: every roof is reachable from spawn through crossings; the loop R1-R2-R3-R4-R1 exists;
   R5 is reached only by X4; every place, patrol endpoint and crossing end is reachable; rooftop-v3 section 5 rules
   (2 m width, no traps, no dead-end pocket under 2 x 2) on every roof; patrol clearances >= 3.0 m from every
   crossing end, the stall and the sabil; no patrol on R1-R3.
5. Camera (owner 2026-10-23): "follow_side_deg": 32 in camera.json, the lazy yaw settles 32 deg right of straight
   behind (a three-quarter view); camera_zone gains an optional "roll" (deg, eased in and out with the zone, the
   camera rolls about its view axis). Zones: one side-view zone per crossing, roll 6 on R5 and at the X4 gap.
6. Player text: the new prompt keys in localization/world.csv (English; Arabic column empty).

## Do NOT edit
features/combat/, content/combat/, localization/combat.csv, features/dialogue/, content/dialogue/, features/items/,
content/economy/, features/prototype/ (another session owns them), features/world/logic/framed_shots.gd,
content/world/props/workbench.json, tools/art/, docs/design/, HANDOFF.md, docs/DECISIONS.md.

## Tests
One per rule in items 3-5: crossing places parse and connect the regions as listed; FollowCam settles at the side
angle; a zone's roll eases in and back to 0 outside it; the old rooftop tests keep passing for the old area or are
moved to the new one with the same rules.

## Proof
`bash tools/check.sh` raw last 15 lines; renders (not headless, LESSONS 2) from the play camera on each roof and at
X3, to C:/dev/game/inbox/level1_*.png (960x540); small WIP commits; final message ends with
`Built-by: Gemini 3.8 Flash (agy)`.
