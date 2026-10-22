# HANDOFF (current state only; rewritten by /handoff; max 60 lines)
Last updated: 2026-10-21, session 6 (Opus 5.5, `claude-opus-5-5`, lead, high): v0.3 "Painted Rooftops", Phase 2.
Plan: docs/design/v03-plan.md (B4 replaced by 3D characters). 3D spec: docs/design/characters-3d.md.

## Status
- On claude/night-sanaa, pushed, checked: check.sh all passed, 498 tests. Merged into main at this handoff.
- Merged: Phase 1 (P1a, P1b), the look spike, B1 items + shop, B2 battle arena, B3 painted world (look B),
  B5 level (v3 layout, sabil, stall, 3 patrols), B6 UI v2. Details: git log and the builders' commit messages.
- Contract stubs for B4 are on the branch: ModelSource, ModelDef (kind `model`), `face_dir`, `hit_stop`,
  `visual_rules.default_source`. Characters are still the old pixel sprites (fallback source).
- Not seen by the owner yet: v0.3 in play. Renders: inbox/b3/ (world), inbox/spike/ (looks).
- Open numbers: fps_probe 81.7 on the rooftop with look B (target 90; >= 60 on the Latitude holds). Balance
  harness: rooftop_patrol 73-88% without herbs but 99-100% with herbs; patrol_pair and patrol_drone 100%
  (B5's placeholder encounters). Cut-away FPS while active not measured. Title menu (New/Continue/Quit) not built.
  `Rooftop.frame_speaker` not wired to dialogue. Sounds ui_* missing from sounds.json.

## Waiting on the owner
- Done 2026-10-22: Quaternius zips and Flow pictures (inbox/).
- Optional: Flow model pictures per docs/design/art-prompts-v03.md (Zayd with the hilt, the hilt alone, Bilqis,
   Abu Nabil): A-pose, grey background.

## Next steps
1. B4 3D characters: the lead copies only the used files from inbox/stand_in/ into assets/characters/, writes
   their .import files and manifest entries, then one builder builds characters-3d.md (ModelDef, pure
   clip_timing/locomotion/yaw_turn, ModelSource, painted skin shader, hit-stop, trail, stand-ins incl. Zayd's
   grandfather's hilt, Abu Nabil, drone; tests). Lead views renders. Model: Opus lead; Sonnet builder
   (Technical Artist). Effort: high.
2. Balance pass: Game Designer tunes herbs and the two new encounters into the 73-88% band (harness args in
   features/combat/harness/balance.gd). Model: Sonnet. Effort: medium.
3. Phase 3 integration: title menu, frame_speaker wiring, ui sounds, smoke play-through, renders, fps_probe (look B
   to 90), Code Reviewer (Opus, high) on the integrated diff, merge to main, CI, Checkpoint 2: Feras plays v0.3.
   Model: Opus lead, Sonnet fixes. Effort: high.

## Paste-ready prompt
Rewritten at the session 7 handoff.
