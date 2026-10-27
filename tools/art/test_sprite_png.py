#!/usr/bin/env python3
"""Self-test for sprite_png.py: python tools/art/test_sprite_png.py (plain asserts, exits non-zero on failure)."""
import json
import os
import shutil
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from PIL import Image  # noqa: E402

import sprite_png  # noqa: E402

ART = os.path.join(HERE, "..", "..", "content", "art")


def main():
    tmp = tempfile.mkdtemp()
    try:
        sprites = os.path.join(tmp, "sprites.json")
        shutil.copy(os.path.join(ART, "sprites.json"), sprites)
        common = ["--sprites", sprites, "--palette", os.path.join(ART, "palette.json")]
        before = sprite_png.find(sprite_png.read_sprites(sprites), "rydan")
        png = os.path.join(tmp, "rydan.png")
        assert sprite_png.main(["export", "--id", "rydan", "--png", png] + common) == 0
        assert sprite_png.main(["import", "--id", "rydan", "--png", png] + common) == 0
        after = sprite_png.find(sprite_png.read_sprites(sprites), "rydan")
        assert after["rows"] == before["rows"], "round trip changed the pixels"
        assert after["licence"] == before["licence"] and "hand-edited" in after["source"]

        img = Image.open(png).convert("RGBA")
        img.putpixel((8, 10), (1, 2, 3, 255))  # a colour outside the palette
        img.save(png)
        assert sprite_png.main(["import", "--id", "rydan", "--png", png] + common) == 1, "stray colour accepted"
        assert sprite_png.main(["import", "--id", "rydan", "--png", png, "--snap"] + common) == 0

        gpl = os.path.join(tmp, "main.gpl")
        assert sprite_png.main(["palette", "--out", gpl] + common) == 0
        with open(os.path.join(ART, "palette.json"), encoding="utf-8") as f:
            count = len(json.load(f)["items"][0]["colors"])
        with open(gpl, encoding="utf-8") as f:
            assert len(f.read().splitlines()) == 4 + count, "palette file lacks colours"
    finally:
        shutil.rmtree(tmp)
    print("sprite_png: all tests passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
