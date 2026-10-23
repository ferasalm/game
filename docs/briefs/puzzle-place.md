# Brief: puzzle-place (<= 60 lines; the puzzle scene and the five roofs are on main)
You are in your own worktree on branch oc/puzzle-place (made from main). Follow GEMINI.md and AGENTS.md, including
<review_misses>. Load the level-designer skill.

## Why
Feras: both valve puzzles at the end of level 1 on R5 (light lock first, then the water); walk up and interact; the
water puzzle only after the light lock is solved; no fail state; visible feedback on every move.

## Read first
docs/design/valve-puzzles.md; docs/design/level-1.md (R4, R5, X4); features/puzzles/ (view/puzzle_board.gd,
puzzle_yard.tscn: the self-contained grey box with a stand-in capsule player; LightLock, WaterNet and their defs);
content/puzzles/*.json; features/world/interact/valve_spot.gd; content/world/areas.json souq_rooftops_v4 (place
valve_water on R5 x 8.5 z 4.5, crossing x4, camera zone zone_r5); features/world/rooftop/area_actors.gd (where spots are
made); C:/dev/game/inbox/puzzle_*.png (the grey-box renders); tools/shot_level1.gd (render tool).

## What to build
1. The puzzle board is instanced into the level from valve_spot "valve_water" on R5: its mirrors, beam emitter and
   gauges stand on R5 (and m3 on R4, reachable through X4, which stays two-way), placed by content (positions in
   content/puzzles/*.json or the area's places), never by hard-coded numbers.
2. The capsule stand-in is replaced by the real party: Zayd walks up to a mirror or valve and presses interact; the
   level's follow camera stays (zone_r5 may be tuned in areas.json); no separate puzzle camera unless the board needs a
   framed shot, then it comes from content.
3. Order: valve_water's interact runs the light lock first; the water puzzle unlocks only after the light lock is solved
   (GameState.flags puzzle_valve_lock / puzzle_valve_water; saves keep them).
4. Fix the grey-box misses: the player never stands on mirror m2 at start (spawn the party >= 1.5 m from every mirror);
   the canyon gauge sits fully inside the frame from the R5 play camera.
5. valve_spot.gd prints no debug text; player text comes from localization/world.csv PUZZLE_* keys.

## Do NOT edit
`features/combat/`
`features/puzzles/logic/`
`features/world/logic/follow_cam.gd`
`features/world/view/follow_camera_rig.gd`
`features/world/interior/`
`content/world/props.json`
`docs/design/`
`HANDOFF.md`
`docs/DECISIONS.md`

## Tests
valve_water opens the light lock; the water puzzle is refused until puzzle_valve_lock is set; both flags survive a save
and load; every board piece stands on a walkable roof cell of R4 or R5; the party starts >= 1.5 m from every mirror;
the canyon gauge projects inside the viewport from the R5 camera.

## Proof
`bash tools/check.sh` raw last 15 lines with 0 failed; renders (non-headless, 960x540) from the play camera:
C:/dev/game/inbox/puzzle_r5_lock.png (party at the first mirror, beam visible) and puzzle_r5_water.png (party at the
valve, gauges in frame); small WIP commits; final message ends with `Built-by: <model> (opencode)`.
