# Brief: frame-score-fix
You are in your own worktree on branch gemini/frame-score, your build of docs/briefs/frame-score.md. Follow GEMINI.md, including
<review_misses>. Load the minimal-change-engineer skill (Ops has no research persona; our rules outrank its text).
Pattern: tools/eye_metrics.py, tools/test_eye_metrics.py
Timebox: 30 min. First commit within 15 min, then small WIP commits: no commit for 25 min (IDLE_MIN) = NOWORK.

## Why
Feras 10-31, row 18c: five reviewers read the build; these defects are confirmed by Opus. Pillar served (docs/VISION.md):
combat feel wins ties (a scorer that miscounts would pick the wrong look gate).

## Read first
tools/frame_score.py and tools/test_frame_score.py only.

## What to build
Keep to <= 140 lines in tools/frame_score.py. Rewrite parse_lines rather than patching it.
1. to_bool: `_` and `__` count as markdown around a word (`_yes_`, `__NO__` read as answers); a NaN number returns None.
2. parse_lines(text, count), in this order:
   a. Numbered answers first: every `N.`, `N)`, `N:` or `N-` marker at a line start or after whitespace opens slot N, up to
      the next marker or line end, also several on one line (`1. no 2. yes`). A number beyond `count` is ignored. A
      numbered slot with no readable answer stays None and later text never fills it.
   b. Then the unnumbered lines, in order, into the free slots: a line of only yes/no words and punctuation is one answer
      per word (`no yes`); a line with one yes/no word plus prose is one answer; prose with several yes/no words
      (`No, there is no rain.`) is one answer, its first word; a line with no yes/no word is skipped and takes no slot
      (`Looking at the frames:`). Blank lines are skipped.
3. score: the counters always add up to total. A plain value where a list belongs counts all that frame's slots unparsed.
4. CLI: open files as utf-8-sig. Every shape problem prints `ERROR: <reason>`, exit 1, no traceback, stderr empty: a reference
   frame value that is not a list of bools; without --lines an answers value that is not a list; with --lines an answers
   value that is not text or a list of text. All parsing sits inside the one try.

## Do NOT edit
D6 defaults, protected by tools/build_gate.py without being listed: existing tests, tools/, .github/ (edits and
deletions; new test files are allowed) and every change under assets/ (incl. *.import). Keep this prose free of
backticks: every backticked token in this section is a forbidden path, and May edit does not lift it.
`content/`
`features/`
`core/`

## May edit
`tools/frame_score.py`
`tools/test_frame_score.py`

## Ripple
none: nothing imports this tool yet.

## Pre-mortem
none: small, low-risk, pure logic with tests.

## Tests
Add to tools/test_frame_score.py, one case per line, each red on your first build:
`1. yes\nno yes`, 3 -> [True, False, True]; `1. maybe\nyes`, 2 -> [None, True]; `1. no 2. yes`, 2 -> [False, True];
`no\n1. yes`, 2 -> [True, False]; `Looking at the frames:\nyes\nno`, 2 -> [True, False]; `no yes\nyes`, 3 -> [False, True, True];
`No, there is no rain.`, 2 -> [False, None]; `_yes_` and `__NO__`; float NaN -> None; a score with an answers list
shorter than the reference; the CLI on a BOM file, on reference `{"f1": true}`, on `{"f1": "yes"}`, on answers `{"f1": "yes"}`
without --lines, on `{"f1": [true]}` with --lines, and on malformed JSON, each with ERROR, exit 1 and empty stderr.
Keep every existing test.

## Checklist
- file: tools/frame_score.py
- has: tools/frame_score.py :: def parse_lines
- test: tools/test_frame_score.py :: test_numbered_slots_win_and_preamble_takes_no_slot
- test: tools/test_frame_score.py :: test_cli_rejects_bad_shapes_with_error_and_empty_stderr

## Proof
`bash tools/check.sh --no-godot` raw last 15 lines; final message ends with `Built-by: Gemini 3.8 Flash (agy)`.
