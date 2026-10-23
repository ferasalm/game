# Brief: puzzle-scene (<= 60 lines; a self-contained grey-box scene on the merged puzzle logic)
You are in your own worktree on branch gemini/puzzle-scene (made from claude/puzzles-streamline-f7ef2d). Follow
GEMINI.md, including <review_misses>. Load the godot-gameplay-scripter skill.

## Why
Feras: both valve puzzles, light lock first, then the water; no fail state; visible feedback on every move.
The level later instances this scene from R5's valve_spot (not your job).

## Read first
docs/design/valve-puzzles.md; features/puzzles/ (LightLock, WaterNet, their Defs and States, puzzle_hints.gd);
content/puzzles/*.json; tools/shot_menu.gd + tools/shot_menu.tscn (the render-tool pattern).

## What to build (features/puzzles/view/, numbers in content/puzzles/puzzle_yard.json, kind "puzzle_yard")
1. Optional "at": [x, y, z] (metres) on every window, mirror, the lens and every water node (Def fields, default
   zero). Values: windows red (-5.5, 3.0, -4.9), blue (-3.5, 3.0, -4.9), yellow (1.5, 3.2, -4.9), green
   (-12.0, 5.0, 2.0); mirrors m1 (-4.5, 1.4, -1.5), m2 (0.0, 1.4, 1.0), m3 (-8.5, 0.8, 3.0); lens (2.5, 1.4, 0.0).
   Water (y 0.05): valve (2.5, 0), j1 (3.5, 0), g1 (3.5, -2), dock (3.5, -4), g2 (4.5, 0), j2 (5.5, 0),
   g3 (5.5, -2), grate (5.5, -4), s1 (6.5, 0), j3 (6.5, 2.5), g4 (5.0, 2.5), s2 (6.8, 2.5), canyon (8.5, -3.0, 2.5).
2. puzzle_yard.json: floor 14 x 10 m at y 0 centred on 0 (#5a524a), back wall z -5, 6 m high (#6b6158), parapet
   0.6 m on x +7 and z +5; R4 ledge box x -10..-7.5, z 1..5, top y 0.4 (1.5 m leap gap); far tower 2 x 8 x 2 at
   (-13, 4, 2) (#4a4038). Camera at (0, 7, 11) looking at (0, 0.5, -1), fov 50. Colours: red #ff3b30, yellow
   #ffd23f, green #3cdc78, blue #3a7bff, white #f4f1ea, water #5fd4e0, rust #8a4b2a, wood #7a5230, grate #b0302a.
3. PuzzleBoard (Node3D, puzzle_board.gd + puzzle_yard.tscn): builds the grey boxes from content, holds a
   LightLockState and a WaterNetState, act(piece_id) applies one move (shutter, mirror, gate, hook-free, spout), then
   redraws. Pieces cycle with move_left/move_right in the content order; interact acts on the selected one; a cyan
   0.2 m marker floats 0.6 m above it. The water pieces cannot be selected until the light lock is solved.
4. Light view: a window is a 1.0 x 1.4 emissive quad in its colour, a shut shutter is a wood box over it; a mirror
   is a 0.1 x 0.8 x 0.6 brass box (#c8a040) on a post, yaw = turn x 90 deg. Every open window's trace is drawn as
   thin boxes (0.08 m) node to node, unshaded additive, alpha 0.7, in its colour; a trace that ends at "" goes 4 m
   along the last mirror's facing. The lens is a 0.35 m sphere lit in the mixed colour (bits 1 red, 2 green, 3
   yellow, 4 blue, 5 magenta, 6 cyan, 7 white, 0 #222222); a wrong mix flickers (energy 0.6..1.4 at 9 Hz); the seal
   (a 0.5 m torus around the lens) is red until solved, then white and turns 90 deg over 0.8 s.
5. Water view: a channel is a 0.4 wide, 0.15 deep stone box per edge, node to node; an edge with share > 0 gets a
   water strip on top (scrolling UV shader, unshaded, alpha 0.4 + 0.5 x share). Gates: 0.5 x 0.6 x 0.1 wood boxes,
   raised 0.5 m when open; jammed and not freed = rust and tilted 10 deg. Spouts: a 0.8 m trough that yaws toward
   its current target. Outlets: grate a 1.2 x 0.6 red slab; dock a 1.6 x 1.2 pad with two 0.4 m drone boxes that
   sag 0.15 m and darken while it has water; canyon a 1 m gauge bar filled to the canyon share.
6. Hints: a stall timer per puzzle (seconds since it became active, unsolved); hints_due() shows each due key once
   for 5 s in a bottom label (tr(key)). Return-grate water shows PUZZLE_WATER_RETURN once per time it starts.
7. Saves: solving sets GameState.flags[&"puzzle_valve_lock"] / [&"puzzle_valve_water"]; on _ready a set flag
   loads that puzzle solved (water: the full route), an unset one its start state.
8. Render tool tools/shot_puzzles.gd + .tscn (pattern of shot_menu): args start | light_solved | water_half |
   water_solved -> C:/dev/game/inbox/puzzle_<arg>.png at 1920 x 1080.

## Do NOT edit
`features/world/`
`content/world/`
`features/combat/`
`features/dialogue/`
`features/items/`
`core/game_state.gd`
`features/puzzles/logic/`

## Tests (features/puzzles/tests/)
- act() on each piece kind changes the matching state; water pieces refuse while the light lock is unsolved.
- The yellow-blue moves through act() solve the light lock and set the flag; a board made after that loads solved.
- Beam boxes: count = trace segments of open windows; the lens colour matches lens_bits for 0, 3 and 7.
- A water edge has a strip only when its share > 0; the gauge equals the canyon share (0.5 and 1.0 cases).
- Hints: none before 120 s, the first at 120 s, each shown once.

## Proof
`bash tools/check.sh` raw last 15 lines; renders C:/dev/game/inbox/puzzle_start.png, puzzle_light_solved.png,
puzzle_water_half.png, puzzle_water_solved.png; small WIP commits; final message ends with
`Built-by: Gemini 3.8 Flash (agy)`.
