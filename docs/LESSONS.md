# Lessons (curated; symptom -> cause -> fix; dated; max 100 lines; condense back to ~70)

## 1. You can do this yourself
- tools/run_godot.sh fails on any SCRIPT ERROR or ERROR line even when Godot exits 0 (2026-10-19). check.sh "tests
  FAIL" with `exit code 124` and no FAIL line = the 600 s timeout, not a test (2026-10-23).
- See a scene without the owner: non-headless `"$(tools/godot.sh)" --path . --write-movie DIR/f.png --fixed-fps 60
  --quit-after N [scene]`, view 1-2 frames at 640x360 with Pillow (2026-10-21). A Node script under `-s` fails ("doesn't
  inherit SceneTree", no autoloads, an ALERT box on the owner's screen) -> render tools run as a .tscn wrapper
  (tools/shot_dialogue.tscn) (2026-10-23).

## 2. Traps (Godot)
- `"abc".contains("")` is false in 4.7 (runner found 0 tests); a `const` Dictionary can't hold class_name refs (use
  preload); `match` is a keyword (`var match` fails) (2026-10-19/22).
- A scene added in a SceneTree script's `_initialize()` has no `_ready()` yet -> tests start from the first
  `_process()` (tests/runner.gd) (2026-10-19).
- A test with a runtime error still counts as passed; only the SCRIPT ERROR line fails the run -> read FAIL lines.
- Commit every `.uid`, never read them; helper files in tests/ must not start with `test_` (2026-10-19).
- No agent may write *.import -> new text goes into an existing CSV; CSVs use the "keep" importer and TextDB loads
  them (Godot's CSV import breaks a fresh clone; a test enforces "keep") (2026-10-21/22).
- `move_and_slide` does nothing when `_physics_process` is called by hand -> move_and_collide + slide (2026-10-21).
- Sorting StringNames compares addresses (rows flipped between runs) -> sort by String (2026-10-21).
- Headless MultiMesh returns identity transforms -> keep them in node meta for tests (2026-10-21).
- load() of a painted .webp returns null: assets/textures/painted/ is .gdignore -> Image.load_webp_from_buffer
  (PaintedMaterials, ModelMaterials.load_texture) (2026-10-23).
- `find_children(pattern, "MyClass")` never matches a script class_name -> walk children, test `is MyClass` (2026-10-23).
- A UiScreen closed while another covered it stayed frozen on screen (its fade tween is paused with the node) ->
  close() re-enables processing (2026-10-23).
- Lathe garments: torso pieces end at the waist over pelvis pieces raised 0.15 m; coats split at the pelvis (2026-10-22).
- Rodin glb: centred feet, other bone axes, stale buffers, props baked into the body -> tools/rodin (LOD indices, glb
  rewrite: lift, strip, --press) and PoseFollow (runtime retarget) (2026-10-22).
- Foot heights after seek in a SceneTree script: set bones from the tracks, compose get_bone_pose up the parents.
- SurfaceBuffer boxes have no bottom face -> lids need a tilted lining part (2026-10-23).
- Play-camera traps: a keeper behind his stall hid under the awning (StallKeeper: counter end); the follow camera
  sat 8-10 m back leading along the facing (lead along the view direction) (2026-10-23).
- set_exploring(false) hides the player and patrols -> talks use rooftop.freeze_actors (2026-10-22).
- A new area reusing the old mist ids drowned its lower roofs in fog -> mist per area, >= 2 m below its lowest floor
  (2026-10-23).
- Harness said 99.8% party HP: its AI chain-interrupted the boss -> print one seed's events (2026-10-23).

## 3. From reem-bot and feras-career (verified there)
- A check that only prints never fails -> every check exits non-zero; probe each new rule with one bad case.
- A subagent costs 150-290k tokens -> delegate only when the worker reads far more than its brief.
- A superseded rule lives on in a doc or prompt string -> grep for it when a decision changes.
- Gemini research contains invented numbers -> ideas and norms only, never facts.

## 4. Parallel builders (Claude agents 2026-10-21; agy 2026-10-22)
- One worktree per builder; registries (ContentDB KINDS, MAP.md) conflict -> keep both sides, regenerate MAP.md;
  after a merge adds class_names run `tools/run_godot.sh --import` first; check CI (`gh run list`) after main.
- One session owns git in C:\dev\game; others message it for the window. `cd` into a worktree moves the session's
  directory -> `git -C <path>`.
- Python on Windows writes CRLF -> `newline="\n"` (python is `python` here, not python3).
- Parallel worktrees shared user:// -> per-checkout test save dir (2026-10-22). `check.sh | tail && git commit`
  committed a failing run -> grep .check/*.log for FAIL first.
- agy passes check.sh yet misses what a player sees -> GEMINI.md review_misses + tools/agy_review.sh (2026-10-22).
- agy is not creative (owner): a described look (herbs, a sabil) came back as cones and gems -> creative briefs give
  geometry recipes with numbers, colours and the concept path; judge renders from the play camera (2026-10-23).
- An approved design with no brief was never built (zayd-moves.md) -> brief it the same day (2026-10-23).
- Builders said "done" with failing tests or died mid-edit -> tools/build_pipeline.sh (leftovers as WIP, check, one
  free fix pass); PASS with no commits = nothing built; read fix-pass test diffs (one hardcoded a value) (2026-10-23).
- Editing a running .sh broke the running copy (bash reads as it goes) -> never edit tools/*.sh mid-run (2026-10-23).
- Builder stdin: agy exited 2, opencode hung 25 min -> `< /dev/null`. Inkling read outside its worktree and quit 3x
  -> that brief went to agy (2026-10-23).
- OpenRouter :free = 50 requests/day under $10 bought credit, shared by Inkling and all :free models (2026-10-23).
- 4 opencode + 2 agy + Godot hit the 16 GB commit limit (fork failed) -> <= 3 runs; check free memory (2026-10-23).

- opencode Inkling on balance-gear ran the harness, hit permission rejections and committed nothing (the WIP commits were empty) -> `git diff base...branch` empty = nothing built; rerun on agy (2026-10-23).
- check.sh failed once on `exit code 124` and once on exit 139 ("Parameter mem is null" = out of memory) while other Godot runs were open; the failing test passed alone and the rerun was green -> rerun before debugging; and never push before reading the final check line (2026-10-23).

## 5. Art, browser, night look (2026-10-21)
- "3 FPS" was a --write-movie render -> real FPS only via fps_probe.gd.
- The browser pane's downloads are invisible to Claude; Flow links need the owner's cookies -> he saves files to
  inbox/ (git-ignored); pictures pasted in chat are not on disk -> ask him to save them (2026-10-23).
- Painted Flow art pixelized muddy -> pixelize.py --contrast 1.3 --saturation 1.5 --outline; check facing first.
- Night billboards with the moon behind go black -> min_light floor; Label3D in fog -> label_energy > 1, no alpha cut.
- Storm rain at 1.5 cm streaks was sub-pixel, and a lightning light barely shows through the painted shaders ->
  2.4 cm streaks and a screen wash (storm.json) (2026-10-23).

## 6. Cheaper routes
- agy reads GEMINI.md; -p mode denies shell commands -> tools/agy_task.sh (skip-permissions, own worktree).
- Where is X: grep docs/MAP.md (generated), not `ls -R`.
- opencode CLI 1.19.4: `npm install -g --allow-scripts=opencode-ai opencode-ai`; the desktop app owns
  ~/.local/share/opencode -> the CLI uses XDG_DATA_HOME=~/.local/share/oc-cli (tools/oc_task.sh) (2026-10-23).
- opencode "Free usage limit reached" (GLM, DeepSeek share it) then `opencode run` hangs -> read
  ~/.local/share/oc-cli/opencode/log, kill the CLI's PID only (OpenCode.exe is the app) (2026-10-23).
- With an OpenRouter key opencode chose a PAID title model -> small_model pinned :free; laguna is missing from
  opencode's catalogue; Inkling :free works only inside agents (403 on the MCP) (2026-10-23).
