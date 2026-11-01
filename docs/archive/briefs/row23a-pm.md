# Brief: row23a-pm (HANDOFF row 23, part a)
You are in your own worktree on branch gemini/row23a-pm (made from origin/system-v3; the base is pushed). Follow GEMINI.md, including
<review_misses>. Load the minimal-change-engineer skill (build_pipeline.sh pastes it; our rules outrank its text).
Pattern: tools/doc_check.py, tools/session_stats.py
Timebox: 45 min. First commit within 15 min, then small WIP commits: no commit for 25 min (IDLE_MIN) = NOWORK.

## Why
Feras 11-01: tracking is a script, so he sees one board and rows change in one call. Pillar: process (combat feel unaffected).

## Read first
tools/test_pm.py (the tests to make green; read-only), HANDOFF.md (the format; doc_check keeps reading it unchanged), tools/doc_check.py
(`table()` shows how tables parse), feras/BRIEFING.md lines 1-20, plugins/studio/.claude-plugin/plugin.json, .claude-plugin/marketplace.json. Read nothing else.

## What to build
1. `plugins/pm/scripts/pm.py` (stdlib only, typed, UTF-8 and LF on write). Global options before the command: `--handoff PATH`
   (default HANDOFF.md at the repo root = three parents up from the script), `--briefing PATH` (default feras/BRIEFING.md).
2. `board` prints four sections, each headed `== Queue`, `== Open points`, `== This week`, `== Your moves`. Queue: the top 5 numbered
   rows as `#N | Dept | task | Who | Status`. Open points: `Point | Owner | Since`. This week: `Day: Plan`. Your moves: queue rows whose
   Lane is Feras (`#N | task | Status`) and Open points owned by Feras.
3. `next` prints the top row (same format as Queue, first line), then the paste-ready prompt on its own line: the text of the last
   line of "## Prompt for the next chat" that starts with a backtick, without the backticks.
4. `row add --task T --dept D --lane L --who W --status S --blocked B [--at N]` appends a row numbered max+1 (or inserts at position N,
   1 = top); `row set N [--task|--dept|--lane|--who|--status|--blocked V]...` changes only the named cells; `row done N` removes the row.
   Unknown row: exit 1, file untouched. After each edit run the command in env `PM_DOC_CHECK` (default
   `python <repo>/tools/doc_check.py`, split with shlex); on a non-zero exit restore the file byte for byte, print the output and a
   line naming doc_check, exit 1.
5. `week` prints, per row of the This week table: the day line, `Your moves today:`, then one `- ` bullet per sentence or
   `;`-part of the Plan (strip trailing dots; drop empty parts).
6. `report [--now "Sun 11-01 12:30"]` rewrites only the BRIEFING `## Open now (...)` heading (new time; default now, format
   `%a %m-%d %H:%M`) and its table. Header `| # | Open item | Status | Checked | Your move? | When |`. One row per queue row (item =
   task cut at 60 chars; status = Status; checked `-`; Your move? `yes` when the Lane is Feras, else `no`; when = Status) and per Open point (status `open`;
   yes when the Owner is Feras). Numbering restarts at 1. Everything from the next `## ` heading on stays byte for byte.
7. `plugins/pm/.claude-plugin/plugin.json` (copy studio's shape, name `pm`, version 0.1.0), add `pm` to `.claude-plugin/marketplace.json`,
   and `plugins/pm/skills/{status,next,row,week,report}/SKILL.md`: frontmatter `name` and `description`, 15 lines or fewer each, body only
   says which `python ${CLAUDE_PLUGIN_ROOT}/scripts/pm.py ...` call to make and to show its output.
8. `claude plugin validate plugins/pm --strict` must pass (run it).

## Do NOT edit
D6 defaults, protected by tools/build_gate.py without being listed: existing tests, tools/, .github/, plugins/ (edits and
deletions; new test files are allowed) and every change under assets/ (incl. *.import). Keep this prose free of
backticks: every backticked token in this section is a forbidden path, and May edit does not lift it.
`tools/test_pm.py`
`HANDOFF.md`
`features/`
`core/`
`plugins/studio/`

## May edit
`plugins/pm/`
`.claude-plugin/marketplace.json`

## Ripple
none: new plugin, nothing imports it yet; row 25 wires the marketplace; doc_check and HANDOFF format are read, not changed.

## Pre-mortem
1. A row edit corrupts HANDOFF: the doc_check restore test and the unknown-row test stop it. 2. The report loses the BRIEFING history: the byte-for-byte tail test. 3. Windows CRLF: write with newline="\n".

## Tests
`tools/test_pm.py` (red on the base): board/next/row/week/report on a fixture, restore on doc_check failure, the real HANDOFF read-only, plugin files. Player-visible: Feras's board in one call (test_board_...).

## Checklist
- file: plugins/pm/scripts/pm.py
- file: plugins/pm/.claude-plugin/plugin.json
- test: tools/test_pm.py :: test_row_edit_is_restored_when_doc_check_fails

## Proof
`RUN_KIND=py`; `bash tools/check.sh --no-godot` raw last 15 lines; final message ends with
`Built-by: Gemini 3.8 Flash (agy)`.
