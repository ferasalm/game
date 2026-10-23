# HANDOFF (current state only; rewritten by /handoff; max 60 lines)
Last updated: 2026-10-23, session 15 (Opus 5.5, `claude-opus-5-5`): demo push, M1. Plans in docs/design/:
demo-plan, level-1 (five roofs), valve-puzzles. Owner concepts: inbox/level1_concept_roofs.png, level1_concept_sabil.png.

## Status
- Branch claude/night-sanaa, merged to main at the end of session 15. 649 tests, all checks pass.
- Done this session: painted skins wired (models.json; ModelMaterials.load_texture reads the .gdignore'd webp);
  playtest fixes: stuck save picker after an overwrite, Abu Nabil's painted portrait (owner art; missing expressions
  use the neutral), portraits stand on the screen's bottom edge; storm merged and tuned (rain visible, lightning
  screen wash; 87 vs 89 FPS on the laptop), still on the OLD rooftop area until the blockout merges.
- Builders: agy + opencode on openrouter/thinkingmachines/inkling:free (owner, after a free-model test; GLM and
  DeepSeek share opencode's free allowance, which ran out; laguna via the OpenRouter MCP for quick questions).
  OpenRouter :free slugs ONLY (the account holds paid credit). Owner logged in the CLI (oc-cli data folder).
- RUNNING agy (started in session 15; check `git -C C:/dev/game-wt/<task> log`, logs C:/dev/game-wt/<task>.log):
  - level1-blockout-fix (base gemini/level1-blockout): the blockout failed 14 tests (unfinished R5 bake, old-area
    test coordinates, walk-graph tests unaware of crossings, two corridors < 2 m) and its old mist drowned R4/R5.
  - souq-props-2 (base gemini/souq-props): first pass = right sabil structure, wrong materials; herbs still cones.
    Second pass gives geometry recipes (blade bundles, leaf heaps, sloped striped awning, pointed niche).
- Review each with tools/agy_review.sh + its renders (inbox/level1_*.png, prop_*.png, prop_*_play.png); run
  check.sh in the worktree yourself (agy reported "done" with failures before). Merge order: blockout-fix (it carries
  the blockout), then souq-props-2 (carries souq-props). Then remove the four game-wt worktrees.
- After the blockout merge: set "weather": "storm" on souq_rooftops_v4; place the new sabil against a wall on R2 with
  the Musnad sign on that wall (no floating signs); keep crates clear of Abu Nabil; then launch the tayramana brief
  (unblocked: Abu Nabil part B is merged; it needs the blockout's R3 door).
- Owner camera rule (DECISIONS): blocked by a wall, the camera rises toward isometric, never closes in on faces.
  Test it on the five roofs with the 32-degree side angle; fix if it persists.
- Session notes: side-session-notes/local_60fae4fe.../level1-session-notes.md (concept reading of the roofs).
- Session 16: RPG + menus on claude/menus-rpg-5089fa (docs, unmerged); Feras approved rpg-systems.md, rpg-menus.md,
  zayd-moves.md 7. RUNNING opencode oc/rpg-rolls-flee (game-wt). Briefs: zayd-kit, rpg-progression (after it).

## Waiting on the owner
- Play the Abu Nabil fight (session 14 notes): stall at the market roof, pick B or C, win, talk again, Spar.
- Paint 7 menu backdrops (Gemini prompts: docs/design/rpg-menus.md 7) -> inbox/ui_bg_<id>.png.
- Judge the renders of the five roofs and the souq props when they are merged; play the new camera (M1 gate).

## Next steps (one per chat)
1. Review and merge level1-blockout-fix and souq-props-2 (above); renders to Feras next to his concepts; storm on
   the new area; camera wall test; then launch tayramana, crossings (set moves), valve-puzzles (level-1.md 8).
   Model: Opus. Effort: high.
1b. RPG + menus: merge rpg-rolls-flee, run zayd-kit + rpg-progression, brief the menus. Model: Opus. Effort: high.
2. Route B look pass: softer, flatter character light, judged against inbox/route_b.png. Model: Opus. Effort: high.
3. Retest DeepSeek V4.1 Flash and GLM-5.3-Flash on the saved model test when opencode's free allowance resets
   (docs/research/model-test/README.md; ~10 min). Model: Sonnet. Effort: medium.
4. Action combat overhaul after the demo. Model: Opus. Effort: high.
5. Architecture fixes (audit top 5) and balance (worktree agent-a7a39e37292830460). Model: Sonnet. Effort: medium.

## Paste-ready prompt
```
Continue the game repo (ferasalm/game). Read HANDOFF.md. Do Next step 1 as manager of cheap builders (agy runs
level1-blockout-fix and souq-props-2 may still be running or done); play back to Feras and ask before each new
step; check.sh, /handoff.
```
