# Brief: row23c-usage (HANDOFF row 23, part c)
You are in your own worktree on branch gemini/row23c-usage (made from origin/system-v3; the base is pushed). Follow GEMINI.md, including
<review_misses>. Load the minimal-change-engineer skill (build_pipeline.sh pastes it; our rules outrank its text).
Pattern: tools/session_stats.py
Timebox: 45 min. First commit within 15 min, then small WIP commits: no commit for 25 min (IDLE_MIN) = NOWORK.

## Why
Feras 11-01: the USAGE row and a run scoreboard come from data, not from memory. Pillar: process.

## Read first
tools/test_usage_row.py (read-only; make it green), tools/session_stats.py (all 90 lines), tools/build_pipeline.sh (where `.result` is written
at the end and where the builder, task, gate verdict and fix passes are known), docs/USAGE.md lines 1-9. Read nothing else.

## What to build
1. `python tools/session_stats.py --row <session id> [--dir D]`: find `*/<id>.jsonl` under D (default as today); none: print `no transcript for <id>` and exit 1.
   Print ONE line `| date | model | effort | task | window % | result |` (6 cells): date = the first event's `timestamp` (UTC date; else file mtime), model =
   `<Name> (` + backticked raw id + `)` for claude-sonnet-5-5 -> Sonnet 5.5, claude-opus-5-5 -> Opus 5.5, claude-haiku-5-5 -> Haiku 5.5, claude-fable-5-1 ->
   Fable 5.1 (unknown id: the raw id alone; the most used model), effort `TODO`, task `TODO task`, window % `TODO`, result =
   `calls N (M failed), cache reads 3,500, peak context 2k; result: TODO; Kaizen: TODO` (N = tool_use blocks; M = tool results with is_error; cache reads =
   sum of cache_read_input_tokens with thousands commas; peak context = the largest input+cache_read+cache_creation of one request, in k, integer division). The no-argument table keeps working.
2. `tools/runs_log.py append --task T --worker W --effort E --gate G --fix-passes N --minutes M --cost C --findings F [--file docs/runs.csv] [--date YYYY-MM-DD]`
   (csv module, LF line endings, writes the header `date,task,worker,effort,gate,fix_passes,minutes,cost,real_findings` once, default date today).
3. `docs/runs.csv` with only that header line; `.gitattributes` gets the line `docs/runs.csv merge=union`.
4. `tools/build_pipeline.sh`: at the end of a run (after the final `.result` is written, PASS or not) call
   `python tools/runs_log.py append ... || true` with the run's real values (task, builder as worker, effort = the model's effort word or `-`, gate = the first word
   of the verdict, fix passes, minutes since start, cost `0` unless the script already knows it, findings `0`). A logging error never changes the run's result or exit code.
   Edit as little as possible; the toy pipeline tests (tools/test_build_pipeline.py, test_py_runs.py) must stay green.

## Do NOT edit
D6 defaults, protected by tools/build_gate.py without being listed: existing tests, tools/, .github/, plugins/ (edits and
deletions; new test files are allowed) and every change under assets/ (incl. *.import). Keep this prose free of
backticks: every backticked token in this section is a forbidden path, and May edit does not lift it.
`tools/test_usage_row.py`
`tools/test_build_pipeline.py`
`tools/test_py_runs.py`
`features/`
`core/`
`plugins/`

## May edit
`tools/session_stats.py`
`tools/runs_log.py`
`tools/build_pipeline.sh`
`docs/runs.csv`
`.gitattributes`

## Ripple
build_pipeline.sh is executed by every builder run (never edit it while one runs; Claude merges this run last). merge_run.sh and slots.sh read the .result file, which does not change. The toy tests copy tools/, so runs_log.py must tolerate a missing docs/ folder (create it).

## Pre-mortem
1. The logger breaks a run: `|| true` plus the grep test. 2. CRLF in the csv: the CR test. 3. The pipeline test toy lacks runs_log.py: guard the call with `[ -f tools/runs_log.py ]`.

## Tests
`tools/test_usage_row.py` (red on the base): USAGE row cells, unknown session, old table, csv rows and header, repo wiring.

## Checklist
- file: tools/runs_log.py
- has: tools/session_stats.py :: main
- test: tools/test_usage_row.py :: test_repo_wiring_runs_csv_union_header_and_pipeline_call

## Proof
`RUN_KIND=py`; `bash tools/check.sh --no-godot` raw last 15 lines; final message ends with
`Built-by: Gemini 3.8 Flash (agy)`.
