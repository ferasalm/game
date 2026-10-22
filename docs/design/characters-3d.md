# Live 3D characters (v0.3 B4 spec; replaces the painted puppets)
Owner decisions 2026-10-21 (DECISIONS): live 3D skinned models in the 3D diorama (2.5D, aiming at Hades quality,
motion and design), painted shader + ink outline; CC0 stand-in bodies now, Feras's own models later through a free
image-to-3D tool; CC0 moves only (no Mixamo: the repo is public) plus Claude's polish. Design by the Technical Artist;
items marked (unverified) were not confirmed on the source page.

## 1. Sources (all CC0 in the repo; only the files used are copied in, never whole zips)
- **Bodies:** Quaternius "Universal Base Characters" (quaternius.itch.io/universal-base-characters), CC0, humanoid
  rig, about 13k triangles. Standard (free) zip about 122 MB: 2 bodies, 5 hairstyles, no animations. Feras downloads
  it into inbox/stand_in/ (itch.io has no curl link).
- **Moves:** Quaternius "Universal Animation Library" (quaternius.itch.io/universal-animation-library), CC0, FBX/GLB,
  Standard about 15 MB, 45 clips. Which combat clips the free tier has is (unverified): missing attack, cast and item
  clips are keyed by script on the humanoid skeleton.
- **Fallback:** KayKit Adventurers (github.com/KayKit-Game-Assets/KayKit-Character-Pack-Adventures-1.0), CC0, curl-able,
  but chibi proportions are off-style.
