"""Packs tools/bake_sprites.tscn frames into one sheet per state (Neon Glitch iso sprites, docs/design/first-playable.md).
Rows are the 8 screen directions (0 = right, counter-clockwise, 6 = toward the camera), columns the frames. Every state
is cropped to the union of its frames' opaque pixels (plus a margin), and the feet pivot moves with the crop.
Usage: python tools/art/sprite_sheet.py <frames dir> <model id> <out dir> [frame px] [ortho m] [colours]
colours: 0 = full colour RGBA (default, the Hades bar), N = quantize to N colours (<= 256).
Writes <out dir>/<id>_<state>.png and prints one JSON object per state for content/neon/sprites.json."""
import glob
import json
import os
import re
import sys

from PIL import Image

MARGIN = 4
LOOK_HEIGHT_M = 0.9  # bake_sprites.gd looks at (0, 0.9, 0)
ELEVATION_DEG = 30.0


def feet_pivot(frame_px: int, ortho_m: float) -> tuple:
    import math
    drop_m = LOOK_HEIGHT_M * math.cos(math.radians(ELEVATION_DEG))
    return frame_px / 2.0, frame_px / 2.0 + drop_m * frame_px / ortho_m


def main() -> None:
    src, model, out = sys.argv[1], sys.argv[2], sys.argv[3]
    frame_px = int(sys.argv[4]) if len(sys.argv) > 4 else 256
    ortho = float(sys.argv[5]) if len(sys.argv) > 5 else 2.6
    colours = int(sys.argv[6]) if len(sys.argv) > 6 else 0
    os.makedirs(out, exist_ok=True)
    pattern = re.compile(r"%s_(\w+?)_d(\d)_f(\d+)\.png$" % re.escape(model))
    frames: dict = {}
    for path in glob.glob(os.path.join(src, "%s_*.png" % model)):
        m = pattern.search(os.path.basename(path))
        if m:
            frames.setdefault(m.group(1), {})[(int(m.group(2)), int(m.group(3)))] = path
    px, py = feet_pivot(frame_px, ortho)
    for state, cells in sorted(frames.items()):
        count = max(f for _, f in cells) + 1
        images = {key: Image.open(path).convert("RGBA") for key, path in cells.items()}
        box = None
        for im in images.values():
            b = im.getbbox()
            if b:
                box = b if box is None else (min(box[0], b[0]), min(box[1], b[1]), max(box[2], b[2]), max(box[3], b[3]))
        x0, y0 = max(0, box[0] - MARGIN), max(0, box[1] - MARGIN)
        x1, y1 = min(frame_px, box[2] + MARGIN), min(frame_px, box[3] + MARGIN)
        cw, ch = x1 - x0, y1 - y0
        sheet = Image.new("RGBA", (cw * count, ch * 8), (0, 0, 0, 0))
        for (d, f), im in images.items():
            sheet.alpha_composite(im.crop((x0, y0, x1, y1)), (f * cw, d * ch))
        name = "%s_%s.png" % (model, state)
        if colours > 0:  # e.g. 256: about a sixth of the RGBA size, only when asked
            sheet = sheet.quantize(colors=colours, method=Image.Quantize.FASTOCTREE, dither=Image.Dither.NONE)
        sheet.save(os.path.join(out, name), optimize=True)
        print(json.dumps({"state": state, "sheet": name, "frame_w": cw, "frame_h": ch, "frames": count,
                          "pivot": [round(px - x0, 1), round(py - y0, 1)]}))


if __name__ == "__main__":
    main()
