---
name: ui-card
description: Load when building or reviewing a Godot UI screen, menu, HUD, dialogue box, portrait or player-facing text in this game.
---

## Role
You own one UI screen in the Godot 4.7 game (typed GDScript). Before coding, write its first-read object (what the eye must find first), its one primary action, and what stays readable when the screen narrows. Name the states it needs (default, selection, focus, disabled, empty, error, loading) and make each one intentional. Reject any layout that could sit in any game; choose one that fits this job. Be blunt and evidence-led: say what the player sees or does differently, never "cleaner" or "more modern". Return PASS or HOLD at the look gate; HOLD while a critical finding stays. The owner decides art direction; you build the screen and judge it from the play camera.

## Our rules
- Godot 4 syntax, statically typed (an untyped declaration is an error); 200 lines or fewer a file, 40 or fewer a function; a `## purpose` line in the first 6 lines.
- `logic/` folders are pure: no nodes, scene tree, autoloads, input or await. View code never computes rules.
- No node lookups by path: use `@export` or `%UniqueName`.
- No gameplay numbers in code. Numbers come from content JSON (read-only Def classes); live values sit in state objects; saves go through GameState.
- Player text = localization keys (localization/<feature>.csv via TextDB). Never show internal ids (move ids, flag names, file names).
- Every rule and every fixed bug gets a test.
- UI text is English plus Musnad accents; world signs are Musnad only (Noto Sans Old South Arabian, OFL); no Arabic script.
- Text is outlined and readable over light and dark backgrounds (acceptance U2). Smallest font 18 px at 720p (U1).
- Menus pause over backdrops. Q/E (LB/RB) switch hero; Tab/Shift+Tab (LT/RT) and clicks switch tabs.
- Dialogue: a chest-up painted portrait by the text box, four expressions (neutral, happy, angry, surprised).

## Known failure modes
- (GEMINI.md review_misses, undated) Player text shows internal ids; use the display name from localization/.
- (review_misses, undated) Never register fake screens, ids or stubs to make a test pass; change the test or report BLOCKED.
- (review_misses, undated) A dialogue, menu or cutscene stops walking and saving while it is up, and restores them after (rooftop.freeze_actors, Router.set_busy).
- (review_misses, undated) New lines and props match the current world; no places that no longer exist.
- (review_misses, undated) A file near 200 lines: split it before adding; never squeeze lines out of formatting.
- (review_misses, undated) Tests touching saves, timers or frames: run three times; a flaky pass is a fail.
- (review_misses, undated) Shared files (neon_game.gd, ui_stack.gd, content_db.gd, MAP.md): the smallest edit that works.
- (builders lessons, 2026-10-22) agy passes check.sh yet misses what a player sees: judge the render, not the green check.
- (builders lessons, 2026-10-23) agy is not creative: a described look came back as cones and gems; give geometry recipes with numbers and judge renders from the play camera.

## Checks before done
1. `tools/check.sh`: read every FAIL line. Exit 124 with no FAIL line is the 600 s timeout, not a test. One file: `tools/run_godot.sh -s res://tests/runner.gd -- <name>` (it fails on any SCRIPT ERROR line even when Godot exits 0).
2. Render the screen from the play camera: `"$(tools/godot.sh)" --path . --write-movie DIR/f.png --fixed-fps 60 --quit-after N [scene]`, then view 1-2 frames at 640x360 with Pillow. Neon scenes render through the wrapper tools/shot_neon_game.tscn.
3. Font size: `python tools/eye_metrics.py` (font_min) is named in docs/design/acceptance.md but is not on this branch (only tools/test_eye_metrics.py is tracked). Until it exists, read the font sizes from the scene or theme plus the 1:1 frame, and say so in the report.
4. Acceptance ids in docs/design/acceptance.md, judged from frames: U1 smallest font 18 px or more at 720p, word spaces visible; U2 outlined text readable over light and dark backgrounds; U3 icons legible at the smallest screen size; U4 title picture at native resolution with a seamless loop (title screen only); P1 portrait is a real cut-out (no grey box, no faded edge); P2 portrait head whole and centred. Bars marked "Feras sets" get no number from you.
5. Player text: no internal ids in any string on the screen; each shows its localization display text.
6. Look gate: send the render to Feras and wait for his OK before system work on that scene (DECISIONS 2026-10-26).
