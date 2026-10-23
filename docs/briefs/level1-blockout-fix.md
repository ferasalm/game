# Brief: level1-blockout-fix (<= 60 lines)
You are in your own worktree on branch gemini/level1-blockout-fix, made from gemini/level1-blockout (your earlier
blockout run, merged with claude/night-sanaa). Follow GEMINI.md, including <review_misses>. Never weaken a test
threshold or delete a rule test to make it pass: fix the content or the code, or move the test to the right area.

## Why
`bash tools/check.sh` on the blockout ends with 14 FAIL lines (.check/tests.log). Claude's review also found the R4/R5
roofs drowned in purple mist in inbox/level1_r4.png and level1_r5.png. Fix exactly these, nothing else.

## Read first
.check/tests.log after one `bash tools/check.sh`; docs/briefs/level1-blockout.md (the rules still hold);
content/world/mist.json; features/world/logic/walk_graph.gd (your crossing edges); features/world/tests/test_walk_graph.gd,
test_rooftop.gd, test_rooftop_actors.gd, test_painted.gd; tools/export_atlases.gd and tools/art/painterly_bake.py usage.

## What to fix
1. test_painted::test_bakes_match_painter_inputs (wash/facade_tower_r5_emit missing): the bake stopped mid-run. Re-run
   the export + bake exactly as the test message says (export_atlases.gd, then painterly_bake.py for the oil AND wash
   recipes) and commit every changed atlas and bake.json. Run it in the foreground; it takes minutes.
2. test_walk_graph::test_every_area_is_one_piece_from_its_spawn and ..._no_corridor_under_two_metres for
   souq_rooftops_v4: the area is several roof regions joined ONLY by crossing places. Make the generic tests follow
   crossing edges (WalkGraph already builds them) for areas that have crossing places, so "one piece" means reachable
   through crossings. Areas without crossings keep the old meaning.
3. The two corridors under 2 m in souq_rooftops_v4 at cells (23, 29) and (28, 27): widen the layout (rows in
   areas.json) so every walkable path is >= 2 m wide; do not touch the test.
4. test_rooftop::test_player_walks_faces_and_is_stopped_by_the_edge and test_rooftop_actors::
   test_bilqis_never_sticks_around_the_props: these use coordinates of the OLD area on the new one. Re-pick the test
   points on souq_rooftops_v4 with the same intent (an open west edge with a parapet on R2; points next to each prop on
   R2), from the area data, not by hand-guessing. If Bilqis truly sticks next to a prop on the new roofs, fix the
   prop's clearance in areas.json.
5. Mist for the new area (Claude's numbers): add mist items "saila_fog_v4" (height -17.0, stack 5, step 2.3, rect
   [13.0, 0.0, 24.0, 36.0], the other fields as saila_fog), "saila_floor_v4" (as saila_floor, rect the same) and
   "wisps_v4" (as wisps, height -9.0, stack 2): every layer stays >= 2 m below the lowest roof floor (-3.2). Point
   souq_rooftops_v4's "mist" at the three new ids; leave the old items for the old area. A test: no mist layer of an
   area reaches within 2 m of that area's lowest walkable floor.
6. Re-render inbox/level1_r1..r5.png and level1_x3.png with tools/shot_level1.tscn after the fixes.

## Do NOT edit
features/world/weather/, content/world/storm.json (storm, merging next); content/world/props.json items "sabil" and
"herb_stall" (souq-props is rebuilding them); features/combat/, features/dialogue/, features/items/, content/economy/,
features/prototype/; tools/art/ code (running it is fine); docs/design/; HANDOFF.md; docs/DECISIONS.md.

## Proof
`bash tools/check.sh` raw last 15 lines with 0 failed; the six renders; small WIP commits (commit after each numbered
fix: your last run timed out with work uncommitted); final message ends with `Built-by: Gemini 3.8 Flash (agy)`.
