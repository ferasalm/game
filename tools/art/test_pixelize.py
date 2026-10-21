#!/usr/bin/env python3
"""Self-test for pixelize.py: python tools/art/test_pixelize.py (plain asserts, exits non-zero on failure)."""
import json
import os
import sys
import tempfile

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from PIL import Image, ImageDraw  # noqa: E402

import pixelize  # noqa: E402

PALETTE = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "content", "art", "palette.json")


def main():
    palette = pixelize.load_palette(PALETTE)
    with tempfile.TemporaryDirectory() as tmp:
        src = os.path.join(tmp, "in.png")
        img = Image.new("RGB", (200, 300), (250, 250, 250))  # background
        d = ImageDraw.Draw(img)
        d.rectangle((60, 40, 140, 260), fill=(200, 50, 50))  # body
        d.rectangle((80, 20, 120, 60), fill=(220, 170, 120))  # head
        img.save(src)
        entry = pixelize.pixelize(src, "test_sprite", 32, 40, palette)
        out = os.path.join(tmp, "sprites.json")
        with open(out, "w", encoding="utf-8") as f:
            json.dump({"kind": "sprite", "items": []}, f)
        pixelize.write_entry(out, entry)
        pixelize.write_entry(out, entry)  # replace, not duplicate
        with open(out, encoding="utf-8") as f:
            assert len(json.load(f)["items"]) == 1, "entry replaced, not appended twice"
    rows = entry["rows"]
    assert len(rows) == 32, "height is %d" % len(rows)
    assert len({len(r) for r in rows}) == 1, "rows have equal width"
    assert set("".join(rows)) <= set(palette) | {"."}, "only palette letters"
    assert any(c != "." for c in rows[0]), "top row has pixels (trimmed)"
    assert any(c != "." for c in rows[-1]), "bottom row has pixels (trimmed)"
    assert any(r[0] != "." for r in rows), "left edge trimmed"
    assert any(r[-1] != "." for r in rows), "right edge trimmed"
    assert "." in "".join(rows), "background keyed out"
    assert pixelize.outline(["a."]) == [".k..", "kak.", ".k.."], "one pixel gets a 4-neighbour ring"
    assert pixelize.outline([".a.", "aaa"]) == ["..k..", ".kak.", "kaaak", ".kkk."], "4-neighbour ring"
    print("pixelize self-test ok")


if __name__ == "__main__":
    main()
