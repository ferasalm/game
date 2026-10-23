# HANDOFF (current state only; rewritten by /handoff; max 60 lines)
Last updated: 2026-10-23, session 13 (Opus 5.5, `claude-opus-5-5`): demo push, M1. Plans in docs/design/:
demo-plan, level-1 (five roofs), valve-puzzles; older: characters-3d, identity, music.

## Status
- Branch claude/night-sanaa, merged to main (3df9306). 640 tests, all checks pass.
- Look: route B (repainted textures on live 3D; inbox/painted_routes.png). Route A's filter is only a frame-tool
  option (rooftop_shot.gd `route=a`).
- Camera-v2 merged and reviewed: follow camera with no player control, no tilt-shift blur, Brothers framing; framed
  corner shots indoors (owner approved). Side angle (32 deg) and zone roll: in the level1-blockout brief, not built.
- Workbench prop merged; it moves into the tayramana's corner (brief item 0). Remove superseded WIP worktree
  agent-a4cf40c0e9518e744.
- Level 1 redesigned to the owner's brief (five roofs, five crossings, rain, concept art in chat); the first
  blockout run (old two-terrace layout) was stopped unbuilt; its brief is rewritten for five roofs.
- opencode CLI installed (tools/oc_task.sh, oc_review.sh); free models hit their usage limit: wait for the reset.
- skin-bake merged: painted skins in assets/textures/painted/skin/ (not wired into models.json yet).
- Abu Nabil fight merged (session 14): confused status, pot swing, spice cloud, feather snack, qishr cure; hp 1200
  atk 45 agi 60 resist 0.7 (harness 99.5% wins, 69 s, party ends 86% HP); haggle talk with choices, x10 prices,
  fight start, after-win menu, risk-free spar. Not play-checked yet. agy hard-coded herb_seller / abu_nabil_duel
  ids (talk_picker, prototype_battle_flow): move to content later. agy briefs name the .agents/skills (owner).
- Max 3 agy runs at once.

## Waiting on the owner
- Play the Abu Nabil fight: walk to the herb stall at the right end of the roof (x 5, z 13.6), press interact; pick
  B (insult) for him to open, C for you to open; win; talk again for the menu; Spar there. Judge the difficulty.
- A Google Flow concept of the five roofs (prompt given in chat 2026-10-23), saved to inbox/.
- Play the new camera once the blockout is in (M1 gate).

## Next steps (one per chat)
1. Wire the painted skins (assets/textures/painted/skin/) into content/art/models.json; launch level1-blockout
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
