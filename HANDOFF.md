# HANDOFF (current state only; rewritten by /handoff; max 60 lines)
Last updated: 2026-10-23, session 16 manager (Opus 5.5, `claude-opus-5-5`): branches joined, builder rules updated.
Two tracks: level 1 (claude/night-sanaa = old main) and RPG + menus + puzzles (claude/menus-rpg-5089fa -> main).

## Status
- claude/menus-rpg-5089fa now holds the RPG + menus track AND claude/puzzles-streamline-f7ef2d (merged), and is
  merged into main when check.sh passes. Built: rolls + flee, progression (XP, levels, classes, armor, stones, save
  v5), Zayd's kit + damage split, menu skins + Feras's 7 backdrops, equipment menu (3D hologram), workshop menu
  (upgrade, gemstones, crafting), equipment polish, balance-gear, puzzle logic (light lock, water network, hints),
  the build gate (tools/build_gate.py, merge_run.sh), opencode skill subagents (tools/oc_agents.py).
- Builders (DECISIONS 2026-10-23): up to 5 runs at once across all sessions: 2 agy, 2 Cloudflare DeepSeek
  (tools/cf_build.sh; <= $10 over the free neurons), 1 Inkling :free. Every brief names a skill. Count game-wt/* first.
- RUNNING: holo-map (agy, game-wt/holo-map, rpg-menus session), puzzle-scene (DeepSeek, game-wt/puzzle-scene,
  puzzles session). Waiting for review: progression-pure (PASS, game-wt/progression-pure).
- Level-1 track: gemini/level1-blockout-fix and souq-props-2 still unreviewed (worktrees in game-wt); holo-map's
  five-roof view, interact-focus and the puzzle placement wait for that merge.
- Balance: start gear 82.7-89% wins; arc_arm needs a real upside; other encounters not re-run.
- No icon art yet (assets/icons/ missing): letter discs stand in.

## Waiting on the owner
- Judge the menu renders (inbox/menu_*.png) against your mockups; make the icon art (5 heads, 4 items).
- Play the Abu Nabil fight; judge the five roofs and souq props when merged; play the camera.

## Next steps (one per chat; reviews on Sonnet, design and art judgment on Opus)
1. Level 1: review + merge level1-blockout-fix and souq-props-2 into main; storm on the new area; camera wall test;
   then interact-focus and the puzzle placement. Model: Opus. Effort: high.
2. Puzzles: review puzzle-scene (renders vs valve-puzzles.md), merge, renders to Feras. Model: Opus. Effort: high.
3. Menus: review progression-pure and holo-map, workshop polish brief vs inbox/ui_refs/mock_workshop.png.
   Model: Sonnet. Effort: medium.
4. Balance pass 2: arc_arm identity, every encounter, workshop upgrades inside 65-90%. Model: Sonnet. Effort: medium.
5. Route B look pass (character light vs inbox/route_b.png). Model: Opus. Effort: high.
6. Action combat overhaul after the demo. Model: Opus. Effort: high.

## Paste-ready prompt
```
Continue the game repo (ferasalm/game) on main. Read HANDOFF.md. Do Next step 1 as manager: briefs to the
builders (5 slots: 2 agy, 2 DeepSeek, 1 Inkling), gate, review, merge; check.sh; renders to Feras; /handoff.
```
