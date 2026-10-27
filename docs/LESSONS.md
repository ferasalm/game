# Lessons (curated; symptom -> cause -> fix; dated; max 100 lines; condense back to ~70)

## 1. You can do this yourself
- run_godot.sh fails on any SCRIPT ERROR/ERROR line though Godot exits 0 (headless get_image() prints one -> tests
  inject the grab, 10-26); check.sh `exit code 124` and no FAIL line = the 600 s timeout, not a test (10-19/23).
- See a scene without the owner: non-headless `"$(tools/godot.sh)" --path . --write-movie DIR/f.png --fixed-fps 60
  --quit-after N [scene]`, view 1-2 frames at 640x360 with Pillow (2026-10-21). A Node script under `-s` fails
  ("doesn't inherit SceneTree", no autoloads, an ALERT box on the owner's screen) -> render tools run as a .tscn
  wrapper (tools/shot_neon_game.tscn) (2026-10-23).
- Writes into Documents fail as "No such file" even outside the sandbox: Windows Controlled Folder Access is on ->
  keep files elsewhere; Twine's library moved via %APPDATA%/Twine/app-prefs.json storyLibraryFolderPath (2026-10-25).
- Read an Electron app's screen (Twine): PowerShell Start-Process with --remote-debugging-port=N (a bash `&` launch
  died), then node fetch + WebSocket CDP Runtime.evaluate document.body.innerText (2026-10-25).

## 2. Traps (Godot)
- `"abc".contains("")` is false in 4.7 (runner found 0 tests); a `const` Dictionary can't hold class_name refs (use
  preload); `match` is a keyword (`var match` fails) (2026-10-19/22).
- A scene added in a SceneTree script's `_initialize()` has no `_ready()` yet -> tests start from the first
  `_process()` (tests/runner.gd) (2026-10-19).
