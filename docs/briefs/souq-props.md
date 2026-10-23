# Brief: souq-props (<= 60 lines)
You are in your own worktree on branch gemini/souq-props (made from claude/night-sanaa). Follow GEMINI.md, including
<review_misses>. Load the technical-artist skill (.agents/skills/technical-artist). The DESIGN below is fixed: build it as
written (sizes in metres, prop frame: +y up, the prop faces +z); do not invent other pieces.

## Why
Owner playtest 2026-10-23: the sabil "does not look like" his concept (C:/dev/game/inbox/level1_concept_sabil.png: look
at it first) and is not against a wall; Abu Nabil's stall "has other things than herbs" (crystal cones and bottles), and
he is hard to see behind it.

## Read first
docs/MAP.md lines for prop_def, prop_part, prop_mesh, prop_builder, palette_def, light_spec, stall_keeper, workbench;
content/world/props.json items "sabil" and "herb_stall"; content/world/props/workbench.json (a prop with a light);
tools/shot_workbench.gd (render pattern). A Node script will NOT run with -s: render through a .tscn wrapper scene
(see tools/shot_dialogue.tscn).

## What to build
1. Sabil = a WALL NICHE, not a free box. Replace the "sabil" item's parts (keep its id, splash, collide depth <= 0.9):
   - wall slab 2.2 w x 2.8 h x 0.3 d, old brown stone (pattern "basalt"), its front at z=0;
   - carved frame: white gypsum (pattern "gypsum") jambs 0.22 w, 1.9 h, standing 0.06 proud of the wall, a lintel
     1.5 w x 0.22 h on top, and a stepped arch inside (3 boxes narrowing upward) suggesting the pointed niche;
   - niche: a dark recess box 1.0 w x 1.5 h x 0.18 d set into the wall, its back a paler gypsum with a carved panel;
   - brass tap (two frustums + a small box, colour brass) at 0.95 m, the existing falling water stream from it;
   - stone basin: a frustum bowl (bottom r 0.22, top r 0.36, h 0.22) on a 0.5 m pedestal, water surface inside;
   - QAMARIYA above the frame: a half-disc 1.3 m wide centred 2.35 m up: a gypsum outer ring (frustum, 16 sides,
     tilted 90 deg, half sunk in the wall) and 7 glowing wedge panes fanned from the centre (thin boxes rotated
     -75..75 deg) in red, orange, yellow, green, cyan, blue, purple, with thin gypsum mullions between them;
   - 2150 layer: a thin cyan glow strip up the wall's right edge, a small grey meter box with an orange glow digit at
     the frame's left, 3 dark cables (thin boxes) running from the meter up and off the wall's top, one copper pipe
     along the bottom;
   - light: a soft warm light 0.6 m in front of the basin and a coloured fill from the qamariya (pool on the floor).
2. Herb stall (the owner's roof concept: a market stall under a striped awning, herbs hanging along its front edge):
   rebuild "herb_stall": wooden counter (keep size and collide); a sloped awning of alternating teal (#2f8f8a) and
   cream (#e8dcc0) stripes 0.25 wide, its front edge scalloped (small boxes); REMOVE every crystal cone, bottle and jar
   of colour. Add: 8-10 bundles of fresh and dried herbs hanging upside down along the awning's front edge
   (frustums, greens, olive, straw, two pink-magenta "feather herb" plumes like his portrait basket); a stepped
   display of 3 wooden crates heaped with greens; a wooden barrel at one end;
   3 woven baskets on the counter heaped with herbs (one with pink feather plumes, one green, one dried brown);
   2 burlap sacks of qishr (coffee husk) beside the counter with rolled tops; a brass hanging scale; the existing price
   holo kept. A warm lantern on the keeper's end (light 0.85 energy, amber) so Abu Nabil reads at night.
3. Budgets: each prop <= 3000 triangles and <= 6 materials (test_workbench has the pattern); every number in JSON.
4. Renders: tools/shot_prop.tscn (+ .gd) taking a prop id: close-up from the play camera height, to
   C:/dev/game/inbox/prop_<id>.png (960x540), for sabil and herb_stall.

## Do NOT edit
content/world/areas.json, tiles.json, buildings.json, camera.json, places, walk_graph, follow_cam (level1-blockout owns
them; Claude places the props at that merge); features/world/weather/, content/world/storm.json (storm); features/combat/,
features/dialogue/, features/items/, content/economy/; tools/art/; docs/design/; HANDOFF.md; docs/DECISIONS.md.

## Tests
Sabil: has a wall slab behind the basin, a glowing qamariya of 7 colours above 2.0 m, still the water + splash; herb
stall: no part with the old cone/bottle colours, >= 6 hanging bundles, >= 3 baskets, a light; budgets for both.

## Proof
`bash tools/check.sh` raw last 15 lines; the two renders; small WIP commits; final message ends with
`Built-by: Gemini 3.8 Flash (agy)`.
