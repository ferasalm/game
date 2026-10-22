# Lessons (curated; symptom -> cause -> fix; dated; max 100 lines; condense back to ~70)

## 1. You can do this yourself
- Run Godot headless with tools/run_godot.sh: it fails on any SCRIPT ERROR or ERROR line even when Godot exits 0
  (2026-10-19).
- check.sh "tests FAIL" with `run_godot: exit code 124` and no FAIL line = the timeout, not a test: 595 tests take
  ~5 min on the laptop -> cap raised to 600 s (2026-10-23).

## 2. Traps (Godot)
- Test runner found 0 tests -> `"abc".contains("")` is false in Godot 4.7 -> guard empty strings (2026-10-19).
- Parse error "isn't a constant expression" -> a `const` Dictionary can't hold class_name references -> use
  `preload("res://...")` (2026-10-19).
- A scene added in a SceneTree script's `_initialize()` had no `_ready()` yet -> run tests from the first
  `_process()` (tests/runner.gd) (2026-10-19).
- A test with a runtime error still counts as passed by the runner; only the SCRIPT ERROR line fails the run ->
  never trust the summary line alone; read check.sh's FAIL lines (2026-10-19).
- No agent (lead included) may write *.import now -> new text goes into an existing CSV, never a new one
  (2026-10-22).
- Godot 4.4+ writes a `.uid` next to every script and scene -> commit them, never read them (2026-10-19).
- `tests/test_*.gd` files are run as tests -> helper files in a tests/ folder must not start with `test_` (2026-10-19).
- Godot's CSV translation import listed in project settings errors on a fresh clone (CI) -> CSVs use the "keep"
  importer and TextDB loads them at startup; a test enforces "keep" for every CSV (2026-10-21).
- `move_and_slide` moves nothing when `_physics_process` is called by hand in tests -> `move_and_collide` plus a
  slide on the remainder (2026-10-21).
- Item menu rows flipped order between runs -> sorting StringNames compares addresses -> sort by String
  (2026-10-21).
- Lathe garments showed skin and swung like capes -> torso pieces end at the waist (depth >= 0.9) over pelvis
  pieces raised 0.15 m; long coats split at the pelvis (2026-10-22).
- Headless MultiMesh returns identity instance transforms -> keep them in node meta for tests (2026-10-21).
- Rodin glb: feet at y=-0.95 (centred) made Zayd twice as tall and half underground; its UE rig has other bone axes
  than the library (bodies twisted on the floor); Godot's glTF export kept the old buffers (18 MB) -> tools/rodin
  (Godot LOD indices + a Python glb rewrite: lift, strip textures) and PoseFollow (runtime retarget) (2026-10-22).
- Rodin bakes props into the one body mesh (Zayd's dagger is one connected piece with him) -> a triangle cut risks a
  see-through hole (the skin shader culls back faces) -> rewrite_glb.py --press; the real part hides it (2026-10-22).
- `match` is a GDScript keyword: `var match` is a parse error (2026-10-22).
- Foot heights in a SceneTree script: get_bone_global_pose stayed at rest after seek -> set bones from the tracks,
  compose get_bone_pose up the parents (2026-10-23).
- SurfaceBuffer boxes have no bottom face -> a chest lid swung open showed a hollow frame over a closed top -> a
  180-degree-tilted lining part on the lid and a dark inside on the box (2026-10-23).
- A keeper behind his stall was hidden by the awning from the play camera -> StallKeeper: the counter's end
  (2026-10-23).
- set_exploring(false) hides the player and the patrols -> talks use rooftop.freeze_actors (2026-10-22).
- See a scene without the owner: non-headless `"$(tools/godot.sh)" --path . --write-movie DIR/f.png --fixed-fps 60
  --quit-after N [scene]`, then view 1-2 frames scaled to 640x360 with Pillow (2026-10-21).

## 3. From reem-bot and feras-career (verified there)
- A check that only prints never fails -> every check exits non-zero; probe each new rule with one bad case.
- A subagent costs 150-290k tokens -> delegate only when the worker reads far more than its brief (reem-bot).
- A superseded rule lives on in a doc or prompt string -> grep for it when a decision changes (reem-bot).
- Gemini research contains invented numbers -> ideas and norms only, never facts (feras-career; here too).

## 4. Parallel builders (Claude agents 2026-10-21; agy 2026-10-22)
- One worktree per builder; shared registries (ContentDB KINDS, MAP.md) conflict but resolve by keeping both sides;
  regenerate MAP.md after `git add`; check CI (`gh run list`) after merging to main.
- A side chat editing the same checkout blocked a merge -> one session owns git; others message it.
- Python's write_text on Windows writes CRLF -> pass newline="
" (python is `python` here, not python3).
- The Read(**/*.import) deny also blocks an agent's Write to an existing .import -> the lead writes new "keep" .import
  files before Godot's import runs. After a merge adds class_names: `tools/run_godot.sh --import` first.
- Claude Agent worktrees branch from main -> briefs start with `git merge --ff-only <session branch>`; agy_task.sh
  takes the base branch itself.
- Limits, crashes and API errors kill builders mid-edit -> WIP commits early; resume with SendMessage, or a small fresh
  agent in that worktree; after a limit reset start a NEW chat (an old transcript is re-sent uncached).
- Plan mode in the lead paused every background builder -> only while none run. `cd` into a worktree moved the
  session's directory -> `git -C <path>`. lint skips .claude/.
- B4 "needed a builder" but was one tuning pass from done -> run check.sh in a WIP worktree first (2026-10-22).
- Parallel worktrees share one user:// folder -> save tests flake when two checkouts run tests at once -> per-checkout
  test save dir (brief save-slots) (2026-10-22).
- `check.sh | tail && git commit` committed a failing run (tail succeeds) -> grep .check/*.log for FAIL first.
- agy -p stops after 1h30 ("print timeout") mid-turn with no report; its commits stay -> review the commits and run
  check.sh in the worktree yourself (rooftop-v2, 2026-10-22).
- agy builds pass check.sh yet miss things a player sees (internal ids in text, no input lock during a talk, fake
  screen registrations for a test) -> GEMINI.md review_misses + tools/agy_review.sh (2026-10-22).

## 5. Art, browser, night look (2026-10-21)
- Owner saw "3 FPS": that was a --write-movie render (each frame goes to disk) -> real FPS only via fps_probe.gd.
- The built-in browser pane's downloads are invisible to Claude and Flow image links need the owner's cookies
  -> the owner downloads Flow / Flow Music files into inbox/ (git-ignored); read pages with get_page_text/find,
  fill with form_input (the pane is tiny; emulate 1280x800 only to reveal hidden buttons).
- Painted Flow art pixelized flat and muddy -> pixelize.py --contrast 1.3 --saturation 1.5 --outline; green-screen
  fringe snaps to G/L (replace with k on subjects without green); check facing before mirroring (art faces right).
- At night, billboards with the moon behind them go black -> a min_light floor in the character shader; Label3D
  text goes muddy in fog and leaves a dark outline when fading -> label_energy > 1, no alpha cut, fade outline too.

## 6. Cheaper routes
- agy 1.1.21 reads rules from GEMINI.md (not .agents/rules/); -p mode denies every shell command despite
  settings.json allow rules -> tools/agy_task.sh (skip-permissions, own worktree outside .claude/) (2026-10-22).
- Where is X: grep docs/MAP.md (generated), not `ls -R`.
