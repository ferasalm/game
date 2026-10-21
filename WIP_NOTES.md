# Look spike WIP notes (delete before merge)
Branch worktree-agent-a4e91f85045597ede, merged claude/night-sanaa (ff). Lint ok; check.sh NOT run yet.

## Done (committed)
- painted_light.gdshaderinc (paint_mix 0 = plain Lambert, so the night look is unchanged); included in
  character.gdshader (light()), painted_world.gdshader, painted_figure.gdshader.
- PaintDef (features/world/defs/paint_def.gd): "paint" object of a look entry; LookDef.paint + camera_preset.
- CameraRigDef.presets (camera.json: diorama 35, high 45, hades 55 deg, distance 26-27, fov 30, own DoF);
  ExploreCamera uses rig.pose_for(look) (replaces look.camera_offset/fov/dof when a preset is named).
- PaintedMaterials (routes SurfaceMaterials.tile/facade/trim and Diorama.material when a painted look is in use),
  PaintedAtlases (atlas ids, sha256, bake.json reader), tools/export_atlases.gd (headless, writes .bake/atlases).
- tools/art/painterly_bake.py + painterly_recipes.json (wash, oil) -> assets/textures/painted/<recipe>/*.webp +
  bake.json + manifest entries. WebP q90, not PNG (PNG facades were 1.3 MB each; WebP ~0.2 MB). Folder has
  .gdignore; loaded as bytes (load_webp_from_buffer). Full bake ran OK (wash 2.3 MB, oil 2.6 MB, 26 files each).
- ink_outline.gdshader (depth+normal Sobel, render_priority MIN, fog fade), painted_screen.gdshader (vignette,
  grain, CanvasLayer -1), PaintedLook (pick look= arg, begin/finish, LUT ImageTexture3D split tone, AA per
  viewport: no project.godot edits at all), PaintedFigure (static painted Zayd, hides the CharacterVisual).
- rooftop.gd: PaintedLook.begin before build, finish after actors (197 lines now: at the cap, don't add).
- look.json: painted_a (high cam, wash, 3 bands, outline 1.5), painted_b (diorama cam, oil, 5 soft bands, thin
  outline 1.0), painted_c (hades cam, wash, 2 bands, thick outline 2.2, strong vignette + saturated LUT).
- tests: features/world/tests/test_painted.gd (not run yet); tools/art/test_painterly_bake.py (passes; added to
  check.sh art_tools).

## In progress
- First render of painted_a done (scratchpad a1/, fallback textures, before the bake finished), NOT viewed yet.
- figure not cut yet: run `python tools/art/figure_cut.py --in C:/dev/game/inbox/flow_zayd_full_a.png --id zayd`
  (left half of the sheet; writes assets/textures/painted/figures/zayd.webp + manifest). test_painted needs it.

## Next steps
1. Cut the figure; `tools/run_godot.sh --import`; `tools/check.sh`; fix FAIL lines (shader compile errors show
   only in non-headless renders: grep the render log for SHADER ERROR).
2. Render each variant (rooftop_shot.tscn -- 5.5 8.6 look=painted_X; wide = preset camera; close = 9 free-camera
   args before look=). 1280x720 into C:/dev/game/inbox/spike/{A,B,C}_{wide,close}.png; view 640x360; iterate.
3. fps_probe on prototype_main with `-- res://features/prototype/prototype_main.tscn 6 look=painted_X`
   (fps_probe reads args[0]/[1] positionally; look= goes last).
4. Check camera is not inside skyline towers at 26-27 m (tune distance/pitch), compare SMAA vs msaa2.

## Gotchas
- -s SceneTree scripts can't name autoloads (ContentDB) at compile time: load helper scripts at run time.
- The bash tool refuses complex one-liners (timeout/$VAR/inline python): write scripts to files in .bake/.
- Don't edit character_visual.gd / character_motion.gd (another builder). Don't touch core/.
- Bake takes ~5 min for both recipes; re-run after any painter or building change (test_painted fails otherwise).
