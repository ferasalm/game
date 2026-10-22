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
  - Zayd kit and stones: nothing built; build from the design docs.
- Polish: small Musnad line by "Paused", small "Target:" text, big target cone, loud `defeat` sound.
- Inbox: Abu Nabil 3/4 portrait (green) and Flow model pictures for image-to-3D (characters-3d.md 8).

## How work runs now (DECISIONS 2026-10-22)
Gemini (agy) builds whatever can be briefed exactly: Claude writes docs/briefs/<task>.md, runs
`bash tools/agy_task.sh <task> docs/briefs/<task>.md claude/night-sanaa` in the background (worktree
../game-wt/<task>, branch gemini/<task>), then reviews the diff, runs check.sh there and merges. Claude agents only
for art-judgment loops or Opus review; at most 2 at once. Before resuming any WIP worktree: check.sh there + grep
its spec first; finish small remainders as the lead.

## Next steps (one per chat)
1. Zayd kit via agy: Claude briefs from zayd-moves.md + hilt-stones.md PerkDef kinds (exact APIs, files, tests),
   agy builds, Claude reviews and merges. Model: Opus lead (brief + review), Gemini 3.8 Flash high builds.
   Effort: medium.
2. Hilt stones via agy (hilt-stones.md), same flow, on top of the kit. Model: Opus lead, Gemini builds. Effort: medium.
3. Balance pass on the new kit: brief agy from the WIP worktree's notes (base it on that branch). Model: Sonnet
   lead is enough. Effort: medium.
4. Workshop bench (agy builds from its WIP branch; Claude judges renders) and hook motif shader (identity.md; agy
   builds, Claude judges renders). Owner picks the logo's Musnad letter from renders. Model: Sonnet. Effort: medium.
5. Phase 3: title menu, frame_speaker wiring, smoke play-through, fps_probe (look B to 90) via agy; Code Reviewer
   (Opus, high) on all of v0.3; merge; Checkpoint 2: Feras plays v0.3. Model: Opus lead. Effort: high.

## Paste-ready prompt
```
Continue the game repo (ferasalm/game), v0.3. Read HANDOFF.md. Do Next step 1 only: write an exact brief for the
Zayd kit (docs/design/zayd-moves.md + hilt-stones.md PerkDef kinds) to docs/briefs/zayd-kit.md, run it with
tools/agy_task.sh in the background, then review the diff, run tools/check.sh in its worktree, merge, /handoff.
Gemini builds; Claude only briefs and reviews. Opus lead, medium effort.
```
