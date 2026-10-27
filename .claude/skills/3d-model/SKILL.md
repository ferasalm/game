---
name: 3d-model
description: Make rigged 3D characters and props (Hyper3D Rodin MCP, then the free route) for sprite baking. Use before any Rodin call, any new character model, or any credit spend.
paths:
  - "assets/**"
  - "tools/rodin/**"
---
# 3D models (Rodin credits, about 50 left on 10-27 minus the Roya jobs in SPEND.md, expire about 2026-11-17)
Never spend credits without Feras's OK in the chat; name the cost first. **One approved hero asset before any batch.**
Every spend gets a line in docs/SPEND.md (date, asset, credits, reason). The P2b chat spent none.

## The Rydan route (transcript f13b2ff6; the settings that worked)
1. Reference: a Flow A-pose picture (arms 30-45 deg down, flat light, grey background), see flow-media.
2. `rodin_create_uploads` {"files":[{"filename":..,"mime_type":"image/jpeg","size_bytes":..}],"kind":"image"} -> upload_id + signed URL.
3. PUT the bytes: `curl -s -o /dev/null -w "%{http_code}\n" -X PUT -H "Content-Type: image/jpeg" --data-binary @<file> "<upload_url>"`.
4. `rodin_generate` {"reference_upload_ids":[id],"prompt":"<name>, a lean game character in A-pose: <clothes>. Ink comic style textures.",
   "mesh_mode":"Raw","quality_override":40000,"tier":"Gen-2.5-Medium","geometry_file_format":"glb"}. Options seen: mesh_mode
   Raw|Quad; tier Gen-2.5-Medium|High|Extreme-Low. A Quad mesh came out ~12k faces: ask for ~7k (docs/archive/design-3d/characters-3d.md).
5. `rodin_wait` {generation_id, timeout_seconds}; `rodin_generate_rigging` {"asset_id":<generation id>,"bone_template":"human_UE",
   "geometry_file_format":"glb"} (`human_UE` = the old `ue` 70-node rig, so ModelRig retargets the UAL clips; NO animation_preset:
   presets need the `human` skeleton and fail with "Animation retarget requires target Hips"); `rodin_wait` the rig
   generation id; `rodin_get_result` -> signed GLB URL.
6. `curl -s -o inbox/rodin/<id>_rigged_shaded.glb "<url>"`, then
   `python tools/rodin/rewrite_glb.py inbox/rodin/<id>_rigged_shaded.glb - assets/characters/<id>_rodin.glb`
   (usage: SRC IDX_BIN DST [--cut BOX | --keep BOX] [--press BOX] [--place OX,OY,OZ,YAW_DEG,SCALE]); the texture comes out as t_<id>.png.
   Texture: pull the GLB's one image (2048 png) and resize to 1024 as assets/characters/t_<id>.png (Roya 2026-10-27).
7. ModelDef with `pose_source`, then the bake: docs/archive/design-3d/characters-3d.md steps 3-6 and the sprite-bake skill.
The Rodin tools are deferred: ToolSearch "hyper3d rodin" loads them (the MCP may still be connecting at session start).

## Batch priorities (plan section 12)
1. One approved hero asset. Then the cast (Roya, the prison guard, Abu Nabil, enemies; Zayd is a rookie officer), recurring
   props, icons, the title video. Rigs and animation presets fetched for each.
2. Every recurring character is baked to colour (+ normal) sheets so all of them light the same way.

## Free route (UNVERIFIED stub; an art-chat task to prove before access ends)
- Image to 3D: TRELLIS / Hunyuan3D / TripoSR on Hugging Face Spaces. Test one character.
- Or Blender MCP `search_assets` / `import_asset` from CC0 libraries (Poly Haven, Poly Pizza; Sketchfab only with a licence check).
- Rig with Blender Rigify, then the ModelRig retarget and the bake. Write the test result here.

## Style (CANON 2026-10-27)
Every character reference: Flow picture in the unified Basilisk anime + sumi-e ink style, full colour, A-pose, plain grey
background; Feras OKs the picture before any credit is spent. Roya = inbox/flow/roya_style_v3_2k.jpg; Rydan and Bilqis v2
pictures (inbox/flow/*_style_v2_2k.jpg) wait for their re-model batch.
