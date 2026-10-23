# HANDOFF (current state only; rewritten by /handoff; max 60 lines)
Last updated: 2026-10-23, session 17 (Opus 5.5, `claude-opus-5-5`): RPG + menus track, autonomous overnight run.
Two tracks: level 1 (session 15, branch claude/night-sanaa) and RPG + menus (sessions 16-17, claude/menus-rpg-5089fa).

## Status
- claude/menus-rpg-5089fa (pushed, NOT merged into main or night-sanaa): 693 tests, all checks pass. Merged into it:
  rpg-rolls-flee (dodge/crit/resist rolls, flee; Claude review fixes), rpg-progression (XP, levels, classes, armor,
  hilt stones, GearState + Gear.build_hero, save v5), zayd-kit (approved kit, multi-hit damage split, AI, enemy
  retune), menu-skins (backdrops + blurred fallback; pause/save/shop in the mockup layouts), equipment-menu (3D
  hologram hero, slot boxes, stat preview; the old bench screen is gone).
- Feras's 7 backdrops are in (assets/textures/ui_bg/*.webp + manifest); his layout mockups: inbox/ui_refs/mock_*.png.
- Renders to judge: inbox/menu_pause.png, menu_save.png, menu_shop.png, menu_equipment.png (first pass: right
  layout, flat look; polish briefs below).
- RUNNING via tools/build_pipeline.sh (agy; result in C:/dev/game-wt/<task>.result; worktree game-wt/<task>):
  menu-polish (fix pass), workshop-menu (build). Review: read the .result, the non-test diff, the renders; merge into
  claude/menus-rpg-5089fa; check.sh; remove the worktree and branch.
- Queued briefs (docs/briefs/): equipment-polish (after menu-polish), holo-map and interact-focus (only after the
  level-1 session merges gemini/level1-blockout-fix; ask it first: features/world/interact/ is its area).
- Balance: start gear 82.7% wins; better gear combos 92-99% (above 65-90%): for the balance pass.
- Builders now: tools/build_pipeline.sh <oc|agy> <task> <brief> <base> from C:/dev/game, run_in_background. It pastes
  the brief's named skill into the prompt. Gap to fix when no pipeline runs: PASS with zero commits is not a pass.
- opencode is blocked until the OpenRouter free cap resets (50 :free requests/day under $10 bought credit).
- Level-1 track (session 15, unchanged here): blockout-fix and souq-props-2 agy runs ended (worktrees in game-wt);
  still to review and merge by the level-1 session (local_60fae4fe...), then storm on the new area, sabil on R2,
  tayramana, camera wall test.

## Waiting on the owner
- Judge the 4 menu renders against your mockups (and the polish renders when they land).
- OpenRouter: buy $2 of credit (one time) to lift the free cap to 1000 requests/day, or keep agy-only builds on
  days the cap runs out? (Recommended: buy; Inkling stays free per request.) Ling 3.1 Flash tied Inkling (16/16,
  right cause) for $0.016 if you ever want a paid fallback.
- Play the Abu Nabil fight (session 14 notes); judge the five roofs and souq props when merged; play the camera.

## Next steps (one per chat)
1. Review and merge menu-polish and workshop-menu, launch equipment-polish; fix the pipeline zero-commit gap;
   renders to Feras. Model: Sonnet. Effort: medium.
2. Level 1: review and merge level1-blockout-fix and souq-props-2 (level-1 session); storm on the new area; camera
   wall test; then holo-map and interact-focus from this branch. Model: Opus. Effort: high.
3. Merge claude/menus-rpg-5089fa into night-sanaa/main through the level-1 session (ask it first). Model: Sonnet.
   Effort: medium.
4. Balance pass: gear combos inside 65-90% (harness), workshop upgrades included. Model: Sonnet. Effort: medium.
5. Route B look pass (character light vs inbox/route_b.png). Model: Opus. Effort: high.
6. Action combat overhaul after the demo. Model: Opus. Effort: high.

## Paste-ready prompt
```
Continue the game repo (ferasalm/game) on branch claude/menus-rpg-5089fa. Read HANDOFF.md. Do Next step 1: read
C:/dev/game-wt/menu-polish.result and workshop-menu.result, review, merge, launch equipment-polish with
tools/build_pipeline.sh; check.sh; renders to Feras; /handoff.
```
