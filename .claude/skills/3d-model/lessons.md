# 3d-model lessons (dated lines, <= 40)
- Rodin rig `ue` = the old 68-bone rig, so ModelRig retargets the UAL clips (2026-10-26).
- A Quad mesh came out ~12k faces (~25k triangles): ask ~7k quads; textures are stripped and re-baked to t_<id>.png at 1024 (docs/design/characters-3d.md).
- Rig presets with `human_UE` fail ("requires target Hips"; charge unknown): rig human_UE bare, clips come from ModelRig (2026-10-27).
- No balance tool in the MCP: per-job cost stays an estimate until Feras reads hyper3d.ai before/after; log both in SPEND (2026-10-27).
- Free memory under the 3 GB floor (Chrome + Blender open) blocks the bake: close them or bake in the next chat (2026-10-27).
- Measured cost: Medium Quad model + UE rig = 1.5 credits per character; a failed rig cost nothing (Roya, 2026-10-27).
