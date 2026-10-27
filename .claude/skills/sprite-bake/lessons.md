# sprite-bake lessons (seed: docs/LESSONS.md section 5; dated lines, <= 40)
- Iso sprites: the Rodin rig `ue` = the old 68-bone rig, so ModelRig retargets UAL clips; bake_sprites.tscn renders them (ortho, 30 deg, own unshaded ink shader + hull) (2026-10-26).
- 256-colour sheets were 1/6 the size; the Hades bar is full colour, so the packer now defaults to colours=0 (2026-10-27).
- A Node script under `-s` fails; render tools run as a .tscn wrapper, non-headless (2026-10-23).
- Fresh checkout bake fails with "Could not find type ..." parse errors: run `tools/run_godot.sh --import` first; exit 139 = memory, rerun (2026-10-27).
- A silent hang costs 20+ min: `timeout`, `< /dev/null`, one Godot at a time (2026-10-25).
