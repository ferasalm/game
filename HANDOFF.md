# HANDOFF (current state only; one section per track, each edited only by its owner; max 60 lines)
Last updated: 2026-10-27 (Efficiency: P3 rest + P4 done; art chat next), Opus 5.5 (`claude-opus-5-5`).

## Shared
- Builders (D1): <= 2 Godot runs + 1 free text run (slots.sh). Briefs: docs/briefs/TEMPLATE.md (D6 defaults, May edit,
  Ripple from docs/design/systems-map.md, a player-visible test). Balance band: start gear 82.7-89% wins; arc_arm needs an upside.
- Waiting on the owner: OK on docs/VISION.md (P0.1); connectors to switch off and the pre_spend question
  (docs/audits/2026-10-27-process-audit.md); icon art; play the Abu Nabil fight.
### Next steps (one per chat; reviews Sonnet, design and art judgment Opus)
1. Game work from VISION: Efficiency next step 1 (art chat). Model: Opus. Effort: high. Balance pass 2 dropped (D15).

## Track: 2D redesign (owner: the chat "2D redesign brainstorm", 2026-10-24)
- DECISIONS 2026-10-24: 2D isometric ink-comic look per Feras's concepts, offline-rendered sprites, on-map
  turn-based battles (Chrono Trigger style), qamariya at the heart. Last 3D state: tag `3d-archive`.
- Waiting on the owner: more concept pictures (plus an empty plate per scene: no characters, HUD or rain).
1. Then: design doc + plan the one-scene prototype (rooftop, Zayd, one fight, HUD). Model: Opus. Effort: high.

## Track: Neon Glitch (owner: the chat "Retire 3D", 2026-10-26)
- On main: launching = features/neon/neon_game.tscn: start flow -> Roya cold open -> prison roof -> turn-based map
  fight (prison_guard x2, 84 % wins at XP 0) -> cable line -> "TO BE CONTINUED". Renders: tools/shot_neon_game.tscn.
- 3D game retired 10-26 (docs/archive/design-3d/retire-3d-audit.md): branch archive/3d + tag 3d-archive; what to reuse:
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
2. Environment overhaul (DECISIONS 10-24) via the builders skill after his test. Model: Opus. Effort: high.
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
- Done 10-27: P1-P4; summary docs/audits/2026-10-27-process-audit.md; ops-review after 5 sessions measures the gains.
  Open: P0.1 (Feras's VISION OK); skillOverrides name-only does not take effect (ops-review).
Next (game work from VISION), in this order (the art clock first: credits end ~2026-11-17):
1. Art chat: spend the ~50 Hyper3D credits (cast, recurring props, icons, title video; name each job's credit cost first)
   and prove the free 3D route on one character (3d-model skill). Model: Opus. Effort: high.
2. M1 look-and-feel spike, prison roof (VISION M1): real-time Rydan vs 2 guards, lights with normal maps, touch.
   Model: Opus (plan + briefs), builders build. Effort: high.
`Continue ferasalm/game on main. Read HANDOFF.md (Efficiency). Do its next step 1; /handoff.`
