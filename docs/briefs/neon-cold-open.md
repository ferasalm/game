# Brief: neon-cold-open (Neon Glitch: Roya cold open, watch only, about 40 s; <= 60 lines)
You are in your own worktree on your own branch made from neon/first-playable. Follow GEMINI.md / AGENTS.md, including
<review_misses>. Load the godot-gameplay-scripter skill.

## Why
DECISIONS 2026-10-26: start flow -> Roya cold open (in-engine, not a Flow video) -> prison escape. Story (docs/story/
rydan.twee, passage "Roya cold open"): through qamariya glass Roya watches a ration checkpoint, shields someone in the
queue, a system alert identifies her, cut to black. Watch only.

## Read first
docs/design/first-playable.md section 1 item 2. The three painted 16:9 frames (2752x1536):
assets/textures/neon/cold_open_1.webp (rain on qamariya glass), _2 (the checkpoint seen through the glass), _3 (Roya
shields a child, a red scanner beam on her face). Texts already exist: localization/neon_cold_open.csv (NEON_COLD_*).
How a Def is read: features/neon/defs/neon_room_def.gd + core/content_db.gd KINDS. Fonts: assets/fonts/reem_kufi.ttf.

## What to build (all in features/neon/cold_open/ + content/neon/cold_open.json)
1. `cold_open.tscn` + `cold_open.gd` (class ColdOpen, Control, full screen, black background): `signal done`,
   `func start() -> void` (plays from the top), `@export var autostart: bool = true` (F6 runs it alone and prints
   "cold open done"), `@export var seen_path: String = "user://neon_seen.cfg"`.
2. Shots from content/neon/cold_open.json (a NeonColdOpenDef registered with ONE KINDS line in core/content_db.gd,
   the only core edit): per shot the texture path, start and end scale (1.0 -> 1.08), start and end offset in px (a
   slow pan), duration (12 s, 12 s, 14 s), the caption key. Each shot is a TextureRect (stretch keep-aspect-covered)
   tweened from start to end; 1.0 s crossfade between shots (never a black gap). Parallax: shot 2 and 3 get a second
   layer, the same texture at 30 % alpha pushed 1.5x faster, so near and far drift apart.
3. Rain overlay over the frames (a full-screen ColorRect with your own canvas_item shader: slanted thin streaks, two
   speeds, a faint green tint; params in the json). Captions: bottom-centre label (Reem Kufi, white, black outline),
   fade in 0.6 s after the shot starts, out 0.6 s before it ends.
4. Alert (during shot 3, from 4 s in): a slim bar top-centre, red frame, text NEON_COLD_ALERT, fill grows 0 -> 100 %
   over 6 s with a scan-line flicker; when full the text becomes NEON_COLD_ALERT_LOCKED, the bar flashes red 3 times
   and a red vignette pulses once. Then 1.5 s later: cut to black (instant), hold 1.0 s, emit `done` exactly once.
5. Music: assets/audio/music/night_rooftops.ogg on an own AudioStreamPlayer at -12 dB, fades out over the cut.
6. Skip: if seen_path holds `[cold_open] seen=true`, any key / button / click skips straight to the cut-to-black end
   (a small NEON_COLD_SKIP hint bottom-right after 1 s). On the first full play-through, write seen=true (ConfigFile).
   Before that, input is ignored.
7. `tools/shot_neon_cold_open.tscn` (wrapper like tools/shot_dialogue.tscn) renders shot 2 mid-caption and shot 3 with
   the alert half full -> C:/dev/game/inbox/neon_cold_open_<n>.png.

## Do NOT edit
`features/neon/defs/`
`features/neon/logic/`
`features/neon/view/`
`features/neon/roof/`
`features/neon/battle/`
`features/neon/start/`
`features/combat/`
`content/neon/rooms.json`
`content/neon/sprites.json`
`assets/`
`localization/neon_cold_open.csv`
`localization/neon_cold_open.csv.import`
Only core edit: one KINDS line in core/content_db.gd.

## Tests (features/neon/cold_open/tests/)
- Def: the json loads, three shots, every texture path exists, every caption key exists in TextDB.
- ColdOpen headless (seen_path = a temp file): stepping time past the total emits `done` exactly once; input before
  seen does nothing; with seen=true, one key press emits `done` within 2 s; after a full play the file says seen=true.

## Checklist
- file: features/neon/cold_open/cold_open.tscn
- has: features/neon/cold_open/cold_open.gd :: signal done
- has: features/neon/cold_open/cold_open.gd :: func start
- test: features/neon/cold_open/tests/test_cold_open.gd :: test_done_fires_once
- file: content/neon/cold_open.json

## Proof
`bash tools/check.sh` raw last 15 lines; the two renders above; small WIP commits.
