# Brief: m1-touch (nv GLM-5.3 max + DeepSeek high fix; GDScript, RUN_KIND=godot)
You are in your own worktree on branch oc/m1-touch (made from origin/m1-touch-base: m1-defs merged, plus the locked tests; pushed).
Follow GEMINI.md, including <review_misses>. Load the builders skill.
Pattern: features/ui/view/ui_stack.gd, features/neon/roof/view/roof_hud.gd
Timebox: 45 min. First commit within 15 min, then small WIP commits.

## Why
Feras 11-02: floating stick plus buttons for the phone, the same actions as the keyboard; VISION Risks: M1 must play well on a
phone. Pillar served: 1 Hades-feel combat (on touch too; D17).

## Read first
The locked tests (read-only). docs/design/m1-fight.md section 6, FightTouchDef (m1-defs), content/fight/touch.json, the
[input] block of project.godot (the move_* actions). docs/research/m1-fight-github.md names an MIT floating-stick repo as a
reference; ours is written fresh unless a copy keeps its licence header and gets a manifest line.

## What to build
1. project.godot [input]: actions attack (J, mouse left, gamepad X), dash (K, Shift, gamepad A), parry (L, mouse right, gamepad
   left shoulder). Existing actions untouched; keys must not clash with move_*, interact, back or menu.
2. features/fight/touch/logic/touch_layout.gd (pure): button rects from FightTouchDef for a viewport size and a safe-area inset
   (anchor % + offset, sizes in viewport px), `stick_vector(origin, current, radius, deadzone) -> Vector2` clamped to length 1,
   `button_at(point) -> StringName`.
3. features/fight/touch/view/touch_controls.gd (CanvasLayer): floating stick appears where a touch starts in the left half;
   buttons on the right; multi-touch by finger index; presses go through Input.action_press and action_release with strength
   (the sim sees the same actions as the keyboard); visible only when DisplayServer.is_touchscreen_available() or the
   `--touch` flag; hides when a gamepad button arrives. Text (none needed) through TextDB if added.

## Do NOT edit
D6 defaults, protected by tools/build_gate.py without being listed. Keep this prose free of backticks outside May edit.
`features/fight/defs/`
`content/fight/`

## May edit
`project.godot`

## Ripple
project.godot [input]: any test that counts actions (test_input_map if present) is run by the build; pause/menu use `menu` and
`back`, which stay. Android export (row 4) reads the same actions.

## Pre-mortem
Player: a thumb hides the action or a second finger cancels the first -> tests send two touch points and assert both actions hold.
Gate: touch needs a device -> tests inject InputEventScreenTouch and Drag into the node. Review: a key clash -> a test lists every
action's keycodes and fails on a duplicate in the same mode.

## Tests
- features/fight/tests/test_touch_layout.gd :: rects stay inside the viewport and the safe area; every button >= 96 px at
  1920x1080; stick vector is 0 inside the deadzone, length 1 at radius and beyond; button_at hits its centre, not the gap.
- features/fight/tests/test_touch_controls.gd :: touch down on the attack button presses `attack`, up releases; a drag on the
  left moves `move_*` strength; two fingers hold stick and attack together; hidden without a touchscreen unless --touch.
- features/fight/tests/test_fight_actions.gd :: attack, dash, parry exist with a key, a mouse or pad event; no duplicate keycode.
- player-visible: render of the controls at 1920x1080 shows three buttons right, none overlapping the stick zone (a frame test).

## Checklist
- file: features/fight/touch/view/touch_controls.gd
- has: features/fight/touch/logic/touch_layout.gd :: static func stick_vector
- test: features/fight/tests/test_touch_controls.gd :: test_two_fingers_hold_both

## Proof
`bash tools/check.sh` raw last 15 lines; final message ends with `Built-by: GLM-5.3 (opencode)`.
