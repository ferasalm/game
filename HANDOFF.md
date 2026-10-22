# HANDOFF (current state only; rewritten by /handoff; max 60 lines)
Last updated: 2026-10-22, session 10 (Opus 5.5, `claude-opus-5-5`, side session of 9, high): v0.3 "Painted Rooftops",
Phase 2. Specs in docs/design/: v03-plan, characters-3d (8 = Rodin pipeline), identity, zayd-moves, hilt-stones, music.

## Status
- Branch claude/night-sanaa, merged to main. 571 tests.
- Merged: agy rooftop-v2 (Funduq Roof, Souq al-Milh: one 34x26 terrace; save points fall back to spawn_start).
  Renders inbox/rooftop_v2_*.png: breathing room yes, but it reads as an empty dark square: the `T` corners show no
  stair head / mafraj / tanks, the workshop stands on `=` bridge tiles. Needs a dressing pass.
- Zayd's cast is mirrored (ModelDef `mirror_states`, PoseFollow.apply(mirrored)): his cyber right arm casts.
- Rodin (8 paid calls used): Bilqis, Abu Nabil, enemy generated (Quad 7k) and rigged (ue); drone (5k) and the
  jambiyah hilt+sheath (3k, front+side views) generated, no rig. Raw files in inbox/models/ (git-ignored):
  bilqis/abu_nabil/enemy_rodin_rigged.glb, drone_rodin_raw.glb, hilt_rodin_raw.glb. Not slimmed or in game yet.
  Generation ids: side-session notes rodin-session10.md (also in the session 10 transcript).
- agy save-slots still running at the end (worktree ../game-wt/save-slots, uncommitted edits; log
  ../game-wt/save-slots.log). `bash tools/agy_review.sh save-slots`; a dead run restarts with the same agy_task.sh.
- Old WIP worktrees (unmerged, kept): bench prop worktree-agent-a4cf40c0e9518e744; balance worktree-agent-a7a39e37292830460.
- Known: Zayd shows two jambiyahs (Rodin baked one + the code hilt part).

## Waiting on the owner
- Music .wav files into inbox/music/ named by id (docs/design/music.md, 9 tracks incl. boss_abu_nabil).
- Look at the rooftop v2 renders: keep the layout and dress it, or ask for another layout.

## Next steps (one per chat)
0. Merge save-slots. Rodin into the game (characters-3d.md 8 step 3-5): slim Bilqis, Abu Nabil, enemy; textures
   t_<id>.png; models.json scene + pose_source (bilqis: ubc_female, `mirror_states: ["cast"]`, her prosthetic is
   her right arm); drop stand-in garments; manifest (read Hyper3D terms first); render beside the cast.
   Then tools/rodin: skin optional in rewrite_glb.py; a region cut (drop triangles inside a box) to remove Zayd's
   baked dagger and to split the Rodin hilt into grip + sheath for HiltParts; a `mesh` part kind for the drone hull.
   Model: Opus. Effort: high.
1. Music .wav -> .ogg, assets/audio/music/, manifest. Model: Sonnet. Effort: low.
2. Rooftop v2 dressing (stair head, mafraj, tanks in the `T` corners; workshop off the bridge tiles) via agy.
   Model: Sonnet. Effort: medium.
3. Architecture fixes via agy (audit top 5). Model: Opus. Effort: medium.
4. Abu Nabil mini-boss: Game Designer spec (confuse status, herb heals, stall locked until beaten), agy.
   Model: Opus. Effort: medium.
5. Zayd kit, then hilt stones via agy. Model: Opus. Effort: medium.
6. Balance (WIP branch), bench + hook motif, then Phase 3 + Checkpoint 2. Model: Sonnet. Effort: medium.

## Paste-ready prompt
```
Continue the game repo (ferasalm/game), v0.3. Read HANDOFF.md. Do Next step 0 only: merge the save-slots agy run,
put the Rodin models from inbox/models/ in game (slim, ModelDef swap, render), cut Zayd's baked dagger, the Rodin
hilt as his hilt part, the drone mesh; check.sh, /handoff.
```
