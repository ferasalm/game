# HANDOFF (current state only; one section per track, each edited only by its owner; max 60 lines)
Last updated: 2026-10-23, session 16 manager (Opus 5.5, `claude-opus-5-5`): per-track HANDOFF.

## Shared
- Builders: CLAUDE.md + EFFICIENCY 3b (5 runs: 2 agy, 2 DeepSeek, 1 Inkling); check `bash tools/slots.sh` (until it
  lands: count RUNNING lines in ../game-wt/*.result). Balance: start gear 82.7-89% wins; arc_arm needs an upside.
- Waiting on the owner: icon art (5 heads, 4 items; letter discs stand in); play the Abu Nabil fight.
### Next steps (one per chat; reviews Sonnet, design and art judgment Opus)
1. Balance pass 2: arc_arm identity, every encounter, workshop upgrades inside 65-90%. Model: Sonnet. Effort: medium.
2. Route B look pass (character light vs inbox/route_b.png). Model: Opus. Effort: high.
3. Action combat overhaul after the demo. Model: Opus. Effort: high.

## Track: Level 1 (owner: session local_db06935a)
- Five-roof blockout merged to main (5a6c947, 740 tests): storm on, R4/R5 fog fixed, R5 valve spot. RUNNING:
  tayramana, souq-place (props, sabil on R2, crates), camera-wall. Queued: interact-focus, level1-polish.
- Waiting on the owner: judge the five roofs and souq props; play the camera.
1. Review + merge the running builds; interact-focus; puzzle placement on R5. Model: Opus. Effort: high.
`Continue ferasalm/game on main. Read HANDOFF.md (Level 1). Do its next step as manager; /handoff.`

## Track: RPG + menus (owner: session local_c29a3aa9)
- On main: rolls + flee, progression (XP, classes, armor, stones, save v5; no static state), Zayd's kit, menu skins +
  backdrops, equipment and workshop menus, balance-gear, holo map (area plan, markers, city view). 758 tests.
- Holo map is flat 2D; the mockup (inbox/ui_refs/mock_map.png) is an isometric 3D table. Renders predate the five roofs.
- Waiting on the owner: judge the menu renders (inbox/menu_*.png) against your mockups; icon art (5 heads, 4 items).
1. Polish briefs: workshop vs mock_workshop.png; holo map as an isometric table on the five roofs; equipment
   inventory/header overlap. Then interact-focus (brief ready). Model: Sonnet. Effort: medium.
`Continue ferasalm/game on main. Read HANDOFF.md (RPG + menus). Do its next step; /handoff.`

## Track: Puzzles (owner: session local_8f9c02cf)
- On main: puzzle logic (light lock, water network, hints). RUNNING: puzzle-scene (DeepSeek).
1. Review puzzle-scene (renders vs valve-puzzles.md), merge, renders to Feras. Model: Opus. Effort: high.
`Continue ferasalm/game on main. Read HANDOFF.md (Puzzles). Do its next step; /handoff.`

## Track: Efficiency (owner: session 16 manager)
- On branch claude/efficiency-docs -> main: per-track HANDOFF, milestone-only reports. RUNNING: efficiency-tools
  (agy: checklist gate, tools/slots.sh, DeepSeek spend log).
1. Review + merge efficiency-tools. Model: Sonnet. Effort: medium.
`Continue ferasalm/game on main. Read HANDOFF.md (Efficiency). Do its next step; /handoff.`
