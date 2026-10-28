---
name: players-eye-gate
description: The gate before any build reaches Feras: record frames of the real scene, measure, have the calibrated player lens read them against the acceptance list, then Opus confirms the misses. Use before telling Feras to play or look at anything visual.
paths:
  - "features/**"
  - "assets/**"
  - "tools/eye_*"
---
# Player's-eye gate (no build reaches Feras before its frames are checked)
Why: on 10-26 Feras saw grey sprites, 12 fps clips, tiny text and a dark-rectangle "lights off" that every test passed.
The bars live in docs/design/acceptance.md (ids C1, M1, U1 ...); Feras edits them, we do not.

## Steps
1. Record: `bash tools/eye_gate.sh res://tools/shot_neon_game.tscn 24 <out dir>` (any render wrapper .tscn; non-headless
   `--write-movie`, 30 fps; ffmpeg makes `contact.png` 4x4 and `clip.mp4`). `<out dir>` is your scratchpad, never inbox/ of
   another checkout, never assets/. One Godot at a time (`bash tools/slots.sh`); `tools/run_godot.sh --import` first after a pull.
2. Measure: `python tools/eye_metrics.py`. Lines are `METRIC <name> <value> <PASS|WARN> <bar>`; it always exits 0. Every
   WARN goes in the report. (Bars: fps >= 24, colours > 256, font >= 18 px at 720p; chroma and frames are info.)
3. Look: the calibrated player lens (`.claude/agents/review-player`, Haiku effort low, or nemotron-3-ultra :free via
   `mcp__openrouter__send-message` with public content only) reads 4-6 frames at 640x360 plus contact.png against
   acceptance.md, and answers each id seen: OK / MISS / CANNOT SEE, one line each. Frames, not code.
4. Confirm: Opus (or the advisor) re-reads the flagged frames and confirms or drops each MISS. A lens finding is a flag, not a fact.
5. Stamp: after review-player and review-feras, `python tools/hooks/review_stamp.py --player "<verdict>" --feras
   "<verdict>" <contact.png> <clip.mp4> <frames sent>`. The review gate hook blocks SendUserFile and Artifact on any
   unstamped render (tools/hooks/review_gate.py).
6. Only then does the build reach Feras, with the WARN/MISS list and the contact sheet. Open MISSes are named, not hidden.

## Rules
- Frames come from the play camera at the shipped resolution; a render of a different scene does not count.
- A metric WARN is not auto-fail (eye_metrics is a report); a confirmed MISS on a Feras-set bar blocks the hand-off.
- Never write the frames into the repo; the contact sheet and one frame may go to inbox/ of the same checkout for Feras.
- Lens results are cached by commit: do not re-run the lens on an unchanged build.
