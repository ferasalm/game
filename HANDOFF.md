# HANDOFF (current state only; rewritten by /handoff; max 60 lines)
Last updated: 2026-10-22, session 9 (Opus 5.5, `claude-opus-5-5`, lead + agy, high): v0.3 "Painted Rooftops", Phase 2.
Specs in docs/design/: v03-plan, characters-3d (8 = Rodin pipeline), identity, zayd-moves, hilt-stones, music.

## Status
- Merged to main: Zayd's Rodin model (tools/rodin; PoseFollow retarget via ModelDef `pose_source`); music contexts;
  Abu Nabil + party talks; architecture audit (docs/audits/). 568 tests.
- agy runs still going when this chat ended (worktrees ../game-wt/<task>, logs ../game-wt/<task>.log):
  rooftop-v2 and save-slots (briefs in docs/briefs/). `bash tools/agy_review.sh <task>`; a dead run restarts with
  the same agy_task.sh command (worktree and commits kept).
- Old WIP worktrees (unmerged, kept): bench prop worktree-agent-a4cf40c0e9518e744; balance worktree-agent-a7a39e37292830460.
- Known: Zayd shows two jambiyahs (Rodin baked one + the code hilt part); his cast raises the flesh (left) arm.

## Waiting on the owner
- Music .wav files into inbox/music/ named by id (docs/design/music.md, 9 tracks incl. boss_abu_nabil).

## Next steps (one per chat)
0. Merge finished agy runs; Rodin models: Bilqis (pose_source ubc_female), Abu Nabil, enemy + drone (inbox *_front_gray
   / enemy*.png; ~7k quads, UE rig, tools/rodin, ModelDef swap, render). Zayd: cut the baked dagger (tools/rodin),
   Rodin hilt + sheath (jambiyah_hilt_and_sheath.png, no rig) as the hilt part, mirror his cast (PoseFollow: swap
   _l/_r, reflect x). Model: Opus. Effort: high.
1. Music .wav -> .ogg, assets/audio/music/, manifest. Model: Sonnet. Effort: low.
2. Architecture fixes via agy (audit top 5). Model: Opus. Effort: medium.
3. Abu Nabil mini-boss: Game Designer spec (confuse status, herb heals, stall locked until beaten), agy.
   Model: Opus. Effort: medium.
4. Zayd kit, then hilt stones via agy. Model: Opus. Effort: medium.
5. Balance (WIP branch), bench + hook motif, then Phase 3 + Checkpoint 2. Model: Sonnet. Effort: medium.

## Paste-ready prompt
```
Continue the game repo (ferasalm/game), v0.3. Read HANDOFF.md. Do Next step 0 only: merge the finished agy runs,
make Bilqis, Abu Nabil and the enemies with Rodin (cost first), fix Zayd's dagger and cast arm, renders, check.sh, /handoff.
```
