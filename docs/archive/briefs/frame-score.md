# Brief: frame-score
You are in your own worktree on branch gemini/frame-score (made from origin/worktree-row18c-gaps). Follow GEMINI.md, including
<review_misses>. Load the minimal-change-engineer skill (Ops has no research persona; our rules outrank its text).
Pattern: tools/eye_metrics.py, tools/test_eye_metrics.py
Timebox: 30 min. First commit within 15 min, then small WIP commits: no commit for 25 min (IDLE_MIN) = NOWORK.

## Why
Feras 10-31, row 18c: calibrate cheap vision models on real frames against review-player, so a yes/no pre-filter can
save review tokens. Scoring those answers by hand does not repeat. Pillar served (docs/VISION.md): combat feel wins ties
(a cheaper look gate lets more frames be checked before Feras plays).

## Read first
tools/eye_metrics.py and tools/test_eye_metrics.py only (house style for a small CLI and its test).

## What to build
tools/frame_score.py, standard library only, <= 120 lines, a `#!/usr/bin/env python` line and a one-line purpose docstring:
1. `to_bool(value, threshold=0.5)` -> True, False or None. A bool stays itself. An int or float is True when >= threshold.
   Text: the first word `yes` or `no` in it, any case, inside markdown or punctuation (`**Yes.**`, `Answer: NO`); a word
   that only contains them (`nothing`, `yesterday`) does not count; no such word = None. Anything else = None.
2. `parse_lines(text, count)` -> a list of exactly `count` values from to_bool. Numbered lines (`1. yes`, `2) no`) fill
   their slot, unnumbered replies fill slots in order. Words on one line (`no yes yes`) are `count` answers in order.
   A slot with no answer = None. A number beyond `count` is ignored.
3. `score(reference, answers, threshold=0.5)`: both are `{frame: [value, ...]}`; reference values are bools. Returns a dict
   with total, agree, false_pass (reference False, answer True), false_fail (reference True, answer False), unparsed
   (None or a missing frame or slot). total counts every reference slot. A frame only in answers is ignored.
4. CLI: `python tools/frame_score.py --reference ref.json --answers answers.json [--threshold 0.5] [--lines N]`. Both files are
   JSON objects as in step 3; with --lines N each answer is a reply text read through parse_lines. Prints one JSON line
   from score. Exit 0; a missing or invalid file prints `ERROR: <reason>` and exits 1, no traceback.

## Do NOT edit
D6 defaults, protected by tools/build_gate.py without being listed: existing tests, tools/, .github/ (edits and
deletions; new test files are allowed) and every change under assets/ (incl. *.import). Keep this prose free of
backticks: every backticked token in this section is a forbidden path, and May edit does not lift it.
`content/`
`features/`
`core/`

## May edit
`tools/frame_score.py`

## Ripple
none: a new standalone tool; nothing imports it, no pipeline or check calls it.

## Pre-mortem
none: small, low-risk, pure logic with tests.

## Tests
New file tools/test_frame_score.py, same runner block as the pattern. One test per rule:
to_bool on bools, floats at the threshold, `**Yes.**`, `Answer: NO`, `nothing`, None; parse_lines on numbered, on
`no yes yes`, on a short reply; score counts one false pass, one false fail and one unparsed slot in a two-frame sample;
a frame missing from the answers counts all its slots unparsed; the CLI on real temp files prints the JSON line, and on a
missing file prints ERROR and exits 1. No Godot, no network.

## Checklist
- file: tools/frame_score.py
- has: tools/frame_score.py :: def to_bool
- has: tools/frame_score.py :: def parse_lines
- has: tools/frame_score.py :: def score
- test: tools/test_frame_score.py :: test_to_bool_reads_markdown_and_ignores_inner_words
- test: tools/test_frame_score.py :: test_score_counts_false_pass_false_fail_and_unparsed

## Proof
`bash tools/check.sh --no-godot` raw last 15 lines; final message ends with `Built-by: Gemini 3.8 Flash (agy)`.
