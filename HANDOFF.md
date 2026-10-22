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
- Inbox: Abu Nabil 3/4 portrait (green) and Flow model pictures for image-to-3D (characters-3d.md 8).

## How work runs now
agy builds (DECISIONS 2026-10-22): brief in docs/briefs/<task>.md, then in the background
`bash tools/agy_task.sh <task> docs/briefs/<task>.md claude/night-sanaa`; review, check.sh there, merge.

## Next steps (one per chat)
1. Zayd kit via agy (zayd-moves.md + hilt-stones.md PerkDef kinds). Model: Opus lead briefs and reviews,
   Gemini 3.8 Flash high builds. Effort: medium.
2. Hilt stones via agy (hilt-stones.md), on top of the kit. Model: Opus lead. Effort: medium.
3. Balance pass on the new kit: agy, based on the WIP balance branch. Model: Sonnet lead. Effort: medium.
4. Workshop bench (its WIP branch) and hook motif shader (identity.md): agy builds, Claude judges renders; owner
   picks the logo's Musnad letter. Model: Sonnet. Effort: medium.
5. Phase 3: title menu, frame_speaker, smoke play-through, fps_probe via agy; Code Reviewer (Opus, high); merge;
   Checkpoint 2: Feras plays v0.3. Model: Opus lead. Effort: high.

## Paste-ready prompt
```
Continue the game repo (ferasalm/game), v0.3. Read HANDOFF.md. Do Next step 1 only: write an exact brief for the
Zayd kit (docs/design/zayd-moves.md + hilt-stones.md PerkDef kinds) to docs/briefs/zayd-kit.md, run it with
tools/agy_task.sh in the background, then review the diff, run tools/check.sh in its worktree, merge, /handoff.
Gemini builds; Claude only briefs and reviews. Opus lead, medium effort.
```
