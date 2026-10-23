# HANDOFF (current state only; one section per track, each edited only by its owner; max 60 lines)
Last updated: 2026-10-23, session 16 manager (Opus 5.5, `claude-opus-5-5`): per-track HANDOFF.

## Shared
- Builders: CLAUDE.md + EFFICIENCY 3b (5 runs: 2 agy, 2 DeepSeek, 1 Inkling); check `bash tools/slots.sh`.
  Balance: start gear 82.7-89% wins; arc_arm needs an upside.
- Waiting on the owner: icon art (5 heads, 4 items; letter discs stand in); play the Abu Nabil fight.
### Next steps (one per chat; reviews Sonnet, design and art judgment Opus)
1. Balance pass 2: arc_arm identity, every encounter, workshop upgrades inside 65-90%. Model: Sonnet. Effort: medium.
2. Route B look pass (character light vs inbox/route_b.png). Model: Opus. Effort: high.
3. Action combat overhaul after the demo. Model: Opus. Effort: high.

## Track: Level 1 (owner: the next chat from this prompt)
- Milestone on main: five roofs, camera-wall, tayramana, souq props, R5 puzzles, interact-focus, level1-polish + fix.
- After any pull into C:/dev/game: `bash tools/sync_main.sh` (import + new-game smoke); a stale cache broke the run.
- cf DeepSeek gave NOWORK twice on 2026-10-23; reviews go to Haiku. Waiting on the owner: milestone playtest.
1. Act on the playtest notes. Model: Opus. Effort: high.
`Continue ferasalm/game on main. Read HANDOFF.md (Level 1). Do its next step as manager; /handoff.`

## Track: RPG + menus (owner: the next chat from this prompt)
- On main: rolls + flee, progression (XP, classes, armor, stones, save v5; no static state), Zayd's kit, menu skins +
  backdrops, equipment and workshop menus, balance-gear, holo map (area plan, markers, city view). 758 tests.
- Holo map is flat 2D; mock_map.png is an isometric 3D table. Renders predate the five roofs.
- Waiting on the owner: judge the menu renders (inbox/menu_*.png) against your mockups.
1. Polish briefs: workshop vs mock_workshop.png; holo map as an isometric table on the five roofs; equipment
   inventory/header overlap. Model: Sonnet. Effort: medium.
`Continue ferasalm/game on main. Read HANDOFF.md (RPG + menus). Do its next step; /handoff.`

## Track: Puzzles (owner: none)
- On main: features/puzzles/ logic + grey-box scene (puzzle_yard.tscn); renders inbox/puzzle_*.png sent.
1. R5 placement via valve_spot (level-1 briefs it; render player on m2, gauge at edge). Model: Sonnet. Effort: medium.
`Continue ferasalm/game on main. Read HANDOFF.md (Puzzles). Do its next step; /handoff.`

## Track: Efficiency (owner: the next manager chat)
- On main: per-track HANDOFF, milestone-only reports, gate checklists, tools/slots.sh, DeepSeek spend log
  (../game-wt/cf_spend.csv), check.sh capped at 2 test suites machine-wide (tools/check_slot.sh).
1. Keep the tracks in sync, retire finished sessions, hunt further savings. Model: Opus. Effort: medium.
`Continue ferasalm/game on main as manager. Read HANDOFF.md (all tracks). Sync sessions; /handoff.`
