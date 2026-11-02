# Brief: row26-p2-kaizen-tests (SCOPE RUN: a worker writes ONLY the red tests; RUN_KIND=py)
You are in your own worktree on branch oc/row26-p2-kaizen-tests (made from origin/worktree-row26-pipeline-v2; the base is pushed). Follow GEMINI.md, including
<review_misses>. Load the builders skill.
Pattern: tools/test_part_report.py
Timebox: 40 min. First commit within 15 min, then small WIP commits.

## Why
Feras 11-02: this run writes ONLY the failing tests for docs/briefs/row26-p2-kaizen.md (read it fully: its What to build is the spec). A different model implements them next and cannot edit them. Weak tests are the usual defect: assert exact output lines, never "ran without error".

## Read first
docs/briefs/row26-p2-kaizen.md, tools/part_report.py, tools/test_part_report.py (house style for a report-tool test; reuse its way of building fixtures in a temp dir).

## What to build
ONE new file `tools/test_kaizen_report.py` (<= 200 lines, functions <= 40 lines), plain `test_*` functions, ending with the `run_cases` block used by tools/test_part_report.py. Stubs only. One test per rule, named for the rule, each asserting exact lines. Required, at least:
1. `test_groups_are_sorted_and_summed_with_unknowns_left_out`: a csv with 3 groups, mixed numeric and `?` cells; exact group lines, order, sums, averages, `(k unknown)`.
2. `test_an_old_nine_column_file_reads_every_new_column_as_unknown`.
3. `test_since_filters_by_date_and_the_header_names_the_range`.
4. `test_empty_or_missing_csv_reads_kaizen_0_runs`.
5. one test per tune rule that proves it fires (idle, low pass rate, fix passes, unknown cost) with the exact line, and one that proves each stays silent just under its threshold.
6. `test_the_report_never_exceeds_20_lines_and_caps_groups_at_12`.

## Do NOT edit
D6 defaults, protected by tools/build_gate.py without being listed. Write NO product code. Keep this prose free of backticks outside May edit.

## May edit
none

## Ripple
none: tests only. They are red on the base because the spec is unbuilt; do not run check.sh to turn them green.

## Pre-mortem
- A test passes on the base (proves nothing): run it once and confirm it fails for the stated reason before committing.
- A boundary off by one (exactly 10 idle minutes, exactly 15%, exactly 70%): test both sides of each.

## Tests
- tools/test_kaizen_report.py :: every test (red on the base)

## Checklist
- file: tools/test_kaizen_report.py

## Proof
Last 15 lines of the test run (expect FAIL lines); final message ends with `Built-by: <model> (opencode)`.
