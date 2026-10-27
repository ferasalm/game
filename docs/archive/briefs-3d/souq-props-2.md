# Brief: souq-props-2 (<= 60 lines)
You are in your own worktree on branch gemini/souq-props-2, made from gemini/souq-props (your first pass). Follow
GEMINI.md, including <review_misses>. Claude reviewed inbox/prop_sabil.png and prop_herb_stall.png against the owner's
concepts (C:/dev/game/inbox/level1_concept_sabil.png, level1_concept_roofs.png: the stall on the left). Build EXACTLY
the recipes below; a recipe is a geometry rule, follow its numbers. Keep budgets (<= 3000 tris, <= 6 materials).

## Herb stall: the herbs still read as coloured cones and gems. Replace them.
1. Herb bundle recipe (8 bundles along the awning's front edge, 0.22 m apart): a tie point; from it 7 "blades" hang
   down: thin boxes 0.018 w x 0.32 h x 0.006 d, each tilted outward from vertical by 6, 10, 14 deg in a fan around
   the bundle's axis (yaw steps of 360/7 deg), centres 0.16 below the tie; a dark twine box 0.05 x 0.03 x 0.05 at the
   tie; a 0.12 m cord box up to the bar. Colours per bundle, from a seeded pick: sage #7f9a6a, olive #5f7040, dried
   straw #b89c5a, deep green #3f6b45; bundles 3 and 6 are "feather herbs": blades 0.03 wide, colour #e05aa8, tilt 18 deg.
   NO frustum anywhere in a bundle.
2. Basket recipe (3 on the counter): a woven body = frustum (bottom r 0.14, top r 0.18, h 0.12, sides 10, colour
   wicker #8a6a3f) plus 3 thin rim rings (frustum, h 0.012, colour #6e5230); the heap = 12 leaf boxes
   0.07 x 0.012 x 0.035, scattered (seeded) over the top disc, raised 0.01-0.06, random yaw, tilt up to 25 deg; heap
   colours: basket 1 feather pink #e05aa8 + #f08cc4; basket 2 greens #4f7f4a + #7f9a6a; basket 3 dried #9a7a48 + #b89c5a.
3. Awning: a sloped canopy over the counter, front edge 2.05 m high, back edge 2.35 m, depth 1.1, made of 8 stripe
   boxes 0.25 wide x 0.02 thick alternating teal #2f8f8a and cream #e8dcc0, tilted 15 deg toward the front; a row of
   16 small scallop boxes 0.12 x 0.06 x 0.01 hanging from the front edge, same alternation. It must cover the bundles
   from above in the play-camera render.
4. Remove the gem-like frustum mounds; keep the counter, crates of greens (re-make their heaps with recipe 2's leaves),
   barrel, qishr sacks, scale, price holo and lantern.

## Sabil: right structure, wrong materials and placement.
5. Wall: warm mud-brown #6b4a35 with pattern "plaster_worn" (not the dark basalt), 2.2 w x 2.8 h x 0.3 d as before.
6. Qamariya SET INTO the wall: its flat base sits on the lintel's top edge (no gap), panes flush with the wall face
   (z = +0.01), a gypsum ring frustum around the half-disc 0.04 proud; panes keep the 7 colours.
7. Pointed niche: replace the stepped boxes with two gypsum boxes 0.08 thick, tilted +-32 deg, meeting at an apex
   0.25 below the lintel, so the niche top reads as a pointed arch; the recess behind stays dark.
8. Basin pale limestone #d8d0c0 (bowl and pedestal), not orange; tap brass #c8a040, its spout 0.04 r, 0.15 long,
   clearly sticking out at 0.95 m above the basin's water.

## Renders and tests
9. tools/shot_prop: add a "play" view: the camera 6 m away, 4 m up, looking down 35 deg (how the player sees props);
   render both props in close-up AND play view to inbox/prop_<id>.png and inbox/prop_<id>_play.png.
10. Tests: a bundle has >= 7 blades and no frustum; each basket heap has >= 12 leaves; the awning stripes alternate the
    two colours; the qamariya base height equals the lintel top (+-0.01); the basin is not orange.

## Do NOT edit
Everything outside content/world/props.json items "sabil" and "herb_stall", their tests, and tools/shot_prop.*:
the level1-blockout-fix run owns areas.json, mist.json, walk graph and rooftop tests.

## Proof
`bash tools/check.sh` raw last 15 lines; the four renders; WIP commits after each numbered item; final message ends
with `Built-by: Gemini 3.8 Flash (agy)`.
