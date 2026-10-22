# HANDOFF (current state only; rewritten by /handoff; max 60 lines)
Last updated: 2026-10-22, session 8 (Opus 5.5, `claude-opus-5-5`, lead alone, medium): v0.3 "Painted Rooftops", Phase 2.
Specs in docs/design/: v03-plan, characters-3d, identity (hook), zayd-moves, hilt-stones.

## Status
- Merged to main: everything from session 7 plus B4 (live 3D characters: ModelSource, rig, parts, painted skin,
  trail + smear, ClipTiming, Locomotion, YawTurn, hit-stop, facing; garments tuned from renders). 547 tests.
- Not seen by the owner yet: the 3D cast in game (render: inbox/b4_cast_idle_attack.png, idle over attack).
- Still WIP, not merged, worktree branches:
  - Workshop bench prop: worktree-agent-a4cf40c0e9518e744 (1 WIP commit; renders not made).
  - Balance pass: worktree-agent-a7a39e37292830460 (1 WIP commit; was waiting on a harness run).
  - Zayd kit and stones: nothing built yet.
- Polish: Musnad line by "Paused", small "Target:", big target cone, loud `defeat` sound.
- Inbox: Abu Nabil 3/4 portrait (green).

## How work runs now
agy builds (DECISIONS 2026-10-22): brief in docs/briefs/<task>.md, then in the background
`bash tools/agy_task.sh <task> docs/briefs/<task>.md claude/night-sanaa`; review, check.sh there, merge.

## Next steps (one per chat)
0. Zayd's own model (characters-3d.md 8): Feras puts TRELLIS.2's inbox/models/zayd.glb; Claude imports, cuts to
   budget, repaints, rigs onto the 65-bone skeleton, swaps the ModelDef scene, renders. Blender, auto-rig: ask
   first. Then Bilqis, Abu Nabil, hilt (grey JPGs in inbox). Model: Opus lead. Effort: high.
1. Zayd kit via agy (zayd-moves.md + hilt-stones.md PerkDef kinds). Model: Opus briefs, reviews. Effort: medium.
2. Hilt stones via agy (hilt-stones.md), on top of the kit. Model: Opus lead. Effort: medium.
3. Balance pass on the new kit: agy, on the WIP balance branch. Model: Sonnet. Effort: medium.
4. Bench (WIP branch) and hook motif shader (identity.md) via agy; Claude judges renders; owner picks the logo
   letter. Model: Sonnet. Effort: medium.
5. Phase 3 via agy (title menu, frame_speaker, smoke run, fps_probe); Code Reviewer (Opus, high); Checkpoint 2:
   Feras plays v0.3. Model: Opus lead. Effort: high.

## Paste-ready prompt
```
Continue the game repo (ferasalm/game), v0.3. Read HANDOFF.md. Do Next step 0 only: import Zayd's TRELLIS.2
model from inbox/models/zayd.glb per docs/design/characters-3d.md 8, judge renders, merge, check.sh, /handoff.
```
