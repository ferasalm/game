# Brief: workbench (<= 60 lines)
You are in your own worktree on branch gemini/workbench (made from claude/night-sanaa). Follow GEMINI.md, including
<review_misses>. Load the technical-artist skill (.agents/skills/technical-artist).

## Why
Owner playtest 2026-10-23 item 7: "The workshop is plain", unlike the designed one. art-bible.md: "Workshop bench: low
table, a glowing screen, tools, a brass-hilted blade." A Claude builder started it and was stopped mid-unit.

## Read first
`git diff 08c3a74 f607092` (the WIP: content/world/props/workbench.json, features/world/tests/test_workbench.gd,
workshop_spot.gd, explore_rules_def.gd, explore.json). docs/design/art-bible.md (palette letters, scale);
docs/MAP.md lines for prop_part.gd, prop_mesh.gd, prop_builder.gd, workshop_spot.gd; docs/design/level-1.md "Workshop".

## What to build
1. Port the WIP onto this branch (`git checkout f607092 -- <its files>` then fix what no longer fits; the repo
   moved on: run the tests). Keep its tests that still make sense.
2. Finish the prop as a cyberpunk-meets-old-Sana'a workbench, all in workbench.json parts (box/frustum, palette
   letters, no new code): a low cedar table (knee height, 1.8 x 0.8 m), a cushion to kneel on, a tilted glowing
   screen (emissive cyan) on a brass arm, a vise, a rack of 4 tools, a jambiyah blank with a brass hilt on a cloth,
   a coil of cable to a battery box under the table, a small brazier glow (orange). Collide box = the table only.
3. The workshop place uses it (WorkshopSpot), facing the player's approach; the interact point stays reachable.
4. A warm work light (existing AreaLights fake pool, numbers in content) over the table.

## Do NOT edit
features/combat/, content/combat/, localization/combat.csv, features/world/view/explore_camera.gd,
features/world/player/, content/world/camera.json, content/world/areas.json (beyond the workshop entry's prop),
docs/design/, HANDOFF.md, docs/DECISIONS.md.

## Tests
The bench builds with every part; its collide box covers only the table; the interact point is reachable (walk
graph) and not inside any collider; the screen part is emissive.

## Proof
`bash tools/check.sh` raw last 15 lines; renders (not headless, LESSONS 2): the bench close up and in the rooftop
from the play camera, to C:/dev/game/inbox/workbench_*.png (960x540); small WIP commits; final message ends with
`Built-by: Gemini 3.8 Flash (agy)`.
