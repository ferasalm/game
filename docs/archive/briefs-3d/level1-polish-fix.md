# Brief: level1-polish-fix (<= 60 lines; fix pass on top of gemini/level1-polish)
You are in your own worktree on branch gemini/level1-polish-fix (made from gemini/level1-polish). Follow GEMINI.md,
including <review_misses>. Load the level-designer skill.

## Why
A review of level1-polish found misses against docs/briefs/level1-polish.md. Feras playtests tonight: Abu Nabil must
be visible at his stall on R2.

## Read first
docs/briefs/level1-polish.md (step 5); features/world/logic/walk_graph.gd; features/world/defs/explore_rules_def.gd;
content/world/explore.json; content/world/areas.json (souq_rooftops_v4, Abu Nabil's stall entry ~line 824);
features/world/rooftop/area_actors.gd (kept_prop, StallKeeper counter-end placement ~line 132).

## What to build
1. Abu Nabil: restore the stall keeper's prop link in souq_rooftops_v4 (compare with `git show origin/main:content/world/areas.json`)
   so area_actors kept_prop finds the stall and places him at the counter end. Test: in souq_rooftops_v4 the stall
   keeper exists and stands within 1.5 m of his stall's counter end (read the numbers from content).
2. Step 5: walk_graph.gd regions() and reachable_with_crossings() take max_step from ExploreRulesDef.walk_step (passed
   in by the caller, no default number in logic/); every caller passes it. Test that a step just above walk_step splits
   two regions and one just below joins them.
3. Numbers in code: crossing_spot.gd `else 0.15` and area_walk.gd _blocked defaults 1.6 and 0.1 come from content
   (the values that already exist there); no literal fallbacks.
4. test_level1_blockout.gd: patrol_drone's two skipped checks get a comment naming the design reason (start 1.41 m
   from X4 landings) and a replacement assertion: its start and end are each reachable from some floor region.
5. test_walk_graph.gd: the new needs_w/w_missing test must call the real walk check and fail when W is missing.
6. Render: `tools/shot_souq_place` (or the existing R2 stall render tool) to C:/dev/game/inbox/souq_r2_stall.png with
   Abu Nabil in frame from the play camera.

## Do NOT edit
`core/save/`
`core/game_state.gd`
`tools/check.sh`
`tools/build_gate.py`
`CLAUDE.md`
`docs/DECISIONS.md`
`HANDOFF.md`

## Tests
Steps 1, 2, 4 and 5 each name their test above.

## Checklist
- file: features/world/logic/walk_graph.gd
- file: content/world/areas.json
- file: features/world/tests/test_walk_graph.gd
- file: features/world/tests/test_level1_blockout.gd

## Proof
`bash tools/check.sh` raw last 15 lines; render to inbox/souq_r2_stall.png; small WIP commits; final message ends with
`Built-by: Gemini 3.8 Flash (agy)`.
