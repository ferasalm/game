# Brief: level1-polish (<= 60 lines; after camera-wall, souq-place and tayramana merge)
You are in your own worktree on branch oc/level1-polish (made from main). Follow GEMINI.md and AGENTS.md, including
<review_misses>. Load the level-designer skill.

## Why
Review of the merged level-1 blockout (souq_rooftops_v4): the demo must start on the five roofs, and the blockout
left a regression on the old area, a weakened test or two and numbers in code.

## Read first
docs/design/level-1.md (roofs, crossings X1-X5, camera); content/world/areas.json souq_rooftops_v4;
features/world/rooftop/area_walk.gd (`git log -p -3 -- features/world/rooftop/area_walk.gd`: the capsule-span filter
that was dropped); features/world/interact/crossing_spot.gd; features/world/logic/walk_graph.gd; content/world/explore.json;
features/world/tests/test_rooftop_systems.gd, test_walk_graph.gd, test_places.gd.

## What to build
1. The game starts on souq_rooftops_v4 at spawn_start (find where the default area id is set: grep "souq_rooftops"
   in features/ and content/). Tests that need the old area name it explicitly.
2. Regression: area_walk.gd again blocks a cell whose prop overlaps the player's capsule span (old souq_rooftops cells
   (1,21) and (32,11) under the ac_unit props at y 1.2 must be blocked again); AreaWalk.on_prop honours height.
3. patrol_drone on v4 sweeps over the X4 leap gap (between its two landings), not 3 m beside it.
4. Camera zones zone_x3 and zone_x5 use a side view like zone_x1 (yaw 90 or 270, whichever looks across the
   crossing from the open side), per DECISIONS 2026-10-23 (three-quarter side ~32 deg by default).
5. Numbers out of code into content (explore.json or camera.json): crossing_spot.gd fade 0.15 s (use 0.3 s total),
   walk_graph.gd walk step 0.1 m, area_walk.gd 0.1 m tolerance.
6. door_spot.gd and valve_spot.gd print no English debug text (an empty interact stays silent).

## Do NOT edit
`features/combat/`
`features/puzzles/`
`features/world/logic/follow_cam.gd`
`features/world/view/follow_camera_rig.gd`
`content/world/props.json`
`content/world/storm.json`
`docs/design/`
`HANDOFF.md`
`docs/DECISIONS.md`

## Tests
The default area is souq_rooftops_v4; old-area cells (1,21) and (32,11) are blocked; on_prop respects height;
patrol_drone's lane crosses the X4 gap; zone_x3 and zone_x5 yaw is 90 or 270; restore the follow-mode look-offset
check in test_rooftop_systems.gd (camera aims at focus + aim_height, not just camera_position()); test_walk_graph.gd
fails again when an area that needs a W marker lacks one.

## Proof
`bash tools/check.sh` raw last 15 lines with 0 failed; renders from tools/shot_level1.tscn (non-headless) of R1-R5
and X3 to C:/dev/game/inbox/level1_*.png; small WIP commits; final message ends with `Built-by: <model> (opencode)`.
