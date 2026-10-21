#!/usr/bin/env python3
"""Turn a Gemini/Flow PNG into a palette-locked pixel sprite entry for content/art/sprites.json.

Usage: python tools/art/pixelize.py --in PIC.png --id my_sprite [--height 64] [--tolerance 40]
       [--palette content/art/palette.json] [--out content/art/sprites.json]
       [--contrast 1.25] [--saturation 1.4] [--outline]
Steps: key out the corner colour, trim, boost contrast/saturation (painted art is soft and loses its hues when
snapped), box-downscale to --height, snap each pixel to the nearest palette colour, optionally ring the figure
with the dark outline letter (art bible: dark outline 'k').
"""
import argparse
import json
import sys

from PIL import Image, ImageEnhance

OUTLINE_LETTER = "k"  # art bible: the dark selective outline colour

ALPHA_MIN = 128


def load_palette(path):
    with open(path, encoding="utf-8") as f:
        data = json.load(f)
    colors = data["items"][0]["colors"]
    return {k: tuple(int(v[i:i + 2], 16) for i in (1, 3, 5)) for k, v in colors.items()}


def key_out(img, tolerance):
    """Make every pixel close to the average corner colour transparent."""
    img = img.convert("RGBA")
    w, h = img.size
    corners = [img.getpixel(p)[:3] for p in ((0, 0), (w - 1, 0), (0, h - 1), (w - 1, h - 1))]
    bg = tuple(sum(c[i] for c in corners) // 4 for i in range(3))
    px = img.load()
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if a < ALPHA_MIN or sum((c - d) ** 2 for c, d in zip((r, g, b), bg)) <= tolerance ** 2:
                px[x, y] = (0, 0, 0, 0)
    return img


def trim(img):
    box = img.getchannel("A").point(lambda a: 255 if a >= ALPHA_MIN else 0).getbbox()
    return img.crop(box) if box else img


def downscale(img, height):
    width = max(1, round(img.width * height / img.height))
    # premultiplied box filter so transparent pixels do not bleed colour
    return img.convert("RGBa").resize((width, height), Image.BOX).convert("RGBA")


def weighted_distance(c1, c2):
    mean_r = (c1[0] + c2[0]) / 2
    dr, dg, db = (c1[i] - c2[i] for i in range(3))
    return (2 + mean_r / 256) * dr * dr + 4 * dg * dg + (2 + (255 - mean_r) / 256) * db * db


def to_rows(img, palette):
    rows = []
    for y in range(img.height):
        row = ""
        for x in range(img.width):
            r, g, b, a = img.getpixel((x, y))
            if a < ALPHA_MIN:
                row += "."
            else:
                row += min(palette, key=lambda k: weighted_distance((r, g, b), palette[k]))
        rows.append(row)
    return rows


def boost(img, contrast, saturation):
    """Contrast and colour saturation on the RGB channels; alpha is kept."""
    rgb = ImageEnhance.Color(ImageEnhance.Contrast(img.convert("RGB")).enhance(contrast)).enhance(saturation)
    out = rgb.convert("RGBA")
    out.putalpha(img.getchannel("A"))
    return out


def outline(rows, letter=OUTLINE_LETTER):
    """Pads the sprite by one pixel and paints every empty pixel that touches the figure (4 neighbours) with
    the outline letter, so the figure reads against any background."""
    w = len(rows[0]) + 2
    grid = ["." * w] + ["." + r + "." for r in rows] + ["." * w]
    out = []
    for y, row in enumerate(grid):
        line = ""
        for x, c in enumerate(row):
            near = [grid[y + dy][x + dx] for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))
                    if 0 <= x + dx < w and 0 <= y + dy < len(grid)]
            line += letter if c == "." and any(n not in (".", letter) for n in near) else c
        out.append(line)
    return out


def pixelize(path, sprite_id, height, tolerance, palette, contrast=1.0, saturation=1.0, ring=False):
    img = trim(key_out(Image.open(path), tolerance))
    img = trim(downscale(boost(img, contrast, saturation), height - (2 if ring else 0)))
    rows = to_rows(img, palette)
    return {"id": sprite_id, "palette": "main", "source": "gemini/flow picture via tools/art/pixelize.py",
            "licence": "project-own", "rows": outline(rows) if ring else rows}


def write_entry(out_path, entry):
    with open(out_path, encoding="utf-8") as f:
        data = json.load(f)
    data["items"] = [i for i in data["items"] if i["id"] != entry["id"]] + [entry]
    with open(out_path, "w", encoding="utf-8", newline="\n") as f:
        json.dump(data, f, indent=1)
        f.write("\n")


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--in", dest="src", required=True)
    ap.add_argument("--id", required=True)
    ap.add_argument("--height", type=int, default=64)
    ap.add_argument("--tolerance", type=int, default=40)
    ap.add_argument("--palette", default="content/art/palette.json")
    ap.add_argument("--out")
    ap.add_argument("--contrast", type=float, default=1.0)
    ap.add_argument("--saturation", type=float, default=1.0)
    ap.add_argument("--outline", action="store_true", help="ring the figure with the dark outline letter")
    args = ap.parse_args(argv)
    entry = pixelize(args.src, args.id, args.height, args.tolerance, load_palette(args.palette),
                     args.contrast, args.saturation, args.outline)
    if args.out:
        write_entry(args.out, entry)
        print("wrote %s (%dx%d) to %s" % (args.id, len(entry["rows"][0]), len(entry["rows"]), args.out))
    else:
        print(json.dumps(entry, indent=1))
    return 0


if __name__ == "__main__":
    sys.exit(main())
