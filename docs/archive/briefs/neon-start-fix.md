# Brief: neon-start-fix (fix pass on the merged start flow; <= 60 lines)
You are in your own worktree on your own branch made from neon/first-playable. Follow AGENTS.md / GEMINI.md, including
<review_misses>. Load the godot-gameplay-scripter skill.

## Why
The start flow (features/neon/start/, brief docs/briefs/neon-start.md) merged; a review found double confirms, a lost
glow, hard-coded player text and no mouse. Feras plays this first, so it must feel solid.

## Read first
docs/briefs/neon-start.md. features/neon/start/ (all), content/neon/start_flow.json, localization/neon_start.csv.

## What to fix
1. Busy guard: ignore every input while a transition runs (title glitch 0.15 s, the 0.4 s blur zoom, clip
   crossfades). `done` must be emitted exactly once per run, even under key mashing; the zoom's mid-callback must not
   re-apply a state that already changed.
2. Drive the view from StartSteps.next_state(state, input) (it exists but has no caller); remove the duplicated rules
   in start_flow.gd (Bilqis guard, quit). press_any, select_menu_index, select_hero and set_difficulty are used by
   the view or deleted.
3. glitch.gdshader: `COLOR = texture(TEXTURE, uv) * COLOR` (and the split channels likewise) so the cyan title colour
   and glow come back.
4. REACTION: fade the panel out over its fade time, then hide it (it popped out at once).
5. LAUNCH: HUD boot labels tick at evenly spaced times inside hud_boot_duration (not cumulative delays); then a
   0.2 s glitch out, then done.
6. All player text from localization keys via tr(): title, PRESS ANY BUTTON (NEON_START_PRESS_ANY), menu rows, hero
   cards, panel name/brief/playstyle, difficulty names and blurbs, hints, Musnad lines (NEON_MUSNAD_*). No literal
   English strings left in start_flow.tscn or the .gd files; remove keys nobody uses.
7. Font sizes, panel_bg and selection_bg from start_flow.json are applied by start_ui.gd; move the remaining
   numbers (16:9 aspect, blur peaks, glitch offset, blink range, alpha/dim multipliers) into the json + Def.
8. Mouse: the root Control mouse_filter IGNORE; menu rows, hero cards and difficulty buttons react to hover (select)
   and click (confirm); a click on the title counts as any button.
9. BlurOverlay visible only while a blur runs (it costs a full-screen copy every frame).
10. FadeOverlay uses the same cover-fit rect as the video.

## Do NOT edit
`features/neon/defs/`
`features/neon/logic/`
`features/neon/view/`
`features/neon/roof/`
`features/neon/battle/`
`features/neon/cold_open/`
`features/neon/neon_game.gd`
`features/neon/neon_game.tscn`
`features/combat/`
`content/combat/`
`content/neon/rooms.json`
`content/neon/sprites.json`
`assets/`
`core/`

## Tests (features/neon/start/tests/)
- StartSteps.next_state: the full path TITLE..LAUNCH and back from MENU, PICK, PANEL.
- StartFlow headless: mashing confirm 10 times in one frame at every state emits done at most once; the clip test
  reads content/neon/start_flow.json (every path loads as a VideoStream); no Label in the scene has text that is not
  a NEON_* key result (check that each visible label's text equals tr() of some key, or is set from code).

## Checklist
- test: features/neon/start/tests/test_start_flow.gd :: test_mashing_emits_done_once
- has: features/neon/start/shaders/glitch.gdshader :: * COLOR
- key: localization/neon_start.csv :: NEON_START_PRESS_ANY

## Proof
`bash tools/check.sh` raw last 15 lines; renders of TITLE, PICK and PANEL (tools/shot_neon_start.tscn) ->
C:/dev/game/inbox/neon_start_<state>.png; small WIP commits.
