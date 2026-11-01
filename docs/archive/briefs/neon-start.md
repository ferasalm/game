# Brief: neon-start (Neon Glitch start flow over Feras's Flow clips; <= 60 lines)
You are in your own worktree on your own branch made from neon/first-playable. Follow GEMINI.md / AGENTS.md, including
<review_misses>. Load the godot-gameplay-scripter skill.

## Why
DECISIONS 2026-10-25: start = menu -> qamariya -> pick hero -> blur zoom: brief + Normal/Hard -> reaction -> blur
pull-back -> game; clips play as video, UI on top; UI English with Musnad accents. Rydan only for now.

## Read first
docs/design/first-playable.md section 1. The concept cut (read only, outside your worktree): C:/dev/game/inbox/Neon
Glitch Videos/edit/EDIT_LIST.md, ui.py and hud.py (the look of the overlays), NeonGlitch_start_concept_Rydan.mp4.
Clips (Theora, 1280x720, 4 s each): assets/video/title_loop, window_push, hero_pick, rydan_panel, rydan_reaction,
launch (.ogv). Fonts: assets/fonts/reem_kufi.ttf (UI), noto_sans_old_south_arabian.ttf (Musnad lines).
All texts already exist: localization/neon_start.csv (keys NEON_START_*, NEON_HERO_*, NEON_DIFF_*, NEON_HINT_*,
NEON_MUSNAD_*); use them and add only keys you truly need.

## What to build (all in features/neon/start/ + content/neon/start_flow.json + localization/neon_start.csv)
1. `start_flow.tscn` + `start_flow.gd` (class StartFlow, Control, full screen): one VideoStreamPlayer showing the
   current clip stretched (keep aspect, cover), the UI on top, `signal done(difficulty: StringName)`.
2. States (pure `logic/start_steps.gd`, class StartSteps: next state for an input, tested):
   TITLE (title_loop loops; logo "NEON GLITCH" in Reem Kufi with a cyan glow and a 0.15 s RGB-split glitch every
   ~3 s; "PRESS ANY BUTTON" blinks) -> any key: glitch -> MENU (New Game; Continue and Options greyed; Quit) ->
   New Game: window_push plays once under a radial blur that ramps up then down (a CanvasItem shader on the video)
   -> PICK (hero_pick loops; two cards: RYDAN selectable with a Musnad accent line, BILQIS dimmed "LATER") -> confirm
   -> 0.4 s blur zoom -> PANEL (rydan_panel loops; left panel: name, brief, playstyle; difficulty Normal/Hard
   toggled with left/right; the selected one lit) -> confirm -> REACTION (rydan_reaction once, panel fades out) ->
   LAUNCH (launch once; a HUD boot overlay: thin cyan lines and three Musnad labels ticking in, then a glitch out)
   -> done(difficulty). `back` steps back from MENU, PICK and PANEL.
3. Every clip switch hides the cut: a 0.25 s crossfade through a frame grab (or a short blur pulse); the video
   never shows a black frame. Loops restart seamlessly (`loop` on the player).
4. Timings, colours and sizes in content/neon/start_flow.json read by a Def registered with one KINDS line in
   core/content_db.gd (the only core edit allowed).
5. Keyboard, mouse and gamepad: arrows/WASD/stick move, Enter/Space/A confirm, Esc/B back (input map actions
   move_*, interact, back; add none).
6. The scene runs on its own (F6) and prints the chosen difficulty on done.

## Do NOT edit
`features/neon/defs/`
`features/neon/logic/`
`features/neon/view/`
`features/neon/roof/`
`features/neon/battle/`
`features/combat/`
`content/neon/rooms.json`
`content/neon/sprites.json`
`assets/`
Only core edit: one KINDS line in core/content_db.gd.

## Tests (features/neon/start/tests/)
- StartSteps: the full path TITLE..LAUNCH, back from each state, Bilqis cannot be picked, difficulty toggles.
- StartFlow headless: every clip path loads as a VideoStream; done fires once with the chosen difficulty.

## Checklist
- file: features/neon/start/start_flow.tscn
- has: features/neon/start/start_flow.gd :: signal done
- has: features/neon/start/logic/start_steps.gd :: class_name StartSteps
- test: features/neon/start/tests/test_start_steps.gd :: test_full_path_to_launch
- key: localization/neon_start.csv :: NEON_START_PRESS_ANY

## Proof
`bash tools/check.sh` raw last 15 lines; renders of TITLE, PICK and PANEL (a tools/shot_neon_start.tscn wrapper like
tools/shot_dialogue.tscn, state passed as an argument) -> C:/dev/game/inbox/neon_start_<state>.png; small WIP commits.
