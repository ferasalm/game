# Lessons (curated; symptom -> cause -> fix; dated; max 80 lines)

## 1. You can do this yourself
- Run Godot headless with tools/run_godot.sh: it fails on any SCRIPT ERROR or ERROR line even when Godot exits 0
  (2026-10-19).

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
- See a scene without the owner: non-headless `"$(tools/godot.sh)" --path . --write-movie DIR/f.png --fixed-fps 60
  --quit-after N [scene]`, then view 1-2 frames scaled to 640x360 with Pillow (2026-10-21).

## 3. From reem-bot and feras-career (verified there)
- A check that only prints never fails -> every check exits non-zero; probe each new rule with one bad case.
- A subagent costs 150-290k tokens -> delegate only when the worker reads far more than its brief (reem-bot).
- A superseded rule lives on in a doc or prompt string -> grep for it when a decision changes (reem-bot).
- Gemini research contains invented numbers -> ideas and norms only, never facts (feras-career; here too).

## 4. Parallel builders (2026-10-21)
- One worktree per builder agent (Agent isolation "worktree"; tools/godot.sh finds the exe in the main checkout);
  shared registries (ContentDB KINDS, DefReader) conflict on merge but resolve by keeping both sides; one CSV per
  feature avoids text conflicts. Give each brief exact APIs so builders can run at the same time.
- MAP.md regenerated mid-merge listed conflicted files twice; local check passed, CI failed -> map.py dedupes;
  regenerate after `git add`. Check CI (`gh run list`) after merging to main.
- A side chat editing the same checkout blocked a merge -> one session owns git; others message it.
- Python's write_text on Windows writes CRLF -> pass newline="
" (python is `python` here, not python3).
- The Read(**/*.import) deny also blocks an agent's Write to an existing .import -> the lead writes new
  "keep" .import files before Godot's import runs.
- Builders missed the session's commits: Agent worktrees branch from main, not the lead's branch -> every brief
  starts with `git merge --ff-only <session branch>`; resume a builder with SendMessage (its worktree keeps work).
- After a merge adds class_names, tests fail with "Could not find type" -> `tools/run_godot.sh --import` first.
- The 5-hour limit kills background builders mid-edit -> ask for WIP commits early. Near the limit: builders write
  WIP_NOTES.md + commit, the lead hands off; after the reset start a NEW chat and FRESH agents from the notes
  (resuming a long chat or agent re-sends its whole transcript uncached once the cache TTL expired) (2026-10-21).
- Four agents died at once on API errors (ECONNRESET/timeout) -> SendMessage resumed them with work intact (2026-10-21).
- Entering plan mode in the lead paused every background builder (no edits, no commits) -> enter plan mode only
  while no builders run, or have them WIP-commit first (2026-10-21).
- lint_gd linted .claude/worktrees, so builders' unfinished code failed the lead's check -> lint skips .claude/
  (2026-10-21).
- `cd` into a worktree in the Bash tool moved the session's working directory -> use `git -C <path>` (2026-10-21).
- A crash cut a builder off one unit from done -> a small fresh agent in that worktree (no isolation) finished it
  cheaper than resuming the long transcript (2026-10-21).
- B4 "needed a builder" but was one tuning pass from done -> run check.sh in a WIP worktree and grep its spec
  first; the lead finishes small remainders (2026-10-22).

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
