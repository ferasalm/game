# Brief: row23b-handoff (HANDOFF row 23, part b)
You are in your own worktree on branch oc/row23b-handoff (made from origin/system-v3; the base is pushed). Follow GEMINI.md, including
<review_misses>. Load the minimal-change-engineer skill (build_pipeline.sh pastes it; our rules outrank its text).
Pattern: tools/sync_main.sh, tools/status.sh
Timebox: 45 min. First commit within 15 min, then small WIP commits: no commit for 25 min (IDLE_MIN) = NOWORK.

## Why
Feras 11-01: /handoff costs 4 calls or fewer, because every mechanical step is one script. Pillar: process.

## Read first
tools/test_handoff.py (read-only; make it green), .claude/skills/handoff/SKILL.md (the text to move), tools/lib.sh (style only), LESSONS lines
"check.sh | tail && git commit" and "Python on Windows writes CRLF". Read nothing else.

## What to build
1. `tools/handoff.sh "<commit message>" [--main]` (bash, `set -uo pipefail`, no `eval`, no pipe that hides an exit code). No message: print
   `Usage: ...` and exit 2. Work from `git rev-parse --show-toplevel`. Steps in this order, each printing `== <step>`:
   `map` = `python tools/map.py`; `doc_check` = `python tools/doc_check.py`; `check` = `bash tools/check.sh` (print its last 15 lines; on failure
   also every line containing FAIL); `commit` = `git add -A`, then `git commit -m "$msg"` (the message is used verbatim, multi-line allowed); no
   change: print `nothing to commit` and go on; `push` = `git push -u origin HEAD` (a detached HEAD fails here); with `--main` after it
   `git push origin HEAD:main`; `ci` (only with `--main`) = run `${HANDOFF_CI:-gh run list --branch main --limit 1 --json conclusion -q '.[0].conclusion'}`
   through bash -c and require the single word `success` (a CI run still in progress: poll every 20 s up to 10 min).
2. The first non-zero step stops the run: print `HANDOFF FAIL <step>` (step names: map, doc_check, check, commit, push, ci) as the LAST line and exit 1.
   All good: last line `HANDOFF PASS`, exit 0. Only `--main` ever touches main; the default target is the current branch.
3. Move the skill: create `plugins/pm/skills/handoff/SKILL.md` (60 lines or fewer, frontmatter name `handoff` and the same description): keep
   the steps that are Claude's (decisions to docs/decisions-log.md and DECISIONS, lessons, the USAGE row via `python tools/session_stats.py --row <id>`,
   queue rows via `python ${CLAUDE_PLUGIN_ROOT}/scripts/pm.py row ...`, BRIEFING via `pm.py report`, the 5-part report, calendar update); replace every
   mechanical step (map, doc_check, check, commit, push, CI) by one call: `bash tools/handoff.sh "<message>" [--main]` and read its last line. Keep all
   rules (Open points closed or carried, status words, sync_main after a push to main).
4. Replace `.claude/skills/handoff/SKILL.md` with a pointer of 8 lines or fewer (same frontmatter) that says: read and follow
   plugins/pm/skills/handoff/SKILL.md (the plugin loads from main only after row 25; this stub goes then).

## Do NOT edit
D6 defaults, protected by tools/build_gate.py without being listed: existing tests, tools/, .github/, plugins/ (edits and
deletions; new test files are allowed) and every change under assets/ (incl. *.import). Keep this prose free of
backticks: every backticked token in this section is a forbidden path, and May edit does not lift it.
`tools/test_handoff.py`
`tools/check.sh`
`features/`
`core/`
`plugins/studio/`
`plugins/pm/scripts/`

## May edit
`tools/handoff.sh`
`plugins/pm/skills/handoff/`
`.claude/skills/handoff/`

## Ripple
none beyond the skill move: nothing calls handoff.sh yet; the old skill path stays valid as a pointer so /handoff keeps working until row 25.

## Pre-mortem
1. A failing check is hidden by a pipe and committed (the LESSONS case): no pipe, test_each_failing_step. 2. A non-main push reaches main: test_pass_... checks origin main. 3. A message with quotes breaks: passed as one argument, multi-line test.

## Tests
`tools/test_handoff.py` (red on the base): pass path, each failing step, `--main` with CI success and failure, nothing to commit, detached HEAD, usage, skill move.

## Checklist
- file: tools/handoff.sh
- file: plugins/pm/skills/handoff/SKILL.md
- test: tools/test_handoff.py :: test_each_failing_step_stops_the_run_and_names_itself

## Proof
`RUN_KIND=py`; `bash tools/check.sh --no-godot` raw last 15 lines; final message ends with
`Built-by: <model> (opencode)`.
