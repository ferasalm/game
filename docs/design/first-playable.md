# Neon Glitch first playable (spec, 2026-10-26, overnight session)
Built from DECISIONS (Neon Glitch, opening order, prison-roof first fight, turn-based on the map) and Feras's line
of 2026-10-26: "it will be an isometric game similar to Hades, with our unique art style". Read here as the look,
camera and movement (isometric plate, free 8-direction movement, a following camera); the fight stays turn-based on
the map until Feras says otherwise (open question in HANDOFF). Everything lives in `features/neon/` (new), so the
parked 3D code and its tests stay untouched.

## 1. Flow (one run, about 6 minutes)
1. **Start** (`features/neon/start/`): title clip loops, PRESS ANY BUTTON -> menu (New Game; Continue, Options
   greyed) -> window-push clip -> CHOOSE YOUR HERO over the room loop (Rydan; Bilqis card "Later") -> Rydan panel
   over his loop (brief, playstyle, Normal/Hard) -> his reaction clip -> launch clip -> cold open. Clips are Feras's
   Flow outputs as Theora `.ogv` in `assets/video/` (EDIT_LIST.md order: 07 title, 02 push, 11 pick, 09 panel, 10
   reaction, 08 launch). Texts: drafts from texts.py into `localization/neon.csv`.
2. **Roya cold open** (`features/neon/cold_open/`, watch only): three painted frames (Flow), slow parallax push,
   rain overlay, qamariya colour band, caption lines, a system alert "IDENTIFYING..." that fills, she shields a
   child in the queue, the alert locks, cut to black. About 40 s; any key skips after the first play.
3. **Prison roof** (`features/neon/roof/`): Rydan bursts out of the stairwell hatch. Tutorial prompts (move, run,
   interact). Bilqis on comms (dialogue box, her portrait) kills the floodlight when Rydan reaches the fuse box
   (the one tech interaction). Two guards patrol the open middle; touching them starts the fight (from behind =
   ambush, the existing rule). After the win, the cable line on the far parapet is the exit -> "To be continued".
4. **Fight** (`features/neon/battle/`): turn-based on the map (the existing BattleSim, timeline and Rydan's kit),
   no arena swap: fighters step to spots on the plate around the contact point, the HUD comes in, the fight plays
   with sprite clips, then the roof resumes.

## 2. Iso conventions (every scene uses these)
- Plates: Feras's iso paintings, 2:1 dimetric (camera 30 degrees down). Shown at 1920x1080; a plate is wider than
  the screen when it was exported at 2K. World units are plate pixels; y-sort by feet.
- Walkable area: one outer polygon and hole polygons per room in `content/neon/rooms.json` (plate pixels). Pure
  `IsoWalk` (logic) keeps a step inside it and slides along edges. Occluders: foreground cut-outs from the plate with
  a baseline y; drawn over the hero when his feet are above the baseline.
- Movement: 8 directions in screen space, y speed x0.55 (iso foreshortening); walk/run speeds in content.
- Sprites: offline renders of the Rodin models (`tools/bake_sprites.tscn` -> `tools/art/sprite_sheet.py`): per
  state one PNG, rows = 8 screen directions (0 = right, counter-clockwise, 6 = toward camera), columns = frames;
  `content/neon/sprites.json` gives frame size, feet pivot, fps, loop, scale and the impact frame of attacks.

## 3. Fight on the map
- Start: screen glitch (0.3 s), letterbox bars, fighters walk to spots from pure `MapFormation` (hero right-front
  of the contact point, foes left-back, spaced 90 px, kept inside the walkable area).
- Rules: BattleSim exactly as BattleStage drives it (wait mode). Party = Rydan alone (solo, DECISIONS 2026-10-25).
  Foes: two prison guards (`concession_enforcer` kit, renamed by localization), encounter in `content/neon/`.
- View: attack = dash to the target, attack clip, hit on the impact frame (hitstop 70 ms, number pops, target hurt
  clip), dash back; tech moves = cast clip + the move's VFX; KO = ko clip, stays down; victory = end panel, XP.
- HUD: the Control-based pieces of the 3D battle HUD are reused where they only need screen rects (timeline bar,
  command menu, item menu, numbers); a 2D rect provider replaces the 3D projection.

## 4. Art list (each with a manifest entry)
| Asset | Source |
|---|---|
| Prison-roof plate (2K) + occluder cut-outs | Feras's rooftop concept, Flow (Nano Banana) edit into a prison roof |
| Rydan model | Hyper3D Rodin from Feras's sheet (Flow A-pose edit), rigged `ue`, retargeted UAL clips (CC0) |
| Guard sprites | `concession_enforcer_rodin.glb` (existing) |
| Cold-open frames (3) | Flow (Nano Banana), prompts in assets/manifest.json |
| Start clips | Feras's Flow videos -> .ogv |
| Portraits | Feras's sheets (Zayd_expressions = Rydan, Bilqis portrait sheet) |

## 5. Not in this build
Real-time combat, Zayd (no look yet), the `zayd` -> `rydan` code rename, the hilt refactor, saves for this flow,
Bilqis's campaign, music beyond the existing tracks.
