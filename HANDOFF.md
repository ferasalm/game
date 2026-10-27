# HANDOFF (current state only; one section per track, each edited only by its owner; max 60 lines)
Last updated: 2026-10-27 (process audit plan approved: D1-D22; Efficiency track), Opus 5.5 (`claude-opus-5-5`).

## Shared
- Builders: DECISIONS 10-27 (D1): <= 2 Godot runs (agy, DeepSeek) + 1 free text run; slots.sh enforces it after P1.
  Balance: start gear 82.7-89% wins; arc_arm needs an upside.
- Waiting on the owner: icon art (5 heads, 4 items; letter discs stand in); play the Abu Nabil fight.
### Next steps (one per chat; reviews Sonnet, design and art judgment Opus)
1. Process audit P1-P4 first (Efficiency track), then M1 (VISION); balance pass 2 dropped (D15). Model: Sonnet. Effort: medium.
- Route B look pass and action combat in an arena: PAUSED 2026-10-24 by the 2D redesign.

## Track: 2D redesign (owner: the chat "2D redesign brainstorm", 2026-10-24)
- DECISIONS 2026-10-24: 2D isometric ink-comic look per Feras's concepts, offline-rendered sprites, on-map
  turn-based battles (Chrono Trigger style), qamariya at the heart. Last 3D state: tag `3d-archive`.
- Waiting on the owner: more concept pictures (plus an empty plate per scene: no characters, HUD or rain).
1. Then: design doc + plan the one-scene prototype (rooftop, Zayd, one fight, HUD). Model: Opus. Effort: high.

## Track: Neon Glitch (owner: the chat "Retire 3D", 2026-10-26)
- On main: launching = features/neon/neon_game.tscn: start flow -> Roya cold open -> prison roof -> turn-based map
  fight (prison_guard x2, 84 % wins at XP 0) -> cable line -> "TO BE CONTINUED". Renders: tools/shot_neon_game.tscn.
- 3D game retired 10-26 (docs/design/retire-3d-audit.md): branch archive/3d + tag 3d-archive; what to reuse:
  docs/archive/3d-reuse.md. Dialogue fights emit EventBus.battle_requested (no host yet); menu holograms show
  portraits or Neon sprites; the Map tab is greyed (no 2D map yet).
- Feras: play it (Esc/back, Enter/Space, WASD, E). Gaps: Normal/Hard not applied; guards close in formation;
  title twice; floodlight numbers in code; no call-in ally; code id "zayd" = Rydan.
Next, after the 5-hour reset, in this order (Feras 10-26):
1. Vision, mission, objectives + roadmap (docs/VISION.md from bible + DECISIONS; Feras edits). Model: Opus. Effort: high.
2. Builder quality system: gate rejects removed checks and asset edits, tests/assets Do NOT edit by default, layer
   lint (shared code never names a mode), builder playbook in TEMPLATE. Model: Sonnet. Effort: medium.
3. Names to the bible (code id zayd -> rydan, save migration, assets, keys); DeepSeek builds. Model: Opus. Effort: medium.
4. Asset preparation pipeline (jpg -> png, sizes, import settings, manifest check); DeepSeek builds. Model: Sonnet. Effort: medium.
`Continue ferasalm/game on main. Read HANDOFF.md (Neon Glitch). Do its next step; /handoff.`
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

## Track: Efficiency (owner: the process-audit chats P1-P4, 2026-10-27)
- Plan: docs/audits/2026-10-27-process-audit-plan.md (D1-D22 logged), checklist 2026-10-27-plan-checklist.md;
  sequential before game work (D12). Neon Glitch steps 1-2 are folded into P0 and P1-P2. Each P-chat ticks its lines.
1. P1 tool fixes: baseline, builders.conf, slots, pipeline, gate, hook (DeepSeek builds, tests first). Model: Sonnet. Effort: medium.
`Continue ferasalm/game on main. Read HANDOFF.md (Efficiency) and the plan's P1. Do P1, tick the checklist, put P2's prompt here; /handoff.`
