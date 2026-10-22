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
- Look at the rooftop v2 renders (inbox/rooftop_v2_*.png): keep the layout and dress it, or ask for another layout.
- Look at the cast in game (Rodin models): run the prototype, or ask for a render into inbox/.

## Next steps (one per chat)
1. Abu Nabil: review + merge agy part A (`bash tools/agy_review.sh abu-nabil-combat`), then brief and run part B
   (dialogue choices, haggle talk, greedy prices, spar) per the spec's build split. Model: Opus. Effort: medium.
2. Rooftop v2 dressing (stair head, mafraj, tanks in the `T` corners; workshop off the bridge tiles; Abu Nabil's stall
   late on the roof with a sneak path past the patrols) via agy. Model: Sonnet. Effort: medium.
3. Architecture fixes via agy (audit top 5). Model: Opus. Effort: medium.
4. Zayd kit, then hilt stones via agy. Model: Opus. Effort: medium.
5. Balance (WIP branch), bench + hook motif, then Phase 3 + Checkpoint 2. Model: Sonnet. Effort: medium.

## Paste-ready prompt
```
Continue the game repo (ferasalm/game), v0.3. Read HANDOFF.md. Do Next step 1 only: review and merge the agy run
abu-nabil-combat, then write and run part B of docs/design/abu-nabil-boss.md via agy; check.sh, /handoff.
```
