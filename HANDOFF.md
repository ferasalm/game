# HANDOFF (current state only; rewritten by /handoff; max 60 lines)
Last updated: 2026-10-22, session 11 (Opus 5.5, `claude-opus-5-5`, side session of 10, high): v0.3 "Painted Rooftops",
Phase 2. Specs in docs/design/: v03-plan, characters-3d (8 = Rodin pipeline), identity, zayd-moves, hilt-stones, music.

## Status
- Branch claude/night-sanaa, merged to main. 587 tests.
- Merged: agy save-slots (3 slots picked at the sabil with overwrite confirm; title menu Continue / New Game / Load;
  pause Load; retry loads the last slot; per-checkout test save folders). Worktree and branch removed.
- All Feras's Rodin models are in game: Bilqis (7.9k tris, casts with her prosthetic right arm), Abu Nabil (8.2k),
  the Concession enforcer (7.5k, baked baton, attack now sword_attack), the drone hull (5.2k, part kind `mesh`), and
  the grandfather hilt as Rodin grip + sheath (HiltParts `scene`/`sheath_scene`; the blade is still HiltMesh's).
  Stand-in garments are gone. Zayd's baked dagger is pressed flat (`--press`); his hilt now sits at his belly front,
  curving sideways, over the pressed spot (a faint paint remnant shows beside it).
- tools/rodin/rewrite_glb.py: rigid models (no skin lift), `--cut/--keep/--press/--place` (characters-3d.md 8 step 6).
- Music in game: 10 tracks (title, explore_souq, sabil, workshop, 3 battle themes per encounter, boss_abu_nabil,
  victory); menus and the stall keep the area music. Abu Nabil spec: docs/design/abu-nabil-boss.md; agy part A
  (combat, brief docs/briefs/abu-nabil-combat.md) running in ../game-wt/abu-nabil-combat.
- Renders judged by Claude only (scratch); the owner has not seen the new cast yet.
- Old WIP worktrees (unmerged, kept): bench prop worktree-agent-a4cf40c0e9518e744; balance worktree-agent-a7a39e37292830460.

## Waiting on the owner
- Pick the look and camera from the spike renders (step 2), then the level work can start.
- Combat style: keep the timeline or move to an action JRPG (he is considering it; settle before more combat work).

## Next steps (one per chat; the owner's playtest of 2026-10-23: docs/design/playtest-2026-10-23.md)
1. Abu Nabil: review + merge agy part A (`bash tools/agy_review.sh abu-nabil-combat`), then brief and run part B
   (dialogue choices, haggle talk, greedy prices, spar) per the spec's build split. Model: Opus. Effort: medium.
2. Look v2 spike: render the camera options (isometric ortho, front 3/4 ortho, telephoto perspective) with a painted
   pass (painterly filter, repainted textures) side by side into inbox/; owner picks. Model: Opus. Effort: high.
3. Playtest bugs via agy: footsteps (contact-synced, quieter), Abu Nabil out of his stall, chest lid. Model: Sonnet.
   Effort: medium.
4. Level redesign after step 2 (Level Designer): two roofs and a bridge from rooftop-v3.md, a tayramana with a majlis
   to enter and drink qishr with Bilqis, the designed workshop (bench prop WIP). Model: Opus. Effort: high.
5. After the combat-style decision: Zayd kit (zayd-moves.md), hilt stones. Model: Opus. Effort: medium.
6. Architecture fixes via agy (audit top 5); balance (WIP branch). Model: Sonnet. Effort: medium.

## Paste-ready prompt
```
Continue the game repo (ferasalm/game), v0.3. Read HANDOFF.md. Do Next step 1 only: review and merge the agy run
abu-nabil-combat, then write and run part B of docs/design/abu-nabil-boss.md via agy; check.sh, /handoff.
```
