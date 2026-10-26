# HANDOFF (current state only; one section per track, each edited only by its owner; max 60 lines)
Last updated: 2026-10-26 (overnight: Neon Glitch first playable foundation + 3 builders), Opus 5.5 (`claude-opus-5-5`); 3D tracks paused.

## Shared
- Builders: CLAUDE.md + EFFICIENCY 3b (5 runs: 2 agy, 2 DeepSeek, 1 Inkling); check `bash tools/slots.sh`.
  Balance: start gear 82.7-89% wins; arc_arm needs an upside.
- Waiting on the owner: icon art (5 heads, 4 items; letter discs stand in); play the Abu Nabil fight.
### Next steps (one per chat; reviews Sonnet, design and art judgment Opus)
1. Balance pass 2: arc_arm identity, every encounter, workshop upgrades inside 65-90%. Model: Sonnet. Effort: medium.
- Route B look pass and action combat in an arena: PAUSED 2026-10-24 by the 2D redesign.

## Track: 2D redesign (owner: the chat "2D redesign brainstorm", 2026-10-24)
- DECISIONS 2026-10-24: 2D isometric ink-comic look per Feras's concepts, offline-rendered sprites, on-map
  turn-based battles (Chrono Trigger style), qamariya at the heart. Last 3D state: tag `3d-archive`.
- Waiting on the owner: more concept pictures (plus an empty plate per scene: no characters, HUD or rain).
1. Then: design doc + plan the one-scene prototype (rooftop, Zayd, one fight, HUD). Model: Opus. Effort: high.

## Track: Neon Glitch (owner: the overnight chat "Neon Glitch first playable", 2026-10-26)
- Spec docs/design/first-playable.md; branch neon/first-playable (pushed). Done: prison-roof plate (Flow edit of his
  rooftop), Rydan Rodin model from his sheet (A-pose via Flow), tools/bake_sprites.tscn + tools/art/sprite_sheet.py
  (8-dir ink sprites: rydan, guard), start clips as .ogv, portraits (rydan_*, bilqis_ng_*), features/neon foundation.
- Builders running from the old chat (check ../game-wt/<task>.result): neon-roof (agy), neon-start (agy),
  neon-battle (cf). agy works again (ping 10-26); slots.sh still caps agy at 0: use CAP_AGY=2, fix after the runs.
- Waiting on Feras: "similar to Hades" = real-time combat now? (built turn-based on the map); Claude defaults in
  rydan.twee (prosthetic kept, Zayd call-in later, Roya watch-only); the bible's 5 open questions.
1. Review/merge the 3 builds; Flow frames + brief for the Roya cold open; glue features/neon/neon_game.tscn
   (start -> cold open -> roof -> map battle -> exit card) as main scene; render-check; /handoff. Opus, high.
`Continue ferasalm/game on neon/first-playable. Read HANDOFF.md (Neon Glitch), docs/design/first-playable.md. Do its next step; /handoff.`
## Track: Level 1 + playtest fixes: PAUSED 2026-10-24 (3D; 2D redesign). Unmerged fix branches kept in ../game-wt.
- Playtest 2026-10-24: inbox/playtest_*.png, concept_*.png; crossing freeze fixed. docs/briefs/: render-clean,
  menus-equip-fix, holo-map-real (+ their fix passes), then cyber-look, items-menu, gear-slots (save: line review).
1. Review + merge the fix passes, then Feras playtests; items-menu, gear-slots next. Model: Opus. Effort: medium.
2. Environment overhaul (DECISIONS 10-24) via /architecting-games after his test. Model: Opus. Effort: high.
`Continue ferasalm/game on main. Read HANDOFF.md (Level 1 + playtest fixes). Do its next step; /handoff.`

## Track: RPG + menus (owner: the next chat from this prompt)
- On main: rolls + flee, progression (XP, classes, armor, stones, save v5; no static state), Zayd's kit, menu skins +
  backdrops, equipment and workshop menus, balance-gear, holo map (area plan, markers, city view). 758 tests.
- Holo map is flat 2D; mock_map.png is an isometric 3D table. Renders predate the five roofs.
- Waiting on the owner: judge the menu renders (inbox/menu_*.png) against your mockups.
1. Polish briefs: workshop vs mock_workshop.png; equipment inventory/header overlap. Model: Sonnet. Effort: medium.
   The 3D holo-map table is PAUSED 2026-10-24 (2D redesign); the menus may be reskinned for the new look later.
`Continue ferasalm/game on main. Read HANDOFF.md (RPG + menus). Do its next step; /handoff.`

## Track: Puzzles (owner: none)
- Done on main: features/puzzles/ logic, grey-box scene, R5 placement (puzzle-place, 2026-10-23).

## Track: Efficiency (owner: the next manager chat)
- On main: per-track HANDOFF, milestone-only reports, gate checklists, tools/slots.sh, DeepSeek spend log
  (../game-wt/cf_spend.csv), check.sh capped at 2 test suites machine-wide (tools/check_slot.sh).
1. Keep the tracks in sync, retire finished sessions, hunt further savings. Model: Opus. Effort: medium.
`Continue ferasalm/game on main as manager. Read HANDOFF.md (all tracks). Sync sessions; /handoff.`
