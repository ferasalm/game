# Lessons (curated; symptom -> cause -> fix; dated; max 100 lines; aim ~50; condense back to ~70)
Triage (D9, 10-28): a line a test enforces (deleting it, a FAIL still stops the next chat) -> docs/lessons-archive.md
naming the test; Godot code traps -> .claude/rules/code.md; builder-only -> .claude/skills/builders/lessons.md.

## 1. You can do this yourself
- check.sh `exit code 124` with no FAIL line = the 600 s timeout, not a test (10-19/23); 124/139 with "Parameter mem is null" while other Godot runs are open = memory: rerun first (10-23).
- See a scene without the owner: a `--write-movie` render (players-eye-gate skill). A Node script under `-s` fails
  ("doesn't inherit SceneTree", no autoloads, an ALERT box on the owner's screen) -> render tools run as a .tscn wrapper
  (tools/shot_neon_game.tscn) (2026-10-23).
- Writes into Documents fail as "No such file" even outside the sandbox: Windows Controlled Folder Access is on -> keep
  files elsewhere; Twine's library moved via %APPDATA%/Twine/app-prefs.json storyLibraryFolderPath (2026-10-25).

## 2. Godot traps: .claude/rules/code.md (loads with code; build_pipeline pastes it into every builder prompt)

## 3. Process (general; reem-bot and feras-career ones verified there)
- A review run from the main checkout while it was 9 commits behind nearly judged retired docs (the hybrid departments
  existed only on origin) -> a read-only review reads `git show origin/main:<file>` or a fresh worktree (2026-10-28).
- A check that only prints never fails -> every check exits non-zero; probe each new rule with one bad case.
- A harness summary can lie (99.8% party HP: its AI chain-interrupted the boss) -> print one seed's events (2026-10-23).
- A subagent costs 150-290k tokens -> delegate only when the worker reads far more than its brief.
- A slow check: `.check/*.log` times showed 82% of tool_tests in 2 files -> time the steps before choosing a fix (2026-10-31).
- A model "hang" sat near `API key expired` in the same run's log -> grep a failed run's log for ERROR before probing (2026-10-31).
- A superseded rule lives on in a doc or prompt string -> grep for it when a decision changes.
- Gemini research contains invented numbers -> ideas and norms only, never facts.
- A skill with `paths:` frontmatter (flow-media, 3d-model, sprite-bake, players-eye-gate) is not in a chat's skill list
  until it touches a matching file -> the department brief says Read .claude/skills/<name>/SKILL.md (2026-10-28).
- Scratchpad scripts vanish when the session ends (bake_all.sh was nearly lost) -> any script worth rerunning goes into tools/ with a test (2026-10-27).
- An approved design with no brief was never built (rydan-moves.md) -> brief it the same day (2026-10-23).
- Background runs: `python - <<EOF < /dev/null` spun in an empty REPL, `cmd | grep` hid a crash (exit 0), agy, opencode
  and ffmpeg hung on stdin (20-25 min lost) -> script files, `< /dev/null`, ffmpeg `-nostdin`, `set -o pipefail`, child
  timeouts; check each job at its expected end (2026-10-25).
- Editing tools/build_pipeline.sh while two runs used it crashed both after their build ("syntax error near `)'",
  line 98): bash reads a script as it runs -> never edit a tool a live run executes; re-gate with SKIP_BUILD=1 (2026-10-30).
- "Builder hung / reviewer printed nothing" twice had silent causes: opencode's spent free quota (exit 0, no text) and
  Workers AI DeepSeek thinking past the 32k cap -> first probe with `--print-logs` and `--format json` (finish reason,
  tokens) before blaming the model (2026-10-30).
- A new tool version breaks silently (opencode v2) -> back up its data dirs, probe in a throwaway repo (2026-10-30).
- 4 paid probes crashed at their spend-log line (a path wrong in worktrees) -> one smoke call before a batch; results print first; parallel Bash = run_in_background (2026-10-31).
- Bash `VAR=x cmd` given to Feras failed in his PowerShell -> his commands are PowerShell (2026-10-31).
- `claude -p "/x"` from Git Bash turned the command into a path -> `MSYS_NO_PATHCONV=1` (2026-10-31).
- A toy test failed 1 run in 3 and going serial did not cure it: stub setup outlasted IDLE_SEC=3 -> find the race first; fix the stub, never the limit (2026-10-31).
- `/subtask` looked absent (no repo or plugin hit) but is a CLI built-in only a person can type; "PM plugins need sign-ups" came from memory and was false -> check the docs commands page and the plugin directory cache before saying a tool does or doesn't exist (2026-10-31).
- Auto mode refused a `.claude/settings.json` allow list as self-modification -> never script around it; ask Feras with the exact diff (2026-10-31).
- `check.sh | tail && git commit` committed a failing run -> grep .check/*.log for FAIL first; never push before reading the
  final check line (2026-10-23).

## 4. Worktrees and hooks (Claude chats)
- `cd` into another worktree moves the session's directory -> `git -C <path>`, or absolute paths in a read (2026-10-21; again 10-31).
- A worktree-isolated session's Bash refuses git on any other worktree (even `git worktree remove`) -> one PowerShell call from C:\dev\game (2026-10-31).
- A fresh worktree's first import can crash (exit 139) at 1.8 GB free and also at 6.9 GB free (reem_kufi.ttf, 10-28);
  a second import passes. A crashed import leaves
  `*.import<digits>.tmp` files in assets/, which test_asset_manifest reports as unlisted -> delete them, rerun
  `tools/run_godot.sh --import` alone, then check.sh (2026-10-27/28).
- Python on Windows writes CRLF -> `newline="\n"` (python is `python` here, not python3). The Bash tool collapses every `\\` to `\` anywhere in a command, even in single quotes (probed 10-31), so `\\n` reaches Python as a newline: write such code with Write/Edit; heredoc_guard blocks it (10-27, 10-31).
- A worktree-isolated session refuses a Bash call that starts powershell, or whose text names git in a complex form
  -> free memory: `bash tools/slots.sh`; edit text naming git with Edit; under the 3 GB floor a docs-only change runs
  `bash tools/check.sh --no-godot` (2026-10-28).
