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
  (`next_pass`, flag per model) if silhouettes vanish against walls; thin parts like the djanbeyyah may need it.
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
- `content/art/models.json`, kind `model` (ModelDef): `scene`, `height_m`, `radius`, `anchors` (hand, head, hilt,
  tip as bone names; feet = origin), `states` (each of the 9 facade states -> an animation), `stride_m`,
  `turn_speed`, `tint`, `outline_hull`.
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

## 8. Feras's own models later (not in v0.3's build)
1. A Flow picture per hero: full body, front view, camera at chest height, little perspective; **A-pose** (arms
   30-45 degrees down, not a T-pose), fingers apart, legs slightly apart, feet visible; flat even light, no cast
   shadows or rim light, plain grey background (no green); scarf and coat close to the body; the weapon in a
   separate picture. Matching side and back views if the tool takes more than one.
2. Image-to-3D: TRELLIS.2 (MIT licence) on its Hugging Face Space (Feras logs in; free quota unverified). Fallback:
   Meshy free tier (outputs CC BY 4.0: credit in the manifest). Hunyuan3D-2.1's licence excludes the EU, UK and South
   Korea: avoid.
3. Claude reduces triangles, fixes UVs and repaints in Blender (ask the owner's OK to install it first), then
   auto-rigs (AccuRIG or Meshy; Feras logs in).
4. The ModelDef points at the new scene: no code change.
