# HANDOFF (current state only; rewritten by /handoff; max 60 lines)
Last updated: 2026-10-23, session 16 manager (Opus 5.5, `claude-opus-5-5`): per-track HANDOFF.

## Shared
- Builders (DECISIONS 2026-10-23): up to 5 at once, all sessions: 2 agy, 2 Cloudflare DeepSeek (tools/cf_build.sh, <= $10 over free neurons), 1 Inkling :free. Briefs name a skill. Count game-wt/* first.
- Balance: start gear 82.7-89% wins; arc_arm needs a real upside; other encounters not re-run.
- Waiting on the owner: judge menu renders (inbox/menu_*.png) vs mockups; make icon art (5 heads, 4 items; assets/icons/ missing, letter discs stand in); play the Abu Nabil fight; judge the five roofs and souq props when merged; play the camera.

### Next steps (one per chat; reviews Sonnet, design and art judgment Opus)
1. Balance pass 2: arc_arm identity, every encounter, workshop upgrades inside 65-90%. Model: Sonnet. Effort: medium.
2. Route B look pass (character light vs inbox/route_b.png). Model: Opus. Effort: high.
3. Action combat overhaul after the demo. Model: Opus. Effort: high.

## Track: Level 1 (owner: the next chat from the card "Level 1: review and merge the five-roof blockout")
- Branch claude/night-sanaa (= old main). Status: gemini/level1-blockout-fix and souq-props-2 unreviewed (game-wt); holo-map's five-roof view, interact-focus and puzzle placement wait for that merge.
1. Review + merge level1-blockout-fix and souq-props-2 into main; storm on the new area; camera wall test; then interact-focus and puzzle placement. Model: Opus. Effort: high.
`Continue ferasalm/game on main. Read HANDOFF.md (Level 1). Do its next step as manager; check.sh; renders to Feras; /handoff.`

## Track: RPG + menus (owner: session local_c29a3aa9)
- Branch claude/menus-rpg-5089fa -> main (+ claude/puzzles-streamline-f7ef2d, merged); merges at check.sh pass.
- Status: built rolls+flee, progression (XP, levels, classes, armor, stones, save v5), Zayd's kit + damage split, menu skins + Feras's 7 backdrops, equipment menu (3D hologram), workshop menu (upgrade, gemstones, crafting), equipment polish, balance-gear, build gate (tools/build_gate.py, merge_run.sh), opencode skill subagents (tools/oc_agents.py).
- RUNNING: holo-map (agy, game-wt/holo-map, rpg-menus session). To review: progression-pure (PASS, game-wt/progression-pure).
1. Review progression-pure and holo-map, workshop polish brief vs inbox/ui_refs/mock_workshop.png. Model: Sonnet. Effort: medium.
`Continue ferasalm/game on claude/menus-rpg-5089fa. Read HANDOFF.md (RPG + menus). Do its next step; check.sh; /handoff.`

## Track: Puzzles (owner: session local_8f9c02cf)
- Status: puzzle logic built (light lock, water network, hints). RUNNING: puzzle-scene (DeepSeek, game-wt/puzzle-scene, puzzles session).
1. Review puzzle-scene (renders vs valve-puzzles.md), merge, renders to Feras. Model: Opus. Effort: high.
`Continue ferasalm/game on main. Read HANDOFF.md (Puzzles). Do its next step; check.sh; /handoff.`
