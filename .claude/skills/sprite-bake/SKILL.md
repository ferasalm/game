---
name: sprite-bake
description: Bake a rigged 3D model into 8-direction sprite sheets (full colour) for Neon Glitch with tools/art/bake_all.sh. Use before baking any character, changing frame counts or sizes, or judging sprite colour.
paths:
  - "assets/**"
  - "tools/art/**"
  - "tools/bake_*"
---
# Sprite bake (Godot renders, Pillow packs)
Hades bar: **full colour by default**; no 256-colour cap unless asked (D: Hades look, 2026-10-27).

## Run
`bash tools/art/bake_all.sh <out dir> <ids,comma> [states] [frame px] [ortho m] [colours]`
- states = `name:frames:seconds,...`; default `idle:16:2.5,walk:12:1.333,run:10:0.933,attack:12:1.23,cast:8:0.67,hurt:4:0.33,ko:10:1.85`.
- frame px default 256, ortho 2.6 m, colours 0 = full colour (N <= 256 quantizes).
- One Godot at a time (it runs ids in sequence, `timeout 1200`, `< /dev/null`); check `bash tools/slots.sh` first.
- It writes `<out>/bake_<id>/` frames, `<out>/sheets/<id>_<state>.png` and `<out>/sheet_<id>.jsonl` (one JSON per state:
  state, sheet, frame_w, frame_h, frames, pivot). Never bake straight into assets/: bake to a scratch dir, look, then copy
  the sheets to assets/sprites/neon/ and merge the jsonl rows into content/neon/sprites.json (fps, loop, impact by hand).
- Render needs the class cache: after a pull run `tools/run_godot.sh --import` first (it can exit 139 on low memory; rerun).
- A bake without ERROR lines: `grep -c ERROR <out>/bake_<id>.log` must be 0.

## Look
- Render: ortho camera, 30 deg elevation, own unshaded ink shader plus hull outline (tools/bake_sprites.gd, bake_light.gd).
- Rows = 8 screen directions (0 = right, counter-clockwise, 6 = toward the camera); columns = frames; each state cropped to the
  union of opaque pixels plus a 4 px margin; the feet pivot moves with the crop.
- Verify by reading ONE frame at 640x360 or smaller, then `tools/eye_metrics.py` (colours, fps, alpha, chroma).
- Finding 2026-10-27: a rydan idle bake keeps 70k unique colours, but mean chroma is only ~12/255: it reads near-grey. Full colour
  is preserved by the packer; the muted look is the shader/texture. An art-chat task (test a saturated texture or shader mix).

## Open question for M1 (not decided here)
Frame rate x frame px x sheet memory on phones. Full-colour 1728x1552 RGBA for one 16-frame idle is ~10 MB uncompressed in VRAM;
7 states x 2+ characters adds up. M1 must pick fps per clip, a frame px, and a compression (VRAM compressed or reduced colours).

## Tests
`python tools/art/test_sprite_sheet.py` (tiny generated frames: count, sheet size, jsonl rows, colours kept when colours=0).
