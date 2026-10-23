# HANDOFF (current state only; rewritten by /handoff; max 60 lines)
Last updated: 2026-10-23, session 18 (Sonnet 5.5, `claude-sonnet-5-5`): RPG + menus track, review and merge of three builds.
Two tracks: level 1 (session 15, branch claude/night-sanaa) and RPG + menus (sessions 16-18, claude/menus-rpg-5089fa).

## Status
- claude/menus-rpg-5089fa (pushed, NOT merged into main or night-sanaa): 715 tests, all checks pass. Merged into it:
  rpg-rolls-flee, rpg-progression, zayd-kit, menu-skins, equipment-menu, menu-polish (session 17), and this session:
  workshop-menu (upgrade, gemstones, crafting logic + hologram menu; the old equipment screen no longer serves
  WORKSHOP_ID), equipment-polish (cyan hologram material, grid disc, sockets, stats panel), balance-gear.
- Balance (harness, rooftop_patrol, 300 seeds): every obtainable gear row wins 82.7-89.0%, 56-64 s (target 65-90%).
  Cost: arc_arm (epic) is now sp 0 / atk 0 / agi -2 / weight 4.2: weaker on paper, needs a real upside. Other
  encounters were tuned by the builder, not re-run by me.
- Renders (inbox/): menu_{pause,save,shop,equipment,workshop_*}.png.
  Workshop is structurally right but flat vs inbox/ui_refs/mock_workshop.png: no glass panels, no item icons, no
  materials strip with icons; equipment: the inventory panel slightly overlaps the hero header.
- No icon art (assets/icons/ missing): letter discs stand in (5 heads, 4 items) until Feras makes icons.
- Queued briefs: holo-map and interact-focus (only after the level-1 session merges gemini/level1-blockout-fix; ask
  local_60fae4fe first: features/world/interact/ is its area). No builds are running now.
- Builders: tools/build_pipeline.sh <oc|agy> <task> <brief> <base> from C:/dev/game, run_in_background, stdin closed.
  opencode Inkling :free built nothing on balance-gear (rerun on agy worked). Zero commits = NOWORK.
- Cloudflare DeepSeek V4.1 Flash (decision 2026-10-23, cap $8.50): NOT set up here; it gets its own Opus session. opencode
  Feras must run the Cloudflare login himself. Spend so far: $0.
- Level-1 track (session 15): blockout-fix and souq-props-2 await review/merge by local_60fae4fe.

## Waiting on the owner
- Judge the menu renders (pause, save, shop, equipment, workshop) against your mockups; say if workshop needs the glass
  polish pass now.
- Run the Cloudflare login for opencode (see above) so the paid builder can be tested.
- Make the icon art (5 heads, 4 items). Play the Abu Nabil fight; judge the five roofs and souq props when merged.

## Next steps (one per chat)
1. Workshop polish brief (glass panels, icons fallback, materials strip) via agy, then review. Model: Sonnet. Effort: medium.
2. Cloudflare DeepSeek as an opencode builder: provider, pong test, model test, cost log. Model: Opus. Effort: medium.
3. Level 1: review and merge level1-blockout-fix and souq-props-2 (level-1 session); storm on the new area; camera
   wall test; then holo-map and interact-focus from this branch. Model: Opus. Effort: high.
4. Merge claude/menus-rpg-5089fa into night-sanaa/main through the level-1 session (ask it first). Model: Sonnet. Effort: medium.
5. Balance pass 2: arc_arm identity, other encounters, workshop upgrades inside 65-90%. Model: Sonnet. Effort: medium.
6. Route B look pass (character light vs inbox/route_b.png). Model: Opus. Effort: high.
7. Action combat overhaul after the demo. Model: Opus. Effort: high.

## Paste-ready prompt
```
Continue the game repo (ferasalm/game) on branch claude/menus-rpg-5089fa. Read HANDOFF.md. Do Next step 1: write a
workshop-polish brief against inbox/ui_refs/mock_workshop.png, run it on agy through tools/build_pipeline.sh,
review, merge, check.sh; /handoff.
```
