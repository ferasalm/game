# Builder lessons (seed: docs/LESSONS.md section 4; add dated lines here, keep <= 40)
- One worktree per builder; registries (ContentDB KINDS, MAP.md) conflict: keep both sides, regenerate MAP.md (2026-10-21).
- Builders said "done" with failing tests or died mid-edit: build_pipeline.sh keeps leftovers as WIP, checks, one free fix pass; PASS with no commits = nothing built (2026-10-23).
- agy passes check.sh yet misses what a player sees: GEMINI.md review_misses + player lens on renders (2026-10-22).
- agy is not creative: briefs give geometry recipes with numbers, colours and the concept path (2026-10-23).
- A builder rewired a signal and its old listener went dead: Ripple lists every listener/key/id; review-code greps them (2026-10-24).
- Editing a running .sh broke the running copy: never edit tools/*.sh mid-run (2026-10-23).
- Fork from origin/<base>: push the base before a launch (a fix run started on old code) (2026-10-26).
- Free calibrated lens: nemotron-3-ultra :free found 6/6 planted defects; free models failed the reader gold set (2026-10-27).
- After a merge adds class_names run `tools/run_godot.sh --import` first (exit 139 = memory, rerun); check CI (`gh run list`) after main (2026-10-21).
- Parallel worktrees shared user:// -> per-checkout test save dir (2026-10-22).
- Commit memory: 4 runs + Godot left 10 MB free (fork errors, Godot exit 132, the desktop app froze) -> <= 2-3 runs, no own Godot while builders test; check FreeVirtualMemory (2026-10-23, 10-26).
- agy sat 55 min on baseline checks with no code -> on the critical path write it yourself (2026-10-26).
- agy reads GEMINI.md; -p mode denies shell commands -> tools/agy_task.sh (skip-permissions, own worktree).
- opencode CLI 1.19.4: `npm install -g --allow-scripts=opencode-ai opencode-ai`; the desktop app owns ~/.local/share/opencode -> the CLI uses XDG_DATA_HOME=~/.local/share/oc-cli (tools/oc_task.sh) (2026-10-23).
- opencode quit on reads outside its worktree -> opencode.json external_directory allows inbox/ (2026-10-24).
- Two opencode runs started in the same second: one died "database is locked" (shared oc-cli data dir) -> launch runs 30 s apart (2026-10-26).
- Retiring code: an import-graph script (res://, uid://, class_name, ContentDB kinds) gave each run an exact delete list; a brief that allows cross-run deletions must not list those paths as Do NOT edit (2026-10-26).
- A nohup builder is not in the app's task list: watch its .result (2026-10-27).
- msys exec of an msys program = a new Windows process whose parent (the fork) exits: Windows-tree kills miss it -> freeze the tree before killing and join msys `ps` (PID, PPID, WINPID) to the Windows snapshot (tools/kill_tree.py) (2026-10-27).
- Cross-review calibration (row 12, 2026-10-28; D11): agy reviews cf's hook diff `git diff 152f962 783eefd` with the
  brief as cf saw it (152f962), one-shot from an empty folder (no repo, so no `git log` to 5008b5d), packet =
  tools/cross_review_prompt.md + brief + diff + code-reviewer skill + code rules. Scoring, fixed before reading: found =
  the right file and the mechanism of one key bug (a-e, docs/briefs/cross-review.md); real = Opus confirms it against
  783eefd. On: >= 3/5 found and most findings real; else tune the prompt once and rerun.
  Run 1 (agy, ~3 min, format valid): 2/5 found, a (warnings repeat while a compaction sits in the window) and b
  (fallback counts pre-compaction text); 9 findings, ~6 real (anchor-less f\d{8} regex, ../ escapes the exempt
  folder, main() 56 lines, null usage fields; 2 not real, 1 cosmetic). Missed c and d, which were bugs in the brief
  (the code followed it), and e, which lives in the wiring outside the diff. Tune: question the brief (legit inputs,
  every caller shape) and the wiring (fail open or closed when the file is missing).
  Run 2 (tuned prompt, ~8 min): 3/5 found (b; c inbox documents; d files as a list of strings), a dropped, e never
  found; 12 findings, ~8 real (by-design flags: the Flow folder exemption, fail-open on errors). Verdict: agy is ON as
  the cross-reviewer of DeepSeek-built runs; recall varies run to run (union 4/5), so Opus still reads the risky hunks.
  DeepSeek reviewing agy-built runs is uncalibrated: provisional, Opus reads the whole diff until it is calibrated.
- agy's first Python run (row 12 C, 10-28): PASS in ~40 min, +69 lines over 5 tools; Opus fixed 3: a bash function
  called before its definition (an untested refusal path), BREACH filtered into FAIL (Claude's red test demanded FAIL
  for an assets/ edit: a red test can force a wrong design, so test verdict precedence too) and a fix-pass prompt
  that ran Godot in a py run. Brief every refusal path with a test.
- Race B (row 12, 10-28; parser brief, py run): agy and cf each made a first commit in 17-20 min and both parsers passed the 7 red tests, but both runs then burned ~70 min of fix passes on a pipeline leak (RUN_KIND=py reached test_build_pipeline); cf "fixed" it in protected check.sh = BREACH, agy PASSed once re-gated. Cross-review gave 0/2 usable blocks (agy headless denies its tools without --dangerously-skip-permissions; DeepSeek explored 520 s and wrote no block); Opus found 2 real bugs (non-UTF-8 log crash, CRLF out). Verdict: no races for now; one builder + Opus review is cheaper (2026-10-28).
