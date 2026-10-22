# HANDOFF (current state only; rewritten by /handoff; max 60 lines)
Last updated: 2026-10-21, session 6 (Opus 5.5, `claude-opus-5-5`, lead, high): v0.3 "Painted Rooftops", Phase 2.
Plan: docs/design/v03-plan.md; 3D spec: docs/design/characters-3d.md.

## Status
- On claude/night-sanaa, pushed, checked: check.sh all passed, 498 tests. Merged into main at this handoff.
- Merged: Phase 1, spike, B1, B2, B3, B5, B6 (git log).
- Contract stubs for B4 are on the branch: ModelSource, ModelDef (kind `model`), `face_dir`, `hit_stop`,
  `visual_rules.default_source`. Characters are still the old pixel sprites (fallback source).
- Owner has not played v0.3 yet.
- Open: fps_probe 81.7 on the rooftop (target 90). Cut-away FPS unmeasured. Title menu not built.
  `Rooftop.frame_speaker` not wired to dialogue.

## Waiting on the owner
- Done: zips, pictures (inbox/).
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
