# Brief: fast-probe-stream
You are in your own worktree on branch oc/fast-probe-stream (made from origin/main). Follow GEMINI.md, including
<review_misses>. Load the minimal-change-engineer skill (our rules outrank its text).
Pattern: tools/cf_probe.py, tools/test_cf_probe.py
Timebox: 15 min. First commit within 10 min; no commit for 25 min (IDLE_MIN) = NOWORK.

## Why
Feras 10-31: test DeepSeek non-reasoning on a real Python build. Pillar served (docs/VISION.md): the small, fast team behind combat feel.

## Read first
tools/cf_probe.py read_stream, tools/test_cf_probe.py.

## What to build
1. In tools/cf_probe.py read_stream: a `data:` line that is not valid JSON is skipped and counted, never a crash. Add the key
   "bad_lines" to the dict read_stream returns (an int, 0 when none).
2. In summary(): add "bad_lines" to the printed dict.
3. New file tools/test_cf_probe_stream.py with the test below and a `__main__` block in the same style as tools/test_cf_probe.py.

## Do NOT edit
`tools/test_cf_probe.py`

## May edit
`tools/cf_probe.py`

## Ripple
none: cf_probe is a standalone tool; the new key only adds to its printed line.

## Pre-mortem
none: a few lines in one tool, covered by the new test.

## Tests
tools/test_cf_probe_stream.py: test_a_broken_line_is_skipped_and_counted feeds a good event, `data: {broken`, then a good
event to read_stream; both texts survive, bad_lines is 1, and summary() prints bad_lines.

## Checklist
- file: tools/test_cf_probe_stream.py
- has: tools/cf_probe.py :: bad_lines
- test: tools/test_cf_probe_stream.py :: test_a_broken_line_is_skipped_and_counted

## Proof
`bash tools/check.sh --no-godot` raw last 15 lines; final message ends with `Built-by: DeepSeek V4.1 Flash, no reasoning (opencode)`.