- A test with a runtime error still counts as passed; only the SCRIPT ERROR line fails the run -> read the FAIL lines.
- A lambda assigning an outer local changes nothing (captured by value) -> hold it in an Array (2026-10-26).
- Commit every `.uid` and never read it; helper files in tests/ must not start with `test_` (2026-10-19).
- No agent may write *.import -> new text goes into an existing CSV (CSVs use the "keep" importer and TextDB loads
  them; Godot's CSV import breaks a fresh clone, and a test enforces "keep") (2026-10-21/22).
- `move_and_slide` does nothing when `_physics_process` is called by hand -> move_and_collide + slide (2026-10-21).
- Sorting StringNames compares addresses (rows flipped between runs) -> sort by String (2026-10-21).
- load() of a painted .webp returns null when its folder is .gdignore (assets/textures/painted/) ->
  Image.load_webp_from_buffer (2026-10-23).
- `find_children(pattern, "MyClass")` never matches a script class_name -> walk the children and test `is MyClass`
  (2026-10-23).
- A UiScreen closed while another covered it stayed frozen (its fade tween pauses with the node) -> close() re-enables
  processing (2026-10-23).
- Harness said 99.8% party HP: its AI chain-interrupted the boss -> print one seed's events (2026-10-23).

## 3. From reem-bot and feras-career (verified there)
- A check that only prints never fails -> every check exits non-zero; probe each new rule with one bad case.
- A subagent costs 150-290k tokens -> delegate only when the worker reads far more than its brief.
- A superseded rule lives on in a doc or prompt string -> grep for it when a decision changes.
- Gemini research contains invented numbers -> ideas and norms only, never facts.

## 4. Parallel builders (Claude agents 2026-10-21; agy 2026-10-22)
- One worktree per builder; registries (ContentDB KINDS, MAP.md) conflict -> keep both sides, regenerate MAP.md; after
  a merge adds class_names run `tools/run_godot.sh --import` first (exit 139 = memory, rerun); check CI (`gh run list`) after main.
- A pull into C:/dev/game without an import: the game did not run (stale class cache) -> `bash tools/sync_main.sh`
  after every pull (2026-10-24).
- A builder rewired a signal and its old listener went dead; gate, tests and review passed -> audits trace rewired
  signals to their old listeners (2026-10-24).
- One session owns git in C:\dev\game; others message it for the window. `cd` into a worktree moves the session's
  directory -> `git -C <path>`.
- Python on Windows writes CRLF -> `newline="\n"` (python is `python` here, not python3). A `\\n` in a Bash-tool heredoc/sed arrives as a real newline: write such code with Write/Edit (2026-10-27).
- Parallel worktrees shared user:// -> per-checkout test save dir (2026-10-22). `check.sh | tail && git commit`
  committed a failing run -> grep .check/*.log for FAIL first.
- agy passes check.sh yet misses what a player sees -> GEMINI.md review_misses + tools/agy_review.sh (2026-10-22).
- agy is not creative (owner): a described look (herbs, a sabil) came back as cones and gems -> creative briefs give
  geometry recipes with numbers, colours and the concept path; judge renders from the play camera (2026-10-23).
- An approved design with no brief was never built (zayd-moves.md) -> brief it the same day (2026-10-23).
- Builders said "done" with failing tests or died mid-edit -> tools/build_pipeline.sh (leftovers as WIP, check, one
  free fix pass); PASS with no commits = nothing built; read fix-pass test diffs (one hardcoded a value) (2026-10-23).
- Editing a running .sh broke the running copy (bash reads as it goes) -> never edit tools/*.sh mid-run (2026-10-23).
- Silent stdin hangs: agy, opencode (25 min), an ffmpeg render (22 min) -> `< /dev/null`, ffmpeg `-nostdin`, child
  timeouts, progress; check background jobs at their expected end (2026-10-25); a `nohup` builder is not in the app's task list: watch its .result (2026-10-27).
- `python - <<EOF < /dev/null` gave Python no script: it spun in an empty REPL -> script files for background runs;
  `cmd | grep` hid a crash (exit 0) -> `set -o pipefail`. lru_cache of 1280x720 float layers hit MemoryError at
  ~4 GB -> cache uint8 or a few entries (2026-10-25).
- opencode quit on reads outside its worktree -> opencode.json external_directory allows inbox/ (2026-10-24).
- OpenRouter :free = 50 requests/day under $10 bought credit, shared by Inkling and all :free models (2026-10-23).
- Commit memory: 4 runs + Godot left 10 MB free (fork errors, Godot exit 132, the desktop app froze) -> <= 2-3 runs,
  no own Godot while builders test; check FreeVirtualMemory (2026-10-23, 10-26). check.sh
  exit 124/139 ("Parameter mem is null") with other Godot runs open = memory, not a test -> rerun first; never push
  before reading the final check line (2026-10-23).
- Inkling on balance-gear hit permission rejections, committed nothing -> empty `git diff base...branch`: rerun on agy
  (2026-10-23).
- Two opencode runs started in the same second: one died "database is locked" (shared oc-cli data dir) -> launch
  runs 30 s apart. Retiring code: an import-graph script (res://, uid://, class_name, ContentDB kinds) gave each run an
  exact delete list; a brief that allows cross-run deletions must not list those paths as Do NOT edit (2026-10-26).

## 5. Art, browser, night look (2026-10-21)
- "3 FPS" was a --write-movie render -> real FPS only via fps_probe.gd.
- The browser pane's downloads are invisible to Claude; Flow links need the owner's cookies -> he saves files to
  inbox/ (git-ignored); pictures pasted in chat are not on disk -> ask him to save them (2026-10-23).
- Flow from Claude: the browser pane can't download or reach localhost -> Claude in Chrome (his login): upload =
  own <input type=file> + file_upload + a synthetic drop on the grid; download = "Download media" -> 2K -> ~/Downloads;
  the Flow agent picks Nano Banana; 2:3 is refused (1:1, 16:9, 9:16, 4:3, 3:4) (2026-10-26).
- build_pipeline/cf_build fork from origin/<base>: push the base before a launch (a fix run started on old code);
  agy sat 55 min on baseline checks with no code -> on the critical path write it yourself (2026-10-26).
- First import of three 2752x1536 webp: "WebP packing failed", textures load empty -> run --import again (2026-10-26).
- Iso sprites: Rodin rig `ue` = the old 68-bone rig, so ModelRig retargets UAL clips; bake_sprites.tscn renders them
  (ortho, 30 deg, own unshaded ink shader + hull); 256-colour sheets are 1/6 the size (2026-10-26).

## 6. Cheaper routes
- ffmpeg 9 dropped `-filter_complex_script` -> `-/filter_complex file` (2026-10-25).
- agy reads GEMINI.md; -p mode denies shell commands -> tools/agy_task.sh (skip-permissions, own worktree).
- Where is X: grep docs/MAP.md (generated), not `ls -R`. map.py lists untracked files too: with the marketing-* files
  in the checkout CI failed "MAP.md current" -> regenerate in a clean worktree before main (2026-10-26).
- opencode CLI 1.19.4: `npm install -g --allow-scripts=opencode-ai opencode-ai`; the desktop app owns
  ~/.local/share/opencode -> the CLI uses XDG_DATA_HOME=~/.local/share/oc-cli (tools/oc_task.sh) (2026-10-23).
- opencode "Free usage limit reached" (GLM, DeepSeek share it) then `opencode run` hangs -> read
  ~/.local/share/oc-cli/opencode/log, kill the CLI's PID only (OpenCode.exe is the app) (2026-10-23).
- With an OpenRouter key opencode chose a PAID title model -> small_model pinned :free; laguna is missing from
  opencode's catalogue; Inkling :free works only inside agents (403 on the MCP) (2026-10-23).
