# Brief: cross-review-parser (HANDOFF row 12, race B: agy and cf build this same brief in two worktrees)
You are in your own worktree on branch <gemini|oc>/cross-review-parser-<agy|cf> (made from origin/claude/trusting-chatelet-141211). Follow GEMINI.md, including
<review_misses>. Load the minimal-change-engineer skill (build_pipeline.sh pastes it; our rules outrank its text).
Timebox: 30 min. First commit within 15 min, then small WIP commits: no commit for 25 min (IDLE_MIN) = NOWORK.
This is a Python-only run (RUN_KIND=py): change no Godot file; the check is `bash tools/check.sh --no-godot`.

## Why
Feras 10-28: a builder of the other model family reviews every PASS run before Claude. Its findings come back as one
fixed block; this parser turns that block into data and must never read a crashed or chatty reviewer as clean.
Pillar: process (less Claude review time, so more of the limit goes to the game).

## Read first
tools/cross_review_prompt.md (the output contract the reviewer gets), tools/test_cross_review.py (the tests to make
green). Read nothing else.

## What to build
1. New file tools/cross_review.py (Python 3, standard library only, <= 200 lines, a docstring first line saying what it
   is). `parse(text) -> dict` with keys status ("OK" or "INVALID"), findings (a list of dicts: severity, file, line
   (int), scenario, fix) and reason (empty string when OK).
2. The block is the LAST `BEGIN FINDINGS` line and the first `END FINDINGS` line after it (markers compared after
   strip). Inside it, blank lines and lines starting with three backticks are skipped. No block, no end marker, or an
   empty block: INVALID. Exactly one line `NONE`: OK with no findings. NONE with anything else, or more than 12 lines:
   INVALID.
3. A finding line splits on `|` at most 3 times (so the fix may contain `|`), fields stripped. Valid only when:
   severity is high, medium or low (any case, stored lowercase); the location is `<path>:<n>` or `<path>:<n>-<m>`
   (path without spaces, n >= 1; line = n); the scenario contains `->`; the fix is not empty. One invalid line makes
   the whole block INVALID with no findings, and reason names the line.
4. CLI: `python tools/cross_review.py parse <log> [--out <file>]`. OK: print
   `CROSS OK <n> (high <h>, medium <m>, low <l>)`, exit 0, and write to --out a markdown table: the header
   `| severity | file:line | failure scenario | fix |`, the `|---|---|---|---|` row, one row per finding as
   `| <severity> | <file>:<line> | <scenario> | <fix> |` with every `|` inside a field written as `\|`; no findings:
   the file holds `NONE`. INVALID: print `CROSS INVALID <reason>`, exit 1, and --out holds `INVALID: <reason>`.

## Do NOT edit
D6 defaults, protected by tools/build_gate.py without being listed: existing tests, tools/, .github/ (edits and
deletions; new test files are allowed) and every change under assets/ (incl. *.import). Keep this prose free of
backticks: every backticked token in this section is a forbidden path, and May edit does not lift it.
`tools/test_cross_review.py`
`tools/cross_review_prompt.md`
`docs/briefs/`
`.claude/`
`GEMINI.md`

## May edit
`tools/cross_review.py`
`docs/MAP.md`

## Ripple
New file only. tools/cross_review.sh (row 12 A, later) will call parse; the prompt's example line must stay valid
(test_prompt_example_parses). docs/MAP.md: `git add tools/cross_review.py`, then `python tools/map.py`.

## Pre-mortem
1. A reviewer that crashed or only chatted reads as "no findings" -> INVALID unless NONE is explicit (tested).
2. A pipe inside the fix shifts the columns -> split at most 3 times; the table escapes it (tested).
3. The model echoes the prompt's example block -> the last block wins (tested).

## Tests
tools/test_cross_review.py, red on the base, read-only: `python tools/test_cross_review.py` must print
"test_cross_review: 7 tests passed". Player-visible: none (tools).

## Checklist
- file: tools/cross_review.py
- has: tools/cross_review.py :: def parse
- has: tools/cross_review.py :: CROSS INVALID

## Proof
`bash tools/check.sh --no-godot` raw last 15 lines; final message ends with `Built-by: Gemini 3.8 Flash (agy)`
(opencode: `Built-by: <model> (opencode)`).
