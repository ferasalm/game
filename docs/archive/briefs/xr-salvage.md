# Brief: xr-salvage
You are in your own worktree on branch gemini/xr-salvage (made from origin/base-xr-salvage). Follow GEMINI.md, including
<review_misses>. Load the minimal-change-engineer skill (Ops has no research persona; our rules outrank its text).
Pattern: tools/cross_review.py, tools/test_cross_review.py
Timebox: 25 min. First commit within 15 min, then small WIP commits: no commit for 25 min (IDLE_MIN) = NOWORK.

## Why
Feras 10-31, BRIEFING item 9: a cross-review with 10 real findings was thrown away, twice, because one line had no `->`.
Keep the valid lines. Pillar served (docs/VISION.md): combat feel wins ties (builds reach Feras sooner and with fewer bugs).

## Read first
tools/cross_review.py and tools/test_cross_review.py only. The tests are already written and red on your base.

## What to build
All in tools/cross_review.py, standard library only, the file stays <= 150 lines:
1. `parse(text)` always returns a `rejected` key, a list of strings, empty on every path where nothing was rejected.
2. In the line loop, a line `_parse_finding` refuses no longer ends the parse: its error string (it already holds the whole
   line) goes to `rejected`, and the loop goes on.
3. At least one finding: status "OK", findings in the order of the log, `rejected` filled.
4. No finding at all: status "INVALID", findings empty, reason = the first error. The rules before the loop stay as they are: no
   markers, an empty block, `NONE` alone, `NONE` mixed with other lines, more than 12 lines.
5. `_format_markdown(findings, rejected)`: after the table, when `rejected` is not empty, a blank line, the line
   `## Rejected lines (the parser could not read these: read them)`, then one `- <error>` line each. No heading when it is empty.
   `NONE` output for zero findings stays.
6. CLI: the OK line gains `, N rejected` after the closing bracket when N > 0, and stays exactly as today when N is 0.

## Do NOT edit
D6 defaults, protected by tools/build_gate.py without being listed: existing tests, tools/, .github/ (edits and
deletions; new test files are allowed) and every change under assets/ (incl. *.import). Keep this prose free of
backticks: every backticked token in this section is a forbidden path, and May edit does not lift it.
`content/`
`features/`
`core/`
`tools/cross_review.sh`
`tools/cross_review_prompt.md`
`tools/test_cross_review.py`

## May edit
`tools/cross_review.py`

## Ripple
tools/cross_review.sh calls `cross_review.py parse` and reads only its exit code: a partly valid block now exits 0, so it skips
the forced round, which is the point. No other caller; the result text and build_gate.py never read it.

## Pre-mortem
A reviewer's prose inside the block now reads as OK with zero real value: the reason is shown in the Rejected section, and a block
with no valid line stays INVALID. A rejected line vanishing from the file: the test greps for it. The 12-line limit and NONE rules
moving: their tests stay red if touched.

## Tests
Already in tools/test_cross_review.py, read-only: test_a_block_with_no_valid_line_is_invalid,
test_a_bad_line_keeps_the_valid_lines_and_names_itself, test_cli_shows_rejected_lines_in_the_review_file. All others stay green.

## Checklist
- file: tools/cross_review.py
- has: tools/cross_review.py :: rejected
- test: tools/test_cross_review.py :: test_a_bad_line_keeps_the_valid_lines_and_names_itself

## Proof
`bash tools/check.sh --no-godot` raw last 15 lines; final message ends with `Built-by: Gemini 3.8 Flash (agy)`.
