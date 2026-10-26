# Brief: playtest-capture (<= 60 lines)
You are in your own worktree on branch oc/playtest-capture. Follow AGENTS.md. Load the godot-gameplay-scripter skill.

## Why
Feras plays Neon Glitch and wants to circle bugs on screen with a note; Claude reads the result from inbox/playtest/.

## Read first
CLAUDE.md "Code rules"; features/neon/neon_game.gd + .tscn; features/neon/battle/map_battle.gd (_tick_batch);
features/neon/tests/test_neon_game.gd (scene-test pattern); tests/runner.gd line 18 (per-checkout test dir).

## What to build (folder features/debug/playtest/; class names prefixed Playtest)
1. Pure logic/ (RefCounted, no nodes/Input/await): `PlaytestStrokes` (begin(p), add(p), end(), undo(), count(),
   strokes() -> Array[PackedVector2Array]; static ellipse(a, b, segments) = closed ellipse in the a-b box);
   `PlaytestMarks.paint(image, strokes, xform: Transform2D, color, width_px)` stamps fill_rect squares every 1 px
   along each segment, a lone point = a dot; `PlaytestDump`: build(note, stamp, scene, source: Dictionary,
   log_lines) -> Dictionary {time, scene, stage, room, hero, fight, log, note}; fight(ticks, fighters, events);
   plain(v) turns Vector2 into [x, y] (1 decimal) and StringName into String, recursively; caps: note 300 chars,
   log 50, events 10; folder_name(datetime_string, msec) -> "2026-10-26_21-05-33_042" (no colons: Windows).
   `PlaytestLogRing` (push(line), lines(), cap 50). Tool numbers live as named consts in these files.
2. `playtest_logger.gd` (extends Logger, 4.7.2 signature: `_log_error(function: String, file: String, line: int,
   code: String, rationale: String, editor_notify: bool, error_type: int, script_backtraces: Array[ScriptBacktrace])`,
   `_log_message(message: String, error: bool)`): a Mutex, pushes "ERROR|WARNING file:line rationale-or-code" and
   messages only when error is true into a PlaytestLogRing. Never print inside the callbacks.
3. `playtest_capture.gd` (Node, process_mode ALWAYS) + `playtest_capture.tscn`, `@export var source: Node` (calls
   `source.call("playtest_state")` when it has the method), `var out_root: String = "res://inbox/playtest"`,
   `var grab: Callable` (default: get_viewport().get_texture().get_image(); tests inject one: headless grab prints
   ERROR). Off when not OS.is_debug_build() (set_process_input(false), no logger). _ready: OS.add_logger;
   _exit_tree: OS.remove_logger. `_input`: action `playtest_capture` opens (grab the shot FIRST, then remember
   get_tree().paused and gui_get_focus_owner(), pause, show the overlay, mouse visible).
4. Overlay (CanvasLayer layer 128, ALWAYS; child Control draws strokes red, 4 px): left drag = freehand, right
   drag = ellipse; a LineEdit for the note; a hint Label tr("PLAYTEST_HINT"), note placeholder tr("PLAYTEST_NOTE").
   Handle in `_input` with set_input_as_handled() BEFORE the LineEdit sees them: Enter/KP Enter or the capture
   action = save, Esc = cancel, Ctrl+Z = undo stroke. Save: mkdir out_root/<folder_name>/, write shot.png, marked.png
   (copy of the shot painted with xform = get_viewport().get_final_transform() * canvas.get_global_transform_with_canvas(),
   width 4 * xform scale), state.json (JSON.stringify(PlaytestDump.build(...), "  ")), out_root/.gdignore if missing;
   print("PLAYTEST " + absolute folder). Close: hide overlay, restore focus and mouse mode, then UNPAUSE ONLY in a
   later _process once interact, back and menu are all released (else Enter fires the fuse box / battle confirm).
5. NeonGame: a `PlaytestCapture` child in neon_game.tscn with source = NeonGame; `func playtest_state() -> Dictionary`
   returns `NeonPlaytestState.collect(stage, _roof, _battle)` (new features/neon/neon_playtest_state.gd: stage, room
   id, hero position, and when a fight is on PlaytestDump.fight(sim.ticks, [{id, side, hp, sp}] from
   sim.timeline.units, battle.recent_events)). MapBattle: at most 5 new lines: `var recent_events: Array[String]`,
   _tick_batch appends str(event) per event and keeps the last 10.
6. project.godot [input]: `playtest_capture={"deadzone": 0.2, "events": [Object(InputEventKey,"physical_keycode":4194343),
   Object(InputEventJoypadButton,"button_index":4)]}` (F12, joypad Back). Append to localization/neon.csv:
   PLAYTEST_HINT ("Drag: draw | Right-drag: circle | Ctrl+Z: undo | Enter: save | Esc: cancel"), PLAYTEST_NOTE ("Note").
7. tools/playtest.sh: runs `"$(tools/godot.sh)" --path . "$@" 2>&1 | tee inbox/playtest/game.log` (mkdir first,
   `set -o pipefail`). tools/shot_playtest.tscn + .gd (like tools/shot_neon_game): non-headless, reach the roof,
   open the capture with the REAL grab, add a circle and a stroke, note "render test", save, quit.
8. `python tools/map.py` last.

## Do NOT edit
`features/neon/roof/`
`features/combat/`
`features/neon/start/`
`features/neon/cold_open/`
`core/`
`content/`
`tests/`
`docs/ARCHITECTURE.md`
`HANDOFF.md`
`docs/DECISIONS.md`
`assets/`
Also: map_battle.gd stays <= 191 lines; features/debug/ never names NeonGame, MapBattle or RoofScene.

## Tests (features/debug/playtest/tests/ and features/neon/tests/; no push_error/push_warning in tests)
- strokes: begin/add/end, undo removes only the last, undo on empty is safe; ellipse closed, inside its box.
- marks: a painted stroke turns pixels red under xform; pixels away from it stay; points outside the image are safe.
- dump: keys present, Vector2 -> [x, y], caps (note, log 50, events 10), JSON parse round-trip, folder_name no ':'.
- logger: calling _log_error/_log_message directly fills the ring; the ring keeps the newest 50.
- capture: open pauses, cancel unpauses after release; save with an injected 64x36 Image writes the 3 files to a
  test dir (SaveService.test_dir_for(...)/playtest, removed after); paused stays restored; unpause in teardown always.
- neon: playtest_state on the roof has room "prison_roof" and a hero [x, y]; in a fight it has ticks and 3 fighters.

## Checklist
- file: features/debug/playtest/logic/playtest_dump.gd
- file: features/debug/playtest/logic/playtest_strokes.gd
- file: features/debug/playtest/playtest_capture.tscn
- file: tools/playtest.sh
- has: features/neon/neon_game.gd :: func playtest_state
- has: project.godot :: playtest_capture=
- key: localization/neon.csv :: PLAYTEST_HINT
- key: localization/neon.csv :: PLAYTEST_NOTE

## Proof
`bash tools/check.sh` raw last 15 lines; small WIP commits; final message ends `Built-by: <model> (opencode)`.
