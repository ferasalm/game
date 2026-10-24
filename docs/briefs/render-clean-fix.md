# Brief: render-clean-fix (<= 60 lines; fix pass on top of gemini/render-clean)
You are in your own worktree on branch gemini/render-clean-fix (made from gemini/render-clean). Follow GEMINI.md,
including <review_misses>. Load the godot-shader-developer skill. Read docs/briefs/render-clean.md first.

## Why
Review of render-clean: the anti-aliasing never reaches the game's default look, and some fixes are hard-coded.

## What to fix
1. AA in the real look: the rooftop defaults to painted_b (features/world/rooftop/rooftop.gd ~21), whose recipe sets
   "aa": "smaa" (content/world/look.json ~38) and PaintedLook.finish (features/world/view/painted_look.gd ~47-49)
   overwrites the viewport to SMAA with MSAA off. Set "aa": "msaa2" on the painted recipes (look.json ~27, 38, 49;
   the mode exists at painted_look.gd ~18). Test: after PaintedLook.finish with painted_b the viewport has MSAA 2x
   and screen-space AA off.
2. tools/fps_probe.gd: measure the default look (painted_b) and accept a look argument; write avg FPS and the worst
   frame for prototype_main in the final message.
3. Rain/splash plane (features/world/weather/view/storm_host.gd ~113): no hard-coded "camera y - 4.9" or the jump to
   floor_y; use the tile height under the party (as puddle_builder does), lift from storm.json; it must not move when
   the camera frames a speaker. Test: the plane height equals the floor under the party plus the content lift, for
   two different roofs.
4. Ripple and splash fades: the 0.2 fade-in and the other numbers in puddle.gdshader (~41, 46, 51) and the alpha and
   scale curves in storm_builder.gd (~141-151) come from storm.json (uniforms set from content); fade alpha, not the
   normal weight.
5. Painted facades: features/world/view/shaders/painted_world.gdshader ~11 emission sampler gets
   filter_linear_mipmap_anisotropic like the albedo; test the painted materials too (not only StandardMaterial3D).
6. test_storm.gd ~133: replace the 'or' with separate checks for the fade-in and the fade-out curves.
7. Renders with the DEFAULT look (painted_b), from the play camera: inbox/render_clean_r1.png, _r1_b.png, _r3.png.

## Do NOT edit
`core/save/`
`core/game_state.gd`
`features/ui/`
`features/equipment/`
`features/map/`
`tools/check.sh`
`CLAUDE.md`
`docs/DECISIONS.md`
`HANDOFF.md`

## Tests
Steps 1, 3, 5 and 6 name their tests.

## Checklist
- file: content/world/look.json
- file: features/world/weather/view/storm_host.gd
- file: features/world/view/shaders/painted_world.gdshader

## Proof
`bash tools/check.sh` raw last 15 lines; renders; fps numbers; final message ends with `Built-by: Gemini 3.8 Flash (agy)`.
