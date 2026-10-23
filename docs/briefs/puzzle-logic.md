# Brief: puzzle-logic (<= 60 lines; pure logic + content + tests, no scenes)
You are in your own worktree on branch gemini/puzzle-logic (made from claude/puzzles-streamline-f7ef2d). Follow
GEMINI.md, including <review_misses>. Load the godot-gameplay-scripter skill.

## Why
Feras: "challenging medium-difficulty, not too gentle and not too hard"; no fail state, every move can be undone.

## Read first
docs/design/valve-puzzles.md (the whole file, 48 lines); core/content_db.gd (KINDS); core/defs/def_reader.gd;
features/world/defs/mist_def.gd (a Def pattern); features/workshop/tests/test_workshop_logic.gd (a test pattern).

## What to build (new folder features/puzzles/: defs/, logic/, tests/; content/puzzles/)
1. LightLockDef (kind "light_lock", content/puzzles/light_lock.json, one item id "valve_lock"): windows [{id, bits,
   target}], mirrors [{id, targets: 4 ids, start}], hint_secs [120, 240], hint_keys. Colour bits: red 1, green 2,
   blue 4, yellow 3; white = 7. A target is a mirror id, "lens", or "" (the beam leaves into the sky).
   Windows: red bits 1 -> m1; blue 4 -> m1; yellow 3 -> m2; green 2 -> m3 (m3 is the R4 mirror).
   Mirrors (targets for turn 0,1,2,3; all start at 0): m1 ["", "m2", "", "m3"]; m2 ["", "", "lens", "m1"];
   m3 ["", "m2", "m1", ""]. Every shutter starts closed. read() reports a target that is no id, a bad bits value,
   != 4 targets.
2. LightLockState (logic/): shutters Dictionary[StringName, bool], turns Dictionary[StringName, int]; static
   start(def). LightLock (logic/, static funcs only): toggle_shutter(state, id); turn_mirror(state, id) (+1 mod 4);
   trace(def, state, window_id) -> Array[StringName] (the nodes the beam visits, window first; it ends at "lens", at
   "" or when a node repeats: a loop is lost light, guard = mirror count + 2 hops); lens_bits(def, state) -> int (OR
   of the bits of open windows whose trace ends at "lens"); solved(def, state) -> bool (lens_bits == 7).
3. WaterNetDef (kind "water_net", content/puzzles/water_net.json, id "valve_water"): nodes [{id, kind, to, ...}],
   kinds source | split | gate | spout | outlet. gate: to = 1 id, open (start), jammed (bool). spout: to = 2 ids,
   start (0 or 1), spill_unless_shut (a gate id or ""). outlet: reaction ("return" | "dock" | "goal"), no to.
   Graph: valve(source) -> j1; j1(split) -> [g1, g2]; g1(gate, open) -> dock; g2(gate, open) -> j2;
   j2(split) -> [g3, s1]; g3(gate, open, jammed) -> grate; s1(spout, to [j3, grate], start 1);
   j3(split) -> [g4, s2]; g4(gate, open) -> dock; s2(spout, to [canyon, grate], start 1, spill_unless_shut "g3");
   outlets: grate "return", dock "dock", canyon "goal". read() reports unknown ids, a cycle, != 1 source, a gate or
   spout with the wrong number of "to".
4. WaterNetState: open, freed (Dictionary[StringName, bool]), spout (Dictionary[StringName, int]); static
   start(def). WaterNet (static): toggle_gate(state, def, id) -> bool (a jammed gate not yet freed does not move and
   returns false); free_gate(state, def, id) -> bool (true once, for a jammed gate: the jambiyah hook); swing_spout;
   flow(def, state) -> Dictionary[StringName, float] (share at every node reached: the source has 1.0; a split
   divides its share equally among the children that pass water: a shut gate passes none and takes no share; a
   spout sends all to to[spout]; if that is to[0] and its spill_unless_shut gate is open, it goes to to[1] instead);
   outlet_shares(def, state); solved(def, state) -> bool (goal share >= 0.999).
5. Hints (logic/puzzle_hints.gd): hints_due(hint_secs: Array[int], stalled_secs: float) -> int (how many are due).
6. Register both kinds in ContentDB KINDS (append two lines at the end). Hint text, appended to
   localization/dialogue.csv: PUZZLE_LIGHT_HINT_1 "The lens wants white. Glass can make white.", PUZZLE_LIGHT_HINT_2
   "Yellow is already half of white.", PUZZLE_WATER_HINT_1 "Every open gate takes a share.", PUZZLE_WATER_HINT_2
   "That old gate is stuck, not locked.", PUZZLE_WATER_RETURN "Straight back to them."

## Do NOT edit
`features/world/`
`content/world/`
`features/combat/`
`features/items/`
`content/items/`
`core/game_state.gd`
`*.tscn`

## Tests (features/puzzles/tests/)
- Start states: lens_bits 0, not solved; all four shutters open at start: still not solved.
- Yellow-blue: open yellow + blue, m1 turn 1, m2 turn 2 -> 7, solved (2 mirrors). Three colours: red + green +
  blue open, yellow shut, m1 1, m2 2, m3 1 -> solved. Near misses: red + yellow (m1 1, m2 2) -> 3; green + yellow -> 3.
- Loop: m1 turn 3 + m3 turn 2 -> the red trace stops (no hang), lens_bits excludes it. Every move undoes itself
  (shutter twice, mirror four turns = the start state).
- Water start: canyon 0. g1 shut, s1 -> 0, g4 shut, s2 -> 0, g3 jammed open: canyon 0 and the grate gets 1.0.
- toggle on unfreed g3 returns false and keeps it open; free_gate then toggle shuts it; free_gate twice -> false.
- Full route (g1, g3, g4 shut; s1 0; s2 0) -> canyon 1.0, solved; with g4 open -> canyon 0.5, dock 0.5, unsolved.
- Shares at outlets always sum to 1.0 or 0 (every route, 2^4 gate x 2^2 spout states, freed g3).
- Def problems: a bad target id, a cycle, two sources are reported. hints_due: 0 at 119 s, 1 at 120, 2 at 240.

## Proof
`bash tools/check.sh` raw last 15 lines; no renders; small WIP commits; final message ends with
`Built-by: Gemini 3.8 Flash (agy)`.
