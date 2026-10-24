# Brief: render-clean-fix2 (<= 60 lines; fix pass on top of gemini/render-clean-fix)
You are in your own worktree on branch gemini/render-clean-fix2 (made from gemini/render-clean-fix). Follow GEMINI.md.
Load the godot-shader-developer and technical-artist skills. Read docs/briefs/render-clean.md and
docs/briefs/render-clean-fix.md first.

## Why
Feras (2026-10-24), after both passes: "the floor still looks unstable". A still render cannot show it: the roof
floor (dark wet spots, ripple rings, painted tiles) shimmers while the camera moves. Fix the cause, measured.

## What to build
1. Measure first: tools/flicker_probe.gd + tools/flicker_probe.tscn (a .tscn wrapper, LESSONS 1): load the rooftop in
   the DEFAULT look (painted_b), rain on, walk the party 3 m in a straight line at walk speed over 60 frames, grab
   each frame, and over the floor region (pixels whose depth hits a roof floor; or the lower 40% of the screen)
   print `FLICKER <mean abs luminance change of each pixel between frames minus the change explained by the camera
   motion>`; simplest valid method: render twice, once with ripples/puddles/wet spots off, and report both numbers.
   Write the numbers BEFORE any fix into your final message.
2. Suspects, check each and fix what is guilty (say which in the final message):
   a. Painted textures loaded with Image.load_webp_from_buffer (PaintedMaterials, ModelMaterials.load_texture) get
      no mipmaps: call image.generate_mipmaps() before ImageTexture.create_from_image, and sample with
      filter_linear_mipmap_anisotropic in every painted shader (painted_world.gdshader and the floor/tile shaders).
   b. Wet-spot and puddle meshes or decals coplanar with the floor (z-fighting): lift them by the content value in
      storm.json (>= 0.01 m) or use a Decal / render_priority; no two surfaces at the same height.
   c. Ripple rings thinner than ~2 px at the play camera distance: widen them via storm.json and fade them out by
      distance (fwidth-based antialiasing in puddle.gdshader: smoothstep over fwidth of the ring distance).
   d. Normal-map or roughness detail aliasing on the floor: mipmaps, or lower the detail strength by distance.
3. After the fixes the floor FLICKER number must drop by >= 50% and the "effects on" number must be within 25% of
   "effects off". Write both after-numbers in the final message.
   (Most loaders already call generate_mipmaps: check the floor/tile and wet-spot textures, which may not.)
4. Tests, one per guilty suspect (e.g. wet spots and puddles sit >= the storm.json lift above the floor under them;
   the ring antialias uniform is set from content; floor textures have mipmaps). Each must fail on the pre-fix code.
   Shader: features/world/weather/view/shaders/puddle.gdshader.
5. Renders from the play camera, DEFAULT look: inbox/render_clean_r1.png and inbox/render_clean_r3.png, plus
   inbox/render_clean_motion.png = a 2x2 grid of frames 0, 20, 40, 60 cropped to the floor.

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
Step 4 names them; keep every existing world and storm test green. No gameplay numbers in code (content JSON).

## Checklist
- file: tools/flicker_probe.gd
- file: features/world/view/shaders/painted_world.gdshader
- file: content/world/storm.json

## Proof
`bash tools/check.sh` raw last 15 lines; FLICKER before/after numbers; the three renders; final message ends with
`Built-by: <model> (agy)`.
