"""Tests tools/eye_metrics.py on a temp project root. Run: python tools/test_eye_metrics.py"""
import json
import os
import subprocess
import sys
import tempfile

from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))


def sheet(path: str, colours: int, alpha: bool) -> None:
    im = Image.new("RGBA", (20, 20), (0, 0, 0, 0))  # transparent background; RGB sheets are fully opaque
    n = 0
    for x in range(20):
        for y in range(20):
            if n < colours:
                im.putpixel((x, y), (n % 256, n // 256, 7, 255))
                n += 1
    if not alpha:
        flat = Image.new("RGB", im.size, (0, 0, 0))
        flat.paste(im, mask=im.getchannel("A"))
        im = flat
    im.save(path)


def project(root: str, fps: float, colours: int, alpha: bool, font: int) -> None:
    os.makedirs(os.path.join(root, "content/neon"))
    os.makedirs(os.path.join(root, "assets/s"))
    os.makedirs(os.path.join(root, "features/a/b"))
    sheet(os.path.join(root, "assets/s/h_idle.png"), colours, alpha)
    clip = {"state": "idle", "sheet": "res://assets/s/h_idle.png", "frame_w": 10, "frame_h": 20, "frames": 2, "fps": fps}
    data = {"kind": "neon_sprite_set", "items": [{"id": "h", "model": "h", "scale": 1.0, "states": [clip]}]}
    with open(os.path.join(root, "content/neon/sprites.json"), "w") as f:
        json.dump(data, f)
    with open(os.path.join(root, "features/a/b/x.tscn"), "w") as f:
        f.write('[node name="L" type="Label"]\ntheme_override_font_sizes/font_size = %d\nend_font_size = 3\n' % font)
    with open(os.path.join(root, "features/a/y.tres"), "w") as f:
        f.write("[resource]\nfont_size = 40\n")


def metrics(root: str) -> dict:
    res = subprocess.run([sys.executable, os.path.join(HERE, "eye_metrics.py"), "--root", root], capture_output=True, text=True)
    assert res.returncode == 0, "exit code must always be 0: %s" % res.stderr
    out = {}
    for line in res.stdout.splitlines():
        parts = line.split(maxsplit=4)
        if parts and parts[0] == "METRIC":
            out[parts[1]] = parts[2:]  # value, verdict, bar
    return out


def check(cond: bool, msg: str) -> None:
    if not cond:
        print("FAIL", msg)
        sys.exit(1)
    print("ok", msg)


def main() -> None:
    with tempfile.TemporaryDirectory() as tmp:
        bad = os.path.join(tmp, "bad")
        project(bad, 12.0, 10, True, 16)
        m = metrics(bad)
        check(m["clip_fps:h:idle"][:2] == ["12.0", "WARN"] or m["clip_fps:h:idle"][:2] == ["12", "WARN"], "fps 12 warns")
        check(m["clip_frames:h:idle"][0] == "2", "frames reported")
        check(m["clip_px:h:idle"][0] == "10x20", "frame px reported as WxH")
        check(m["sheet_colours:h:idle"][:2] == ["10", "WARN"], "10 colours warns (bar > 256)")
        check(m["font_min"][:2] == ["16", "WARN"], "smallest font 16 warns; end_font_size is ignored")
        good = os.path.join(tmp, "good")
        project(good, 30.0, 300, True, 20)
        m = metrics(good)
        check(m["clip_fps:h:idle"][1] == "PASS", "fps 30 passes")
        check(m["sheet_colours:h:idle"][:2] == ["300", "PASS"], "300 colours passes")
        check(m["sheet_alpha:h:idle"][1] == "PASS", "alpha sheet passes")
        check(m["font_min"][:2] == ["20", "PASS"], "font 20 passes")
        flat = os.path.join(tmp, "flat")
        project(flat, 30.0, 300, False, 20)
        check(metrics(flat)["sheet_alpha:h:idle"][1] == "WARN", "a sheet without alpha warns")
        with open(os.path.join(flat, "content/neon/view.json"), "w") as f:
            json.dump({"alert_font_size": 14, "font_sizes": 3}, f)
        check(metrics(flat)["font_min"][:2] == ["14", "WARN"], "a content JSON font size 14 warns (key ends font_size)")
        empty = os.path.join(tmp, "empty")
        os.makedirs(empty)
        res = subprocess.run([sys.executable, os.path.join(HERE, "eye_metrics.py"), "--root", empty], capture_output=True, text=True)
        check(res.returncode == 0, "an empty root still exits 0")


if __name__ == "__main__":
    main()
