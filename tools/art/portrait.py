#!/usr/bin/env python3
"""Turn a Gemini portrait (flat background colour) into a game portrait.

Keys out the background colour sampled from the four corners, trims to the figure, resizes to a target height
(Lanczos), saves assets/portraits/<speaker>_<expression>.png with its .import file (importer="keep"), and adds
or replaces the entry in assets/manifest.json. See docs/design/portrait-prompts.md.

  python tools/art/portrait.py --in gemini.png --speaker zayd --expression happy --licence "Gemini, owner-generated" --prompt-id zayd_happy_v1
"""
import argparse, json, pathlib, sys
from PIL import Image, ImageChops, ImageFilter

ROOT = pathlib.Path(__file__).resolve().parent.parent.parent
EXPRESSIONS = ("neutral", "happy", "angry", "surprised")
DESPILL_REACH = 6  # pixels from the cut-out edge that lose the background colour cast


def corner_colour(img: Image.Image) -> tuple[int, int, int]:
    """The per-channel median of the four corner pixels."""
    w, h = img.size
    corners = [img.getpixel(p)[:3] for p in ((0, 0), (w - 1, 0), (0, h - 1), (w - 1, h - 1))]
    return tuple(sorted(c[i] for c in corners)[1] for i in range(3))


def key_out(img: Image.Image, tolerance: int) -> Image.Image:
    """RGBA copy where pixels within tolerance of the background are transparent (soft edge up to 2x tolerance)."""
    rgb = img.convert("RGB")
    diff = ImageChops.difference(rgb, Image.new("RGB", rgb.size, corner_colour(rgb)))
    r, g, b = diff.split()
    distance = ImageChops.lighter(ImageChops.lighter(r, g), b)
    span = max(tolerance, 1)
    alpha = distance.point(lambda d: 0 if d <= tolerance else min(255, (d - tolerance) * 255 // span))
    out = rgb.convert("RGBA")
    out.putalpha(alpha)
    return despill(out, corner_colour(rgb), DESPILL_REACH)


def despill(img: Image.Image, bg: tuple[int, int, int], reach: int) -> Image.Image:
    """Near the cut-out edge, clamps the background's strongest channel to the larger of the other two, so hair
    strands lose the green (or blue) fringe; colours deeper inside the figure (green eyes) are untouched."""
    c = bg.index(max(bg))
    near = img.getchannel("A").filter(ImageFilter.MinFilter(2 * reach + 1)).point(lambda a: 255 if a < 255 else 0)
    bands = list(img.split())
    others = ImageChops.lighter(*[bands[i] for i in range(3) if i != c])
    bands[c] = Image.composite(ImageChops.darker(bands[c], others), bands[c], near)
    return Image.merge("RGBA", bands)


def make_portrait(img: Image.Image, tolerance: int, height: int) -> Image.Image:
    keyed = key_out(img, tolerance)
    box = keyed.getchannel("A").getbbox()
    if box is None:
        raise ValueError("nothing left after keying out the background; lower --tolerance")
    figure = keyed.crop(box)
    width = max(1, round(figure.width * height / figure.height))
    return figure.resize((width, height), Image.LANCZOS)


def write_import(png: pathlib.Path) -> None:
    with open(str(png) + ".import", "w", newline="\n", encoding="utf-8") as f:
        f.write('[remap]\n\nimporter="keep"\n')


def update_manifest(assets: pathlib.Path, rel: str, source: str, licence: str, prompt_id: str) -> None:
    path = assets / "manifest.json"
    data = json.loads(path.read_text(encoding="utf-8")) if path.exists() else {"assets": []}
    entry = {"id": pathlib.PurePosixPath(rel).stem, "path": rel, "source": source, "licence": licence, "prompt": prompt_id}
    data["assets"] = [e for e in data["assets"] if e.get("path") != rel] + [entry]
    with open(path, "w", newline="\n", encoding="utf-8") as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
        f.write("\n")


def run(args: argparse.Namespace) -> pathlib.Path:
    if args.expression not in EXPRESSIONS:
        raise ValueError(f"expression must be one of {', '.join(EXPRESSIONS)}")
    assets = pathlib.Path(args.assets)
    rel = f"portraits/{args.speaker}_{args.expression}.png"
    out = assets / rel
    out.parent.mkdir(parents=True, exist_ok=True)
    make_portrait(Image.open(args.input), args.tolerance, args.height).save(out)
    write_import(out)
    update_manifest(assets, rel, args.source, args.licence, args.prompt_id)
    return out


def main() -> int:
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--in", dest="input", required=True, help="Gemini picture with a flat background")
    p.add_argument("--speaker", required=True, help="speaker id, e.g. zayd")
    p.add_argument("--expression", required=True, help="|".join(EXPRESSIONS))
    p.add_argument("--licence", required=True, help='licence text for the manifest, e.g. "Gemini, owner-generated"')
    p.add_argument("--prompt-id", default="", help="id of the prompt in docs/design/portrait-prompts.md")
    p.add_argument("--source", default="gemini")
    p.add_argument("--tolerance", type=int, default=40, help="background match, 0-255 per channel (default 40)")
    p.add_argument("--height", type=int, default=720, help="output height in pixels (default 720)")
    p.add_argument("--assets", default=str(ROOT / "assets"), help="assets folder (default: the repo's)")
    try:
        out = run(p.parse_args())
    except (ValueError, OSError) as err:
        print(f"portrait.py: {err}", file=sys.stderr)
        return 1
    print(f"wrote {out}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
