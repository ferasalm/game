# HANDOFF (current state only; rewritten by /handoff; max 60 lines)
Last updated: 2026-10-23, session 12b (Opus 5.5, `claude-opus-5-5`): new direction logged (DECISIONS 2026-10-23),
Phase 2. Specs in docs/design/: v03-plan, characters-3d (8 = Rodin pipeline), identity, zayd-moves, hilt-stones, music.

## Status
- Branch claude/night-sanaa, merged to main. 595 tests (check.sh test cap now 600 s: the suite takes ~5 min).
- Playtest bugs 1-3 fixed (docs/design/playtest-2026-10-23.md), renders judged by Claude only: footsteps sound on
  the walk/run clips' foot contacts (ClipDef.contacts -> clip_event &"footstep"), softer Kenney carpet steps at
  -15/-21 dB, no timer; Abu Nabil stands at his stall's left end (StallKeeper, from the prop's collide box; behind
  it the awning hid him), turned to his talk point in front; a test keeps every NPC off every prop; chests: one lid,
  shut until opened, a lined lid and a dark inside when open; a test per chest (shut, opened, looted after a load).
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
- Play-check the bug fixes: the softer footsteps (carpet samples; other CC0 sets need his OK to download) and Abu
  Nabil at the stall's end (behind the counter the awning hid him).
- Pick a painted route from the step 1 renders.
- Settled 2026-10-23: action combat later (arena kept); environment and levels first; Brothers-style camera outdoors,
  semi-fixed indoors (inbox/camera-refs/); opencode free models join agy as builders.

## Next steps (one per chat; playtest 2026-10-23: docs/design/playtest-2026-10-23.md)
1. Demo push (new chat, Opus high, managing cheap builders): set up opencode (GLM 5.3 Flash, DeepSeek V4.1 Flash)
   beside agy; render the 3 painted routes side by side for Feras; the Brothers-style camera; design level 1 and the
   cyberpunk rooftop souq (docs/design/level-1.md); a demo plan. Model: Opus. Effort: high.
2. agy's abu-nabil-combat (../game-wt/abu-nabil-combat): Feras: let agy finish it; then review + merge
   (`bash tools/agy_review.sh abu-nabil-combat`); the timeline stays until the overhaul. Model: Sonnet. Effort: medium.
3. Action combat overhaul (parry, counter, dodge, light/heavy, lock-on) after the environment. Model: Opus. Effort: high.
4. Architecture fixes via agy/opencode (audit top 5); balance (WIP branch). Model: Sonnet. Effort: medium.

## Paste-ready prompt
```
Continue the game repo (ferasalm/game). Read HANDOFF.md. Do Next step 1 (the demo push), as manager of cheap
builders (agy, opencode); check.sh, /handoff.
```
