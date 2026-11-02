# Brief: row26-s10-report (cf DeepSeek high; Python only, RUN_KIND=py)
You are in your own worktree on branch oc/row26-s10-report (made from origin/row26-s10-base; the base is pushed). Follow GEMINI.md, including
<review_misses>. Load the builders skill.
Pattern: tools/oc_usage.py, tools/runs_log.py
Timebox: 30 min (<= 45). First commit within 15 min, then small WIP commits.

## Why
Feras 11-02: the head's context must not fill with builder output. One short report per part replaces reading a log, a diff or a `.result` in full. Pillar served: none directly (a lean head, cheaper and clearer reviews).

## Read first
tools/test_part_report.py (the red tests, read-only: they define the output), tools/oc_usage.py (house style), tools/runs_log.py (the runs.csv columns), tools/build_pipeline.sh lines 160-175 (what a `.result` looks like).

## What to build
`tools/part_report.py TASK [--wt-dir DIR] [--runs-csv FILE] [--reviews-dir DIR]` (<= 120 lines, functions <= 40 lines, docstring first). Defaults: wt dir = `<parent of the main checkout>/game-wt` (the same place tools/lib.sh wt_dir gives: find the main checkout from `git rev-parse --git-common-dir`), runs csv `docs/runs.csv`, reviews dir `.check/reviews` of the current checkout. It prints at most 15 lines of at most 160 characters (cut longer lines with `...`):
1. `<WORD> <task> builder=<b> model=<m> kind=<k>` from `<wt>/<task>.result` (WORD = its first word; missing parts print `?`). No `.result`: print only `NO RESULT <task>`.
2. `checked <7-char sha> <n> commits, <m> files` (commits = lines under `--- commits`; files from the diffstat summary line, else `?`).
3. `idle_min <N>` and the `quiet:` / `idle:` note line when present.
4. Up to 5 detail lines: the `.result` lines that start with WARN, BREACH, FAIL, ERROR, CHECKLIST, `gate error:` or `why:`.
5. `cost <tokens_in>/<tokens_out> tokens, $<usd_est> (<cost_source>)` from the LAST runs.csv row for the task; no csv or row: `cost ?`.
6. `flags <n> (<first finding text, cut>)` from `<reviews-dir>/<task>-cross.md` (count the lines between BEGIN FINDINGS and END FINDINGS; print `2 flag(s)` style with the first finding's text); no file: `flags ?`.
7. `next:` one line: PASS -> `read risky hunks, then bash tools/merge_run.sh <task>`; FAIL -> `read the FAIL lines in <task>.check.txt`; BREACH -> `read the breach, fix by hand or rerun`; NOWORK or ERROR -> `read the why line, fix the launch`. Never suggest a merge for a non-PASS word.
It never prints a log, a diff or a test body. Exit 0 always.

## Do NOT edit
D6 defaults, protected by tools/build_gate.py without being listed. Keep this prose free of backticks outside May edit.

## May edit
none

## Ripple
none: a new stand-alone tool; nothing imports it yet (the skill and briefs will call it). docs/MAP.md and DOCMAP.md refresh themselves.

## Pre-mortem
- A `.result` field is missing in an old run: every part prints `?`, never a traceback.
- A huge WARN line floods the report: the 160-char cut and the 15-line cap are tested.
- Windows paths in the git call: pass them as arguments, no shell string.

## Tests
- tools/test_part_report.py :: every test (red on the base)

## Checklist
- file: tools/part_report.py
- test: tools/test_part_report.py :: test_a_pass_report_has_the_word_model_cost_flags_and_the_next_step

## Proof
`bash tools/check.sh --no-godot` raw last 15 lines; final message ends with `Built-by: DeepSeek V4.1 Flash high (opencode)`.
