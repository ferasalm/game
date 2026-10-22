# HANDOFF (current state only; rewritten by /handoff; max 60 lines)
Last updated: 2026-10-23, session 13 (Opus 5.5, `claude-opus-5-5`): demo push, M1. Plans in docs/design/:
demo-plan, level-1 (five roofs), valve-puzzles; older: characters-3d, identity, music.

## Status
- Branch claude/night-sanaa, merged to main. 622 tests, all checks pass.
- Look: route B (repainted textures on live 3D; inbox/painted_routes.png). Route A's filter is only a frame-tool
  option (rooftop_shot.gd `route=a`).
- Camera-v2 merged and reviewed: follow camera with no player control, no tilt-shift blur, Brothers framing; framed
  corner shots indoors (owner approved). Side angle (32 deg) and zone roll: in the level1-blockout brief, not built.
- Workbench prop merged (screen glows too pale); it moves into the tayramana's corner (tayramana brief item 0).
  WIP worktree agent-a4cf40c0e9518e744 is superseded: remove it.
- Level 1 redesigned to the owner's brief (five roofs, five crossings, rain, concept art in chat); the first
  blockout run (old two-terrace layout) was stopped unbuilt; its brief is rewritten for five roofs.
- opencode CLI 1.19.4 installed (own data folder), tools/oc_task.sh + oc_review.sh, AGENTS.md, opencode.json. Free
  models said "Free usage limit reached"; owner: wait for the reset ($0). No completed opencode run yet.
- agy running: skin-bake (route B skins, Python). The Abu Nabil session (local_fcbcec7e...) runs agy
  abu-nabil-world and owns features/combat, dialogue, items, economy, prototype until it merges. Max 3 runs total.

## Waiting on the owner
- A Google Flow concept of the five roofs (prompt given in chat 2026-10-23), saved to inbox/.
- Play the new camera once the blockout is in (M1 gate).

## Next steps (one per chat)
1. Review and merge skin-bake; wire the painted skins into content/art/models.json; launch level1-blockout
   (docs/briefs/level1-blockout.md); review it with renders for Feras; then crossings, tayramana (after the Abu
   Nabil merge), storm, valve-puzzles briefs (level-1.md 8). Retry opencode with a tiny prompt first.
   Model: Opus. Effort: high.
2. Route B look pass: softer, flatter character light, judged against inbox/route_b.png. Model: Opus. Effort: high.
3. Action combat overhaul after the demo. Model: Opus. Effort: high.
4. Architecture fixes (audit top 5) and balance (worktree agent-a7a39e37292830460). Model: Sonnet. Effort: medium.

## Paste-ready prompt
```
Continue the game repo (ferasalm/game). Read HANDOFF.md. Do Next step 1 as manager of cheap builders; play back
to Feras and ask before each new step; check.sh, /handoff.
```
