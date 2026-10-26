# Lessons archive (3D-only; moved 2026-10-25 when 3D was archived, tag 3d-archive)

- Lathe garments: torso pieces end at the waist over pelvis pieces raised 0.15 m; coats split at the pelvis (2026-10-22).
- Rodin glb: centred feet, other bone axes, stale buffers, props baked into the body -> tools/rodin (LOD indices, glb
  rewrite: lift, strip, --press) and PoseFollow (runtime retarget) (2026-10-22).
- Foot heights after seek in a SceneTree script: set bones from the tracks, compose get_bone_pose up the parents.
- SurfaceBuffer boxes have no bottom face -> lids need a tilted lining part (2026-10-23).
- Play-camera traps: a keeper behind his stall hid under the awning (StallKeeper: counter end); the follow camera
  sat 8-10 m back leading along the facing (lead along the view direction) (2026-10-23).
- A new area reusing the old mist ids drowned its lower roofs in fog -> mist per area, >= 2 m below its lowest floor
  (2026-10-23).
- Headless MultiMesh returns identity transforms -> keep them in node meta for tests (2026-10-21).
- load() of a painted .webp returns null: assets/textures/painted/ is .gdignore -> Image.load_webp_from_buffer
  (PaintedMaterials, ModelMaterials.load_texture) (2026-10-23).
- Night billboards with the moon behind go black -> min_light floor; Label3D in fog -> label_energy > 1, no alpha cut.
- Storm rain at 1.5 cm streaks was sub-pixel, and a lightning light barely shows through the painted shaders ->
  2.4 cm streaks and a screen wash (storm.json) (2026-10-23).
- set_exploring(false) hides the player and patrols -> talks use rooftop.freeze_actors (2026-10-22).
- Painted Flow art pixelized muddy -> pixelize.py --contrast 1.3 --saturation 1.5 --outline; check facing first.
