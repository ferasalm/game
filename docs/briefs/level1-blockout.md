# Brief: level1-blockout (<= 60 lines; start only after camera-v2 is merged)
You are in your own worktree on branch gemini/level1-blockout (made from claude/night-sanaa). Follow GEMINI.md,
including <review_misses>. Load the level-designer skill (.agents/skills/level-designer).

## Why
Owner playtest 2026-10-23 item 5: "the roof is too big and lost its second roof"; he wants v1's two connected roofs,
less crowded. docs/design/rooftop-v3.md is that layout; docs/design/level-1.md adds the demo's needs on top.

## Read first
docs/design/rooftop-v3.md (all), docs/design/level-1.md sections 2, 3, 5, 7; docs/MAP.md lines for area_def,
place_def, area_builder, area_dressing, prop_builder, walk_graph, camera_zone (camera-v2), building and skyline defs.

## What to build (content first; code only where a new place kind needs it)
1. rooftop-v3 section 7, items 1-7, exactly (grid, buildings, props moved/removed/added, lights, signs, places,
   camera limits, explore.json numbers).
2. level-1 deltas: (a) tall ring buildings allowed: tower_e and tower_h 6 floors, a new tall tower-house behind the
   commons' west parapet (x -3, z 6, 7 floors, lit qamariya) so the commons is framed; (b) the Concession water tower
   on the east roof NE corner (tower_h becomes it: a tank prop on its roof with a red beacon and a cyan ring light);
   (c) a place kind "door" {id, x, z, yaw, target} at (4.5, 11.0) yaw 90 with target "tayramana" (interact prompt
   key WORLD_PROMPT_ENTER, no action yet beyond a log line; the tayramana brief wires it); (c2) a second door "workshop_door" at (2.5, 13.0) yaw 180, target "workshop", replacing the outdoor
   workshop interact (the workshop menu moves inside with the tayramana brief); (d) a place kind "valve"
   {id, x, z} at (21.5, 3.0) (prompt WORLD_PROMPT_TURN, no action yet); (e) four camera_zone places from level-1
   section 2 (spawn, vista strip, bridge, valve) with numbers you choose, then tune from renders.
   (f) camera (owner 2026-10-23): "follow_side_deg": 32 in camera.json, the lazy yaw settles 32 deg to the right
   of straight behind (a three-quarter view); camera_zone gains an optional "roll" (deg, eased in and out with the
   zone, the camera rolls about its view axis); roll 6 in the valve zone and in a new zone at the east roof landing.
3. Every rooftop-v3 section 5 rule as a test over the new area (reachability, 2 m width, bridge 3 cells, no traps,
   places reachable, patrol clearances >= 3.0). Drop the old camera-safety test (section 5 rule 7): the follow camera
   shortens its arm on walls now; say so in the test file's purpose line.

## Do NOT edit
features/combat/, content/combat/, localization/combat.csv, features/world/logic/framed_shots.gd, content/world/props/workbench.json,
tools/art/, docs/design/, HANDOFF.md, docs/DECISIONS.md.

## Tests
One per rule in item 3; the door and valve places parse and are reachable; the camera zones parse; FollowCam settles
at the side angle; a zone's roll eases in and back to 0 outside it.

## Proof
`bash tools/check.sh` raw last 15 lines; renders (not headless, LESSONS 2) from the play camera at spawn, the
vista strip, the bridge and the east roof to C:/dev/game/inbox/level1_*.png (960x540); small WIP commits; final
message ends with `Built-by: Gemini 3.8 Flash (agy)`.
