# HANDOFF (current state only; one section per track, each edited only by its owner; max 60 lines)
Last updated: 2026-10-26 (story bible merged, Twine map outlined), story chat (Opus 5.5, `claude-opus-5-5`); 3D tracks paused.

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

## Track: Neon Glitch (owner: the chat "Neon Glitch brainstorm", 2026-10-25)
- Plan: docs/design/neon-glitch-plan.md. Story: Feras's bible docs/story/bible.md (2026-10-26) -> Twine map
  rydan.twee (38 passages: ch0 Roya cold open, ch1 prison escape -> "Earlier" Zayd -> demo end, ch2-3 Numan, Bilal,
  Kanan; later arcs). Decided 10-26: first fight on the prison roof, three hilts (1/2/3), no year (DECISIONS).
- Code still has the old hilt model (grandfather_hilt start, stones) and "zayd" = Rydan: brief a change later.
- Waiting on Feras: red "check" passages (Rydan's prosthetic arm, Zayd as first call-in), slot contents
  (gems with a tech reason vs modules), Roya cold open playable or not, the bible's 5 open questions (Twine).
1. Pull his Twine edits; settle checks; then brief the first build (start flow + Roya cold open + prison-roof
   fight) with the 2D track. Model: Opus. Effort: high.
`Continue ferasalm/game on main. Read HANDOFF.md (Neon Glitch), docs/story/README.md. Pull the story; settle the checks; brief the first build; /handoff.`
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
