#!/usr/bin/env python3
"""Turn a Gemini/Flow PNG into a palette-locked pixel sprite entry for content/art/sprites.json.

Usage: python tools/art/pixelize.py --in PIC.png --id my_sprite [--height 32] [--tolerance 40]
       [--palette content/art/palette.json] [--out content/art/sprites.json]
Steps: key out the corner colour, trim, box-downscale to --height, snap each pixel to the nearest palette colour.
"""
import argparse
import json
import sys

from PIL import Image

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


def pixelize(path, sprite_id, height, tolerance, palette):
    img = trim(key_out(Image.open(path), tolerance))
    img = trim(downscale(img, height))
    return {"id": sprite_id, "palette": "main", "source": "gemini/flow picture via tools/art/pixelize.py",
            "licence": "project-own", "rows": to_rows(img, palette)}


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
    ap.add_argument("--height", type=int, default=32)
    ap.add_argument("--tolerance", type=int, default=40)
    ap.add_argument("--palette", default="content/art/palette.json")
    ap.add_argument("--out")
    args = ap.parse_args(argv)
    entry = pixelize(args.src, args.id, args.height, args.tolerance, load_palette(args.palette))
    if args.out:
        write_entry(args.out, entry)
        print("wrote %s (%dx%d) to %s" % (args.id, len(entry["rows"][0]), len(entry["rows"]), args.out))
    else:
        print(json.dumps(entry, indent=1))
    return 0


if __name__ == "__main__":
    sys.exit(main())
