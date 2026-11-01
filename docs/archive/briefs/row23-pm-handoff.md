# Row 23: pm plugin and one-call handoff (chat brief; rules: docs/briefs/system-v3.md)
Department: Ops. Model: Sonnet high, auto mode. Skills: builders. Persona: none.
Goal: tracking and hand-off are scripts, so Feras sees one board and /handoff costs 4 calls or fewer.
Read: docs/briefs/system-v3.md, this file, the builders skill, the handoff skill, docs/briefs/row22-probe.md. Grep for the rest.
May edit: `plugins/`, `tools/`, `.gitattributes`, `.claude/skills/handoff/`, `.claude/settings.json`, `docs/runs.csv`, tool-neutral words in CLAUDE.md, WORKFLOW and skills.
Do NOT edit: `features/`, `core/`, `content/`, `assets/`, `.agents/skills/`, `.claude/rules/code.md`, row 22's plugin files beyond adding to them. HANDOFF's format: doc_check keeps reading it unchanged.

## Parts (a, b and c run side by side, one builder each, all `RUN_KIND=py`. You write each failing test first. d and e after them.)
a. agy: `plugins/pm/scripts/pm.py`, tests `tools/test_pm.py` on a copy of the real HANDOFF.md.
   - `board`: top 5 queue rows, Open points, This week, Feras's moves. `next`: the top row and the paste-ready prompt.
   - `row add|set|done`: edits the queue, runs doc_check, restores the file if doc_check fails.
   - `week`: the week table as "Your moves today:" lists, one per day, for the calendar.
   - `report`: rewrites BRIEFING's "Open now" table from HANDOFF.
   - Skills `plugins/pm/skills/{status,next,row,week,report}/SKILL.md`, 15 lines or fewer each, only calling the script.
b. cf max: `tools/handoff.sh "<commit message>" [--main]`: map, doc_check, check.sh, commit, push, CI result with `--main`; prints `HANDOFF PASS` or `HANDOFF FAIL <step>`. Stops at the first failing exit code; never a pipe that hides one (LESSONS). Default target is the current branch; only `--main` touches main. Test `tools/test_handoff.py` in a throwaway repo with a stub check. Then move the skill to `plugins/pm/skills/handoff/SKILL.md`: decisions, lessons and the report stay Claude's; every mechanical step is the script.
c. agy: `python tools/session_stats.py --row <session id>` prints a USAGE row with calls, cache reads, model and context; Claude fills task, result and Kaizen. `docs/runs.csv` (date, task, worker, effort, gate, fix passes, minutes, cost, real findings), appended by the pipeline, `merge=union` in `.gitattributes`. It edits build_pipeline: no build may be running then.
d. cf fast: helpers that stop guard refusals: `tools/main_file.sh <path>` prints a file from origin/main; `tools/merge_base.sh [branch]` fetches and fast-forwards. CLAUDE.md names them in one line. Test each.
e. Status line: first dump its real stdin JSON and confirm the field names (the CLI holds five_hour and seven_day; nothing else is proven). `tools/statusline.py` prints one line and writes `.check/usage.json`; token_handoff reads it. Replace `get_usage`, `get_session`, `SendUserFile` wording with tool-neutral rules: "the status line, or Feras's /usage"; keep review_gate's matcher working. Wiring goes in `.claude/settings.json`: if auto mode refuses, ask Feras with the exact line.

## Stop rules
Auto mode refuses a change: stop, ask Feras with the exact diff. Same step failed twice: call the advisor. 3 rounds on one problem: report. Budget: 80 main-chat calls. Late: d, then e's rewording, park first.

## Done when
`bash tools/check.sh` all passed and read; `claude plugin validate plugins/pm --strict` passes; `/pm:status` and `/pm:next` run in a fresh chat; this chat's own /handoff uses the new door in 4 calls or fewer, on `system-v3`; pushed.

## Report
15 lines or fewer: parts with status, runs with their one-line results, the /handoff call count, questions for Feras. No merge to main, no sync; row 23 done, row 24 next; the next prompt ready to paste.