- **Survey drone:** a rigid three-part model animated in code, not a skinned body.
- Every file gets a manifest entry (source URL, CC0). The lead writes the .import files (agents can't).

## 2. Import and retargeting (no Blender for the stand-ins)
- Godot 4.7 imports .glb and .fbx headless. `filesystem/import/blender/enabled=false` so a stray .blend can't break CI.
- Retarget at import: BoneMap with SkeletonProfileHumanoid, Rename Bones, Unique Node, Overwrite Axis; Fix Silhouette
  for A-pose bodies with the feet in its filter list.
- Imported clips are shared and lose edits on reimport: events and retiming live in JSON (ClipDef), never in tracks.

## 3. Shading (one light model with the world)
- A skinned spatial ShaderMaterial includes `painted_light.gdshaderinc` (the spike's): banded light, indigo shadow
  tint, rim, min_light floor. It keeps the facade's flash, desat, glow and tint uniforms.
- Textures: one painted albedo (soft light and cavity darkening baked in), an emission mask for neon, no normal or
  roughness maps, low specular. AI textures go through `tools/art/painterly_bake.py`.
- Outline: the spike's screen-space depth+normal pass (models write depth and normals). An optional inverted hull
  (`next_pass`, flag per model) if silhouettes vanish against walls; thin parts like the jambiyah may need it.
- Shadows: characters cast into the moon's directional shadow only, never lamp shadows; a blob contact decal always.

## 4. Motion (the Hades feel)
- Locomotion: BlendSpace1D idle/walk/run by speed; playback rate = speed / `stride_m`, so feet never slide. No foot IK
  on flat roofs.
- AnimationPlayer in MANUAL callback mode, advanced by `advance()` from pure ClipTiming: each one-shot clip plays in
  segments: wind-up about 0.7x, a hold of about 80 ms, the strike about 1.8x, then recovery. `impact_t` fires
  clip_event(&"impact"); the end fires &"end".
- Hit-stop: a per-character freeze of 60-90 ms on attacker and target (`CharacterVisual.hit_stop`), never
  Engine.time_scale.
- Weapon: a ribbon trail between hilt and tip BoneAttachment3D points; an arc smear card on the strike frame.
- Squash on the facade's body node (not bones); lean 6-8 degrees from acceleration; yaw turn about 900 deg/s.
- Facing: `CharacterVisual.face_dir(Vector3)` sets a target yaw, with a 3/4 bias toward the camera in battle. Never
  mirror a model with a negative scale (it breaks winding and right-hand weapons).
- Every number above is a [PLACEHOLDER] in content/art JSON, tuned on renders.

## 5. Data
- `content/art/models.json`, kind `model` (ModelDef): `scene`, `height_m`, `radius`, `anchors` (hand, head, belt,
  hilt, tip as bone names; feet = origin), `states` (each of the 9 facade states -> an animation), `stride_m`,
  `turn_speed`, `tint`, `outline_hull`, `attachments` (parts worn on an anchor: a mesh scene each).
- **Zayd's default skin always wears his grandfather's jambiyah hilt** (owner, 2026-10-21): a separate attachment
  (`grandfather_hilt`, the Heirloom item) sheathed at the front of his belt while exploring, moved to the hand anchor
  for strikes and back after. One part, modelled once; a stand-in mesh until Feras's picture (section 8).
  Heirloom accent: carnelian red #d9503f (rarities.json).
- `content/art/clips.json`, kind `clip` (ClipDef): per animation `seconds`, `loops`, `impact_t`, wind-up/hold/strike.
- `visual_rules.default_source`: "pixel" or "model". `set_sprite(id)` picks per character: a ModelDef with that id
  swaps in a ModelSource; otherwise the pixel sprite stays.

## 6. Budgets (Iris Xe; confirmed with fps_probe)
Hero 15k triangles, enemy 10k, NPC 7k; at most 90k character triangles on screen; at most 70 bones; 1 material
(2 at most); albedo 1024x1024 (VRAM compressed) plus a 256x256 emission mask; automatic mesh LOD on.

## 7. Tests (headless; never pixels)
- Pure: every model maps all 9 states; the ClipTiming curve and its events; the yaw step; stride to playback rate.
- On the imported model: Skeleton3D and named bones exist; anchors resolve; every mapped clip exists; every
  `impact_t` lies inside its clip; bone, triangle (index count / 3), surface and texture counts within budget.
- Battle waits on clip_event, never a timer; facing never uses a negative scale.

## 8. Feras's own models (Hyper3D Rodin)
1. A Flow picture per hero: full body, front view, camera at chest height, little perspective; **A-pose** (arms
   30-45 degrees down, not a T-pose), fingers apart, legs slightly apart, feet visible; flat even light, no cast
   shadows or rim light, plain grey background (no green); scarf and coat close to the body; the weapon in a
   separate picture. Matching side and back views if the tool takes more than one. Zayd's picture shows the
   grandfather's hilt sheathed at the front of his belt, and a separate close picture of that hilt (front and side)
   becomes its own 3D part.
2. Image-to-3D: Hyper3D Rodin (Feras's Creator plan), driven by Claude through the hyper3d MCP: upload the picture
   (up to 5 views), `rodin_generate` Gen-2.5-Medium, mesh_mode Quad, about 10-15k faces, glb; then
   `rodin_generate_rigging` with bone_template `ue` (the Quaternius rig's UE names: pelvis, spine_03, hand_r) and no
   animations. Claude names the credit cost before each paid call and never retries a timed-out one (check Hyper3D
   Mine). Before the first manifest entry Claude reads Hyper3D's terms for the output licence.
3. Slim it (no Blender, no downloads): `SRC=<rigged.glb> IDX=<tmp>/idx.bin DST=<tmp>/junk.glb MAX_TRIS=14800
   "$(tools/godot.sh)" --headless --path . -s tools/rodin/slim_indices.gd`, then
   `python -I tools/rodin/rewrite_glb.py <rigged.glb> <tmp>/idx.bin assets/characters/<id>_rodin.glb`: Godot's LOD
   simplifier, textures and materials stripped, feet lifted to y=0, UE `head` renamed `Head`. The diffuse becomes
   `t_<id>.png` at 1024 (the painted shader takes the ModelDef's `skin`). Quad 12k faces = ~25k triangles: ask for
   about 7k quads next time and the simplifier has less to do.
4. Retarget at run time: the Rodin UE rig has other bone axes and rest pose than the library, so the ModelDef names
   `"pose_source": "res://assets/characters/ubc_male.gltf"` (ubc_female for women): that body plays the clips hidden
   and PoseFollow turns each same-named bone to point where the source bone points (twist and ik bones keep rest;
   the hips' travel scales with hip height). Stand-in garment parts go; the hilt part stays.
5. Check: test_model_defs, test_pose_match, a render beside the cast (Zayd: inbox/zayd_rodin_cast.png).
