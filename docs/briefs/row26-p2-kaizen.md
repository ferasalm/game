# Brief: row26-p2-kaizen (cf DeepSeek low with a Pattern; Python only, RUN_KIND=py)
You are in your own worktree on branch oc/row26-p2-kaizen (made from origin/row26-p2-base, the locked tests; pushed). Follow GEMINI.md, including
<review_misses>. Load the builders skill.
Pattern: tools/part_report.py, tools/oc_usage.py
Timebox: 30 min. First commit within 15 min, then small WIP commits.

## Why
Feras 11-02: close the telemetry loop. Every batch ends with one Kaizen line: what to cut or tune. A script reads docs/runs.csv and says it in at most 20 lines, so the head spends no tokens reading the scoreboard. Pillar served: none directly (the build system improves itself).

## Read first
tools/test_kaizen_report.py (the locked tests, read-only: they define every output), tools/part_report.py (house style, how a csv is read), tools/runs_log.py (the columns: date, task, worker, effort, gate, fix_passes, minutes, cost, real_findings, tokens_in, tokens_out, usd_est, cost_source, idle_min; an older file has only the first nine).

## What to build
`tools/kaizen_report.py [--csv FILE] [--since YYYY-MM-DD]` (<= 110 lines, functions <= 40 lines, docstring first). Default csv `docs/runs.csv`. A missing column or a `?` cell is unknown, never 0; rows of an old 9-column file have every new column unknown.
1. First line `KAIZEN <n> runs, <first date>..<last date>` (after --since: only rows with date >= it); no rows: `KAIZEN 0 runs` and nothing else.
2. One line per group `worker/effort` (effort `-` stays `-`), sorted by runs descending then name, at most 12 groups (then `... and <k> more groups`): `<group>  runs N  pass P%  min avg A  fix avg F  idle I min  tok X/Y  usd U (k unknown)` where pass% = whole percent of rows whose gate is PASS; A and F to 1 decimal; I = sum of numeric idle_min; X, Y = sums of numeric tokens_in and tokens_out; U = sum of numeric usd_est to 2 decimals; k = rows whose tokens_in is unknown (write `tok ?/?` and `usd ?` when every row is unknown).
3. Then `tune:` lines, only when triggered, in this order:
   - a group whose idle sum is at least 10 minutes and at least 15% of its minutes: `tune: <group> lost <I> of <M> min to idle: lower QUIET_SEC or tighten the first-commit deadline`;
   - a group with at least 3 runs and pass% under 70: `tune: <group> passes only <P>% of <N> runs: tighten briefs or move up an effort`;
   - a group with at least 3 runs and fix avg over 1.0: `tune: <group> needs <F> fix passes a run: write sharper tests`;
   - any unknown-cost row: `tune: <K> row(s) have no cost reading (older runs or non-opencode builders)`.
4. Never more than 20 lines in total; exit 0 always; paths as arguments.

## Do NOT edit
D6 defaults, protected by tools/build_gate.py without being listed. Keep this prose free of backticks outside May edit.

## May edit
none

## Ripple
none: a new stand-alone tool; the skill's Kaizen step calls it. docs/MAP.md and DOCMAP.md refresh themselves.

## Pre-mortem
- A cell like `0.0362` or `?` or empty breaks a float: every numeric read goes through one helper that returns None for anything that is not a number.
- A group with one row divides by zero somewhere: averages use the row count, never a guess.
- Windows CRLF in a csv: read with newline="".

## Tests
- tools/test_kaizen_report.py :: every test (red on the base)

## Checklist
- file: tools/kaizen_report.py
- test: tools/test_kaizen_report.py :: test_groups_are_sorted_and_summed_with_unknowns_left_out

## Proof
`bash tools/check.sh --no-godot` raw last 15 lines; final message ends with `Built-by: DeepSeek V4.1 Flash low (opencode)`.
