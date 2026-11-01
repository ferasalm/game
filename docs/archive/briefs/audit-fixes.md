# Brief: audit-fixes (<= 60 lines; from the 2026-10-24 audit of the level-1 merges)
You are in your own worktree on branch gemini/audit-fixes (made from origin/main). Follow GEMINI.md, including
<review_misses>. Load the godot-gameplay-scripter skill.

## Why
An audit after the milestone merge found smaller defects the gates missed. Fix them without changing what works.

## Read first
features/world/view/interact_focus.gd; features/world/interact/sabil_spot.gd; features/world/tests/test_interact_focus.gd;
features/world/interior/tayramana_room.gd; content/world/rooms.json; content/ui/style.json;
features/world/tests/test_walk_graph.gd; features/world/tests/test_level1_blockout.gd.

## What to build
1. Sabil: drinking at the sabil opens the slot picker after its first screen closes; InteractFocus must ease back
   ONCE, after the last screen of the spot closes (not between the two). Test: advance time between the screens and
   check the camera is still on the focus shot while the picker is open, and back on the follow view after it closes.
2. interact_focus.gd: the literal `0.6` fallbacks for t_focus_zoom (~lines 92 and 120) go; read the style key only.
3. tayramana_room.gd: lamp colour, energy and range (~lines 59 and 66) and the sit-spot fallbacks (~line 138) come from
   content/world/rooms.json (tayramana entry); keep today's values exactly.
4. test_walk_graph.gd ~line 76: the W-marker reachability check runs for any W marker again, as before level1-polish.
5. test_level1_blockout.gd ~line 124: patrol_drone's skipped clearance check gets a real replacement: its patrol path
   keeps >= the content's crossing clearance from every crossing except X4, whose landing it starts beside by design.

## Do NOT edit
`core/save/`
`core/game_state.gd`
`features/prototype/prototype_main.gd`
`features/world/interior/tayramana_flow.gd`
`tools/check.sh`
`tools/build_gate.py`
`CLAUDE.md`
`docs/DECISIONS.md`
`HANDOFF.md`

## Tests
Steps 1, 4 and 5 name their tests; steps 2 and 3 keep every existing test green with the same values.

## Checklist
- file: features/world/view/interact_focus.gd
- file: features/world/tests/test_interact_focus.gd
- file: content/world/rooms.json
- file: features/world/tests/test_walk_graph.gd

## Proof
`bash tools/check.sh` raw last 15 lines; small WIP commits; final message ends with `Built-by: Gemini 3.8 Flash (agy)`.
