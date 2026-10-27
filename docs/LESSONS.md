# Lessons (curated; symptom -> cause -> fix; dated; max 100 lines; aim ~50; condense back to ~70)

## 1. You can do this yourself
- check.sh `exit code 124` with no FAIL line = the 600 s timeout, not a test (10-19/23); 124/139 with "Parameter mem is null" while other Godot runs are open = memory: rerun first (10-23).
- See a scene without the owner: a `--write-movie` render (players-eye-gate skill). A Node script under `-s` fails
  ("doesn't inherit SceneTree", no autoloads, an ALERT box on the owner's screen) -> render tools run as a .tscn wrapper
  (tools/shot_neon_game.tscn) (2026-10-23).
- Writes into Documents fail as "No such file" even outside the sandbox: Windows Controlled Folder Access is on -> keep
  files elsewhere; Twine's library moved via %APPDATA%/Twine/app-prefs.json storyLibraryFolderPath (2026-10-25).
- Read an Electron app's screen (Twine): PowerShell Start-Process with --remote-debugging-port=N (a bash `&` launch died),
  then node fetch + WebSocket CDP Runtime.evaluate document.body.innerText (2026-10-25).

## 2. Traps (Godot)
- `"abc".contains("")` is false in 4.7 (runner found 0 tests); a `const` Dictionary can't hold class_name refs (use
  preload); `match` is a keyword (`var match` fails) (2026-10-19/22).
- A scene added in a SceneTree script's `_initialize()` has no `_ready()` yet -> tests start from the first `_process()`
  (tests/runner.gd) (2026-10-19).
- A test with a runtime error still counts as passed: run_godot.sh fails only on a SCRIPT ERROR/ERROR line though Godot
  exits 0 (headless get_image() prints one -> tests inject the grab, 10-26) -> read the FAIL lines.
- A lambda assigning an outer local changes nothing (captured by value) -> hold it in an Array (2026-10-26).
- Commit every `.uid` and never read it; helper files in tests/ must not start with `test_` (2026-10-19).
- No agent may write *.import -> new text goes into an existing CSV (CSVs use the "keep" importer and TextDB loads them;
  Godot's CSV import breaks a fresh clone, and a test enforces "keep") (2026-10-21/22).
- `move_and_slide` does nothing when `_physics_process` is called by hand -> move_and_collide + slide (2026-10-21).
- Sorting StringNames compares addresses (rows flipped between runs) -> sort by String (2026-10-21).
- load() of a painted .webp returns null when its folder is .gdignore (assets/textures/painted/) -> Image.load_webp_from_buffer (2026-10-23).
- `find_children(pattern, "MyClass")` never matches a script class_name -> walk the children and test `is MyClass` (2026-10-23).
- A UiScreen closed while another covered it stayed frozen (its fade tween pauses with the node) -> close() re-enables processing (2026-10-23).
- A test counting processes by name machine-wide is flaky with parallel checkouts -> mark the test's children (2026-10-27).

## 3. Process (general; reem-bot and feras-career ones verified there)
- A check that only prints never fails -> every check exits non-zero; probe each new rule with one bad case.
- A harness summary can lie (99.8% party HP: its AI chain-interrupted the boss) -> print one seed's events (2026-10-23).
- A subagent costs 150-290k tokens -> delegate only when the worker reads far more than its brief.
- Audit cost: 3 Haiku audits at max effort reading whole doc sets cost ~15% of a 5-hour window -> narrow briefs, Haiku high (calibrated), exact files and an output template (2026-10-27).
- A superseded rule lives on in a doc or prompt string -> grep for it when a decision changes.
- Gemini research contains invented numbers -> ideas and norms only, never facts.
- Where is X: grep docs/MAP.md (generated), not `ls -R`; map.py lists untracked files too: with the marketing-* files in the checkout CI failed "MAP.md current" -> regenerate in a clean worktree before main (2026-10-26).
- Scratchpad scripts vanish when the session ends (bake_all.sh was nearly lost) -> any script worth rerunning goes into tools/ with a test (2026-10-27).
- An approved design with no brief was never built (rydan-moves.md) -> brief it the same day (2026-10-23).
- `python - <<EOF < /dev/null` gave Python no script: it spun in an empty REPL -> script files for background runs; `cmd | grep` hid a crash (exit 0) -> `set -o pipefail` (2026-10-25).
- `check.sh | tail && git commit` committed a failing run -> grep .check/*.log for FAIL first; never push before reading the
  final check line (2026-10-23).
- Silent stdin hangs (agy, opencode, ffmpeg: 20-25 min lost) -> `< /dev/null`, ffmpeg `-nostdin`, child timeouts, progress;
  check background jobs at their expected end (2026-10-25).

## 4. Parallel builders and worktrees (Claude agents 2026-10-21; agy 2026-10-22)
- A pull into C:/dev/game without an import: the game did not run (stale class cache) -> `bash tools/sync_main.sh` after every pull (2026-10-24).
- One session owns git in C:\dev\game; others message it for the window. `cd` into a worktree moves the session's directory -> `git -C <path>`.
- The SessionStart hook read the main checkout ($CLAUDE_PROJECT_DIR), not the worktree -> it uses $PWD (P1.8) (2026-10-27).
- tools/slots.sh counted 0 runs from a worktree (it looked for game-wt relative to the checkout) -> it finds C:/dev/game-wt from any worktree (P1.2, test_slots.py) (2026-10-27).
- Python on Windows writes CRLF -> `newline="\n"` (python is `python` here, not python3). A `\\n` in a Bash-tool heredoc/sed arrives as a real newline: write such code with Write/Edit (2026-10-27).
