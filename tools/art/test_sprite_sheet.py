"""Tests tools/art/sprite_sheet.py with tiny generated frames. Run: python tools/art/test_sprite_sheet.py"""
import json
import os
import subprocess
import sys
import tempfile

from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
PX = 16
FRAMES = 3


def make_frames(src: str) -> int:
    """8 directions x FRAMES frames, each a different colour square; returns the unique opaque colours made."""
    n = 0
    for d in range(8):
        for f in range(FRAMES):
            im = Image.new("RGBA", (PX, PX), (0, 0, 0, 0))
            colour = (10 + d * 20, 30 + f * 40, 200 - d * 10, 255)
            for x in range(4, 12):
                for y in range(4, 12):
                    im.putpixel((x, y), colour)
            im.save(os.path.join(src, "t_idle_d%d_f%d.png" % (d, f)))
            n += 1
    return n


def run(src: str, out: str, *extra: str) -> list:
    res = subprocess.run([sys.executable, os.path.join(HERE, "sprite_sheet.py"), src, "t", out, str(PX), "2.6", *extra],
                         capture_output=True, text=True, check=True)
    return [json.loads(line) for line in res.stdout.splitlines()]


def unique_colours(path: str) -> int:
    with Image.open(path) as raw:
        im = raw.convert("RGBA")
    return len({p for p in im.getdata() if p[3] > 0})


def check(cond: bool, msg: str) -> None:
    if not cond:
        print("FAIL", msg)
        sys.exit(1)
    print("ok", msg)


def main() -> None:
    with tempfile.TemporaryDirectory() as tmp:
        src, full, quant = (os.path.join(tmp, n) for n in ("src", "full", "quant"))
        os.makedirs(src)
        make_frames(src)
        rows = run(src, full)
        check(len(rows) == 1 and rows[0]["state"] == "idle", "one jsonl row for the idle state")
        check(rows[0]["frames"] == FRAMES, "frame count %d" % FRAMES)
        with Image.open(os.path.join(full, "t_idle.png")) as sheet:
            check(sheet.size == (rows[0]["frame_w"] * FRAMES, rows[0]["frame_h"] * 8), "sheet size = cells x 3 by 8")
            check(sheet.mode == "RGBA", "default sheet is full-colour RGBA")
        check(unique_colours(os.path.join(full, "t_idle.png")) == 24, "colours=0 keeps all 24 colours")
        rows = run(src, quant, "4")
        with Image.open(os.path.join(quant, "t_idle.png")) as q:
            check(q.mode == "P", "colours=4 quantizes to a palette")
        check(unique_colours(os.path.join(quant, "t_idle.png")) <= 4, "colours=4 caps the colours")
        empty = os.path.join(tmp, "empty")
        os.makedirs(empty)
        Image.new("RGBA", (PX, PX), (0, 0, 0, 0)).save(os.path.join(empty, "t_idle_d0_f0.png"))
        res = subprocess.run([sys.executable, os.path.join(HERE, "sprite_sheet.py"), empty, "t", tmp + "/o"], capture_output=True, text=True)
        check(res.returncode != 0 and "no opaque pixel" in res.stderr, "an all-transparent state fails with a reason")
        res = subprocess.run([sys.executable, os.path.join(HERE, "sprite_sheet.py"), tmp + "/none", "t", tmp + "/o"], capture_output=True, text=True)
        check(res.returncode != 0 and "no t_" in res.stderr, "no frames at all fails with a reason")
        fake = os.path.join(tmp, "godot.sh")
        with open(fake, "w", newline="\n") as f:
            f.write("#!/bin/bash\necho baking\n")  # a Godot that bakes nothing
        os.chmod(fake, 0o755)
        res = subprocess.run(["bash", os.path.join(HERE, "bake_all.sh"), tmp.replace("\\", "/") + "/b", "t", "idle:2:1"],
                             capture_output=True, text=True, env={**os.environ, "GODOT_BIN": fake.replace("\\", "/")}, stdin=subprocess.DEVNULL)
        check(res.returncode != 0 and "FAIL t bake" in res.stderr, "bake_all exits non-zero when a bake made no frames")


if __name__ == "__main__":
    main()
