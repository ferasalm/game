#!/usr/bin/env python3
"""Self-test for portrait.py on a synthetic picture in a temp dir; exit 1 on any failure."""
import argparse, json, pathlib, sys, tempfile
from PIL import Image, ImageDraw

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import portrait


def synthetic(path: pathlib.Path) -> None:
    img = Image.new("RGB", (200, 300), (30, 200, 60))  # flat green background
    ImageDraw.Draw(img).ellipse((60, 80, 140, 240), fill=(200, 120, 90))
    img.save(path)


def args_for(src: pathlib.Path, assets: pathlib.Path, **over) -> argparse.Namespace:
    base = dict(input=str(src), speaker="rydan", expression="happy", licence="test licence", prompt_id="p1",
                source="gemini", tolerance=40, height=120, assets=str(assets))
    base.update(over)
    return argparse.Namespace(**base)


def main() -> int:
    with tempfile.TemporaryDirectory() as tmp:
        tmp_path = pathlib.Path(tmp)
        src, assets = tmp_path / "in.png", tmp_path / "assets"
        synthetic(src)
        out = portrait.run(args_for(src, assets))
        img = Image.open(out)
        assert out.name == "rydan_happy.png", out
        assert img.mode == "RGBA" and img.height == 120, (img.mode, img.size)
        assert img.getpixel((0, 0))[3] == 0, "background corner must be transparent"
        assert img.getpixel((img.width // 2, img.height // 2))[3] == 255, "figure centre must be opaque"
        assert 40 <= img.width <= 100, f"trimmed width off: {img.width}"
        strip = Image.new("RGBA", (9, 1), (90, 160, 80, 255))
        strip.putpixel((0, 0), (30, 200, 60, 0))
        spill = portrait.despill(strip, (30, 200, 60), 2)
        assert spill.getpixel((2, 0))[:3] == (90, 90, 80), "a pixel near the cut-out edge must lose the green cast"
        assert spill.getpixel((8, 0))[:3] == (90, 160, 80), "a pixel deep inside the figure keeps its green"
        assert pathlib.Path(str(out) + ".import").read_text() == '[remap]\n\nimporter="keep"\n'
        portrait.run(args_for(src, assets, licence="second licence"))  # replaces, not duplicates
        manifest = json.loads((assets / "manifest.json").read_text())["assets"]
        assert len(manifest) == 1, manifest
        assert manifest[0]["licence"] == "second licence" and manifest[0]["source"] == "gemini", manifest
        assert manifest[0]["path"] == "portraits/rydan_happy.png" and manifest[0]["prompt"] == "p1", manifest
        try:
            portrait.run(args_for(src, assets, expression="sleepy"))
            raise AssertionError("bad expression must fail")
        except ValueError:
            pass
        blank = tmp_path / "blank.png"
        Image.new("RGB", (50, 50), (1, 2, 3)).save(blank)
        try:
            portrait.run(args_for(blank, assets))
            raise AssertionError("an empty picture must fail")
        except ValueError:
            pass
    print("test_portrait: ok")
    return 0


if __name__ == "__main__":
    sys.exit(main())
