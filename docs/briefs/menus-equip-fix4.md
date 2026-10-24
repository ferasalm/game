# Brief: menus-equip-fix4 (<= 60 lines; small fix pass on top of oc/menus-equip-fix3)
You are in your own worktree on branch oc/menus-equip-fix4 (made from oc/menus-equip-fix3). Follow AGENTS.md.
Load the minimal-change-engineer and godot-gameplay-scripter skills. Read docs/briefs/menus-equip-fix3.md first.

## Why
fix3's tests now pass (Claude fixed the layout timing in commit 27bb265), but lint fails and the anchor numbers sit
in code. Change nothing else.

## What to fix
1. Lint (tools/lint_gd.py; <= 200 lines a file, <= 40 a function):
   - features/art/view/model_source.gd (222 lines): move anchor() and _fallback_anchor() into a new
     features/art/view/model_anchors.gd (static helpers, `## purpose` line); model_source.gd calls it.
   - features/art/view/character_visual.gd (202): shorten the header comment back to <= 3 lines.
   - features/ui/view/screens/pause_hero_row.gd (201): trim by moving _stat_bar into a small helper file or
     merging the two accessors' blank lines; behaviour unchanged.
   - features/ui/tests/test_pause_menu.gd:68: split the 41-line test into two tests (portraits; bars).
2. Numbers in code: CHEST_HEIGHT, BELT_HEIGHT, ARM_HEIGHT, HAND_HEIGHT, the 0.4 / 0.45 / 0.5 width factors and the
   1.8 fallback height in model_source.gd, and the 0.35 / BELT_HEIGHT numbers in features/art/view/pixel_source.gd,
   move to content/art/visual.json (read through the existing visual def; a missing key fails a test).
3. Do not touch any test assertion except the split in step 1; run `bash tools/check.sh` and fix only lint/test
   failures you caused.
4. Renders: inbox/fix_equip_zayd.png, inbox/fix_equip_bilqis.png, inbox/fix_pause.png (tools/shot_menu.tscn).

## Do NOT edit
`core/`
`features/map/`
`features/world/`
`tools/check.sh`
`CLAUDE.md`
`docs/DECISIONS.md`
`HANDOFF.md`

## Tests
A test that every anchor number loads from visual.json; all equipment, pause, ui and art tests stay green.

## Checklist
- file: features/art/view/model_anchors.gd
- file: content/art/visual.json

## Proof
`bash tools/check.sh` raw last 15 lines; the three renders; final message ends with `Built-by: <model> (cf)`.
