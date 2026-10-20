#!/usr/bin/env python3
"""Edit a sprite in a pixel editor (Pixelorama): export it to PNG, paint, import it back, losslessly.

Usage: python tools/art/sprite_png.py export --id zayd --png zayd.png [--scale 1]
       python tools/art/sprite_png.py import --id zayd --png zayd.png [--snap] [--source TEXT]
       python tools/art/sprite_png.py palette --out main.gpl   (load it in Pixelorama: paint only these colours)
Import never resizes. Transparent pixels become '.'; any colour not in the palette is an error that lists
where it is, unless --snap moves it to the nearest palette colour. Other fields of the entry are kept.
"""
import argparse
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from PIL import Image  # noqa: E402

import pixelize  # noqa: E402

SPRITES = "content/art/sprites.json"
PALETTE = "content/art/palette.json"


def read_sprites(path):
    with open(path, encoding="utf-8") as f:
        return json.load(f)


def find(data, sprite_id):
    for item in data["items"]:
        if item["id"] == sprite_id:
            return item
    return None


def export_png(rows, palette, png_path, scale=1):
    img = Image.new("RGBA", (len(rows[0]), len(rows)), (0, 0, 0, 0))
    for y, row in enumerate(rows):
        for x, letter in enumerate(row):
            if letter != ".":
                img.putpixel((x, y), palette[letter] + (255,))
    if scale > 1:
        img = img.resize((img.width * scale, img.height * scale), Image.NEAREST)
    img.save(png_path)


def png_rows(png_path, palette, snap=False):
    """The PNG as palette rows, and a list of 'x,y #rrggbb' for each colour outside the palette."""
    img = Image.open(png_path).convert("RGBA")
    exact = {rgb: letter for letter, rgb in palette.items()}
    rows, strays = [], []
    for y in range(img.height):
        row = ""
        for x in range(img.width):
            r, g, b, a = img.getpixel((x, y))
            if a < pixelize.ALPHA_MIN:
                row += "."
            elif (r, g, b) in exact:
                row += exact[(r, g, b)]
            elif snap:
                row += min(palette, key=lambda k: pixelize.weighted_distance((r, g, b), palette[k]))
            else:
                strays.append("%d,%d #%02x%02x%02x" % (x, y, r, g, b))
                row += "."
        rows.append(row)
    return rows, strays


def write_sprites(path, data):
    with open(path, "w", encoding="utf-8", newline="\n") as f:
        json.dump(data, f, indent=1)
        f.write("\n")


def write_gpl(palette, out_path):
    with open(out_path, "w", encoding="utf-8", newline="\n") as f:
        f.write("GIMP Palette\nName: qarnaw-main\nColumns: 8\n#\n")
        for letter, (r, g, b) in palette.items():
            f.write("%3d %3d %3d %s\n" % (r, g, b, letter))


def run_import(args, palette):
    data = read_sprites(args.sprites)
    rows, strays = png_rows(args.png, palette, args.snap)
    if strays:
        print("%d pixel(s) not in the palette (x,y colour), e.g. %s; repaint them or pass --snap"
              % (len(strays), "; ".join(strays[:8])))
        return 1
    entry = find(data, args.id)
    if entry is None:
        entry = {"id": args.id, "palette": "main", "source": args.source or "own (hand-drawn)",
                 "licence": "project-own"}
        data["items"].append(entry)
    elif args.source:
        entry["source"] = args.source
    elif "hand-edited" not in entry.get("source", ""):
        entry["source"] = entry.get("source", "") + "; hand-edited (sprite_png.py)"
    entry["rows"] = rows
    write_sprites(args.sprites, data)
    print("imported %s (%dx%d) into %s" % (args.id, len(rows[0]), len(rows), args.sprites))
    return 0


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("command", choices=["export", "import", "palette"])
    ap.add_argument("--id")
    ap.add_argument("--png")
    ap.add_argument("--out")
    ap.add_argument("--scale", type=int, default=1)
    ap.add_argument("--snap", action="store_true")
    ap.add_argument("--source")
    ap.add_argument("--sprites", default=SPRITES)
    ap.add_argument("--palette", default=PALETTE)
    args = ap.parse_args(argv)
    palette = pixelize.load_palette(args.palette)
    if args.command == "palette":
        write_gpl(palette, args.out or "main.gpl")
        return 0
    if not (args.id and args.png):
        ap.error("export and import need --id and --png")
    if args.command == "import":
        return run_import(args, palette)
    entry = find(read_sprites(args.sprites), args.id)
    if entry is None:
        print("no sprite '%s' in %s" % (args.id, args.sprites))
        return 1
    export_png(entry["rows"], palette, args.png, args.scale)
    print("exported %s to %s" % (args.id, args.png))
    return 0


if __name__ == "__main__":
    sys.exit(main())
