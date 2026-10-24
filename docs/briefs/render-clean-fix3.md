# Brief: render-clean-fix3 (<= 60 lines; fix pass on top of gemini/render-clean-fix2)
You are in your own worktree on branch gemini/render-clean-fix3 (made from gemini/render-clean-fix2). Follow GEMINI.md.
Load the godot-shader-developer and test-results-analyzer skills. Read docs/briefs/render-clean-fix.md and
docs/briefs/render-clean-fix2.md first. Skip any item below that fix2 already did (say which in the final message).

## Why
Review of render-clean-fix (2026-10-24): the ripple fade still scales the normal weight, some tests cannot fail, and
some content values have duplicate code defaults.

## First: find the real shimmer (fix2 did not move it)
Claude ran tools/flicker_probe.tscn on gemini/render-clean-fix and on fix2: FLICKER 0.003016 vs 0.003037, effects on
0.0218 vs off 0.0223, so puddles/ripples are NOT the cause and fix2 changed nothing Feras can see. In fix2's
inbox/render_clean_motion.png the dark wet-spot patches differ from frame to frame (they appear and vanish) and the
parapet walls carry a speckled high-frequency texture.
Feras (asked 2026-10-24) says it is mostly the TILE/BRICK PATTERN: the floor and roof brick texture crawls, sparkles
or swims as the camera moves (aliasing / moire), not the wet spots. fix2 already set SurfaceMaterials._base to linear
anisotropic and it did not help, so the painted_b look draws the bricks elsewhere: find where (painted_world.gdshader
procedural pattern? PaintedMaterials atlas sampled without mipmaps or with a UV scale that defeats them? diorama.gd
~110 TEXTURE_FILTER_NEAREST? a pixelize/posterize step?) and fix it at the cause: mipmapped, anisotropic sampling;
a procedural pattern gets fwidth-based antialiasing that fades the mortar lines to the average colour by distance;
keep the painted look's colours. Test: the floor/roof materials of painted_b sample with mipmaps (fails pre-fix).
A. Extend tools/flicker_probe.gd to save inbox/flicker_heat.png: per pixel, the frame-to-frame luminance change
   summed over the 60 frames (motion compensated by reprojecting with the camera, or with the camera still and the
   party walking), normalized, as a heat map over frame 0; and inbox/flicker_walk.gif (the 60 frames, 640 px wide).
B. Name the hottest regions (wet-spot decals popping by distance/LOD, wall speckle, floor tile pattern, shadow acne,
   rain streaks) in the final message, fix each at its cause, and show the heat map before and after
   (inbox/flicker_heat_before.png, inbox/flicker_heat.png). Ignore rain streak pixels in the metric (mask them).
C. The probe's FLICKER number on the floor region must drop by >= 40% after the fix; write both numbers.

## What to fix
1. features/world/weather/view/shaders/puddle.gdshader ~45-57, ~75: the ripple fade-in/out multiplies ALPHA (a ring's
   own alpha), not the normal weight; ALPHA = edge_alpha * ring fade. Test: the fade uniforms reach the material and
   the shader source writes the fade into ALPHA (a test that fails on the old shader).
2. features/world/weather/tests/test_storm.gd ~171-175: assert frame_speaker's bool, then call the host's update()
   by hand with a moved camera and check the plane height did not change. Must fail if the plane follows the camera.
3. test_storm.gd ~157-168: take the R1 and R3 floor heights from the area content / the rooftop, not -0.8 and 1.6.
4. test_storm.gd ~137: sample the fade curves at 0.0, 0.5 and 1.0.
5. puddle_builder.gd ~61-63: placement rejects puddles whose XZ rects overlap on one roof (so no two puddles share a
   plane); test_render_clean.gd ~38-44 tests that with two seeds, and its message says what it checks.
6. test_render_clean.gd ~12-14 and test_storm.gd ~16-17: replace the "json has key" checks with behaviour (the
   loaded material/curve uses that value).
7. storm_def.gd ~25-28, 42-45, 114-117, 134-137: the new storm.json keys are required (push_error on a missing key,
   no duplicate code default numbers). storm_builder.gd ~123-124 scale range and ~143 alpha level come from their own
   storm.json keys.
8. surface_materials.gd ~133 _base must not change far() silhouettes (~108): keep far() as on origin/main.
9. painted_look.gd ~21-27: drop the process-wide static override; tools/fps_probe.gd passes the look name as an
   argument to the scene instead.

## Do NOT edit
`core/`
`features/equipment/`
`features/map/`
`features/ui/`
`tools/check.sh`
`CLAUDE.md`
`docs/DECISIONS.md`
`HANDOFF.md`

## Tests
Steps 1-6 name them; keep every world and storm test green.

## Checklist
- file: features/world/weather/view/shaders/puddle.gdshader
- file: features/world/weather/tests/test_storm.gd
- file: features/world/weather/defs/storm_def.gd

## Proof
`bash tools/check.sh` raw last 15 lines; inbox/render_clean_r1.png again; final message ends with
`Built-by: <model> (agy)`.
