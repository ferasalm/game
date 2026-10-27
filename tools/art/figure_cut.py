#!/usr/bin/env python3
"""Cut one painted full-body figure out of a Flow picture on green (look spike: a static painted billboard).

  python tools/art/figure_cut.py --in inbox/flow_zayd_full_a.png --id rydan [--half left] [--height 640]

Keys out the green with portrait.py's soft keyer and despill, trims, resizes (Lanczos) and writes
assets/textures/painted/figures/<id>.webp (lossless, with alpha) plus its assets/manifest.json entry.
"""
import argparse, pathlib, sys
from PIL import Image

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import portrait  # noqa: E402

ROOT = pathlib.Path(__file__).resolve().parent.parent.parent
SOURCE = "google flow, owner-generated"
LICENCE = "Google Flow output, owner-generated; check Flow terms before a commercial release"


def cut(img: Image.Image, half: str, tolerance: int, height: int) -> Image.Image:
    if half == "left":
        img = img.crop((0, 0, img.width // 2, img.height))
    elif half == "right":
        img = img.crop((img.width // 2, 0, img.width, img.height))
    return portrait.make_portrait(img, tolerance, height)


def main(argv=None) -> int:
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--in", dest="input", required=True)
    p.add_argument("--id", required=True)
    p.add_argument("--half", choices=("left", "right", "all"), default="left", help="Flow sheets hold two takes")
    p.add_argument("--tolerance", type=int, default=60)
    p.add_argument("--height", type=int, default=640)
    p.add_argument("--assets", default=str(ROOT / "assets"))
    args = p.parse_args(argv)
    assets = pathlib.Path(args.assets)
    rel = f"textures/painted/figures/{args.id}.webp"
    out = assets / rel
    out.parent.mkdir(parents=True, exist_ok=True)
    cut(Image.open(args.input), args.half, args.tolerance, args.height).save(out, lossless=True)
    portrait.update_manifest(assets, rel, SOURCE, LICENCE, pathlib.Path(args.input).name)
    print(f"wrote {out}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
