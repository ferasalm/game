# Brief: p2b-eye-metrics (<= 60 lines)
You are in your own worktree. Follow GEMINI.md. Load the godot-gameplay-scripter skill only for naming habits; this is
Python, no Godot run is needed.

## Why
The player's-eye gate needs numbers a reader cannot fake: clip fps, sheet colours, alpha, smallest font. A report, not a gate.

## Read first
- tools/test_eye_metrics.py (the spec in executable form; make it pass unchanged)
- tools/art/sprite_sheet.py lines 1-20 (style of a small Pillow tool); content/neon/sprites.json head (shape)

## What to build
Create `tools/eye_metrics.py`, <= 120 lines, a docstring first line, stdlib + Pillow only. `python tools/eye_metrics.py
[--root DIR]` (default: the git top level, else the cwd). Print one line per metric, always exit 0 (even with no files):
`METRIC <name> <value> <PASS|WARN> <bar>`
1. For each item and state in `<root>/content/neon/sprites.json` (items[].states[]; `sheet` is `res://path` -> `<root>/path`):
   - `clip_fps:<id>:<state>` = the state's `fps`; PASS when >= 24 else WARN; bar `>=24`.
   - `clip_frames:<id>:<state>` = `frames`; PASS; bar `info`.
   - `clip_px:<id>:<state>` = `<frame_w>x<frame_h>`; PASS; bar `info`.
   - `sheet_colours:<id>:<state>` = unique colours among pixels with alpha > 0 (convert to RGBA; for a sheet without alpha
     every pixel counts); PASS when > 256 else WARN; bar `>256`.
   - `sheet_alpha:<id>:<state>` = `yes` when the PNG has an alpha channel (RGBA/LA, or P with transparency) else `no`;
     PASS for yes, WARN for no; bar `alpha`.
   - `sheet_chroma:<id>:<state>` = mean of (max-min of R,G,B) over alpha > 0 pixels, one decimal; PASS; bar `info`.
   - A missing sheet file: `sheet_missing:<id>:<state> 0 WARN exists` and skip its sheet metrics.
2. `font_min` = the smallest integer N in any line matching `(^|[\s/])(default_)?font_size\s*=\s*N` in
   `<root>/features/**/*.tscn` and `*.tres` (so `end_font_size = 3` does not count). PASS when >= 18 else WARN; bar
   `>=18`. No match: `font_min none PASS >=18`.
Values print without spaces (no spaces in names or values). Fps prints as the JSON number does (`12.0` or `12`).

## Do NOT edit
`tools/test_eye_metrics.py`
`tools/build_gate.py`
`tools/check.sh`
`assets/`
`content/`
`features/`
Everything else except the May edit list below.

## May edit
`tools/eye_metrics.py` (new)

## Tests
`python tools/test_eye_metrics.py` prints only `ok` lines (check.sh picks the file up by itself).

## Checklist
- file: tools/eye_metrics.py
- test: tools/test_eye_metrics.py :: check(

## Proof
`python tools/test_eye_metrics.py` and `bash tools/check.sh` raw last 15 lines; small WIP commits; final message ends
with `Built-by: DeepSeek (cf)`.
