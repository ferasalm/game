"""Player's-eye metrics for Neon clips and UI fonts (report only; always exits 0)."""
import argparse
import glob
import json
import os
import re
import subprocess
import sys

from PIL import Image

FONT_RE = re.compile(r"(?:^|[\s/])(?:default_)?font_size\s*=\s*(\d+)", re.MULTILINE)


def emit(name: str, value: object, verdict: str, bar: str) -> None:
    print("METRIC %s %s %s %s" % (name, value, verdict, bar))


def git_root() -> str:
    try:
        res = subprocess.run(["git", "rev-parse", "--show-toplevel"], capture_output=True, text=True)
        if res.returncode == 0 and res.stdout.strip():
            return res.stdout.strip()
    except OSError:
        pass
    return os.getcwd()


def clips(root: str) -> list:
    path = os.path.join(root, "content", "neon", "sprites.json")
    try:
        with open(path, encoding="utf-8") as handle:
            data = json.load(handle)
    except (OSError, ValueError):
        return []
    out = []
    for item in (data.get("items", []) if isinstance(data, dict) else []):
        for state in item.get("states", []):
            out.append((item.get("id", ""), state))
    return out


def sheet_metrics(base: str, state: dict, root: str) -> None:
    sheet = str(state.get("sheet", ""))
    rel = sheet[len("res://"):] if sheet.startswith("res://") else sheet
    path = os.path.join(root, rel)
    if not os.path.isfile(path):
        emit("sheet_missing:%s" % base, 0, "WARN", "exists")
        return
    try:
        with Image.open(path) as image:
            has_alpha = image.mode in ("RGBA", "LA") or (image.mode == "P" and "transparency" in image.info)
            rgba = image.convert("RGBA")
    except (OSError, ValueError):
        emit("sheet_missing:%s" % base, 0, "WARN", "exists")
        return
    opaque = [px for px in rgba.getdata() if px[3] > 0]
    colours = len({px[:3] for px in opaque})
    emit("sheet_colours:%s" % base, colours, "PASS" if colours > 256 else "WARN", ">256")
    emit("sheet_alpha:%s" % base, "yes" if has_alpha else "no", "PASS" if has_alpha else "WARN", "alpha")
    if opaque:
        chroma = sum(max(px[0], px[1], px[2]) - min(px[0], px[1], px[2]) for px in opaque) / len(opaque)
    else:
        chroma = 0.0
    emit("sheet_chroma:%s" % base, "%.1f" % chroma, "PASS", "info")


def clip_metrics(root: str) -> None:
    for item_id, state in clips(root):
        base = "%s:%s" % (item_id, state.get("state", ""))
        fps = state.get("fps", 0)
        emit("clip_fps:%s" % base, fps, "PASS" if fps >= 24 else "WARN", ">=24")
        emit("clip_frames:%s" % base, state.get("frames", 0), "PASS", "info")
        emit("clip_px:%s" % base, "%sx%s" % (state.get("frame_w", 0), state.get("frame_h", 0)), "PASS", "info")
        sheet_metrics(base, state, root)


def font_min(root: str) -> None:
    values = []
    for pattern in ("**/*.tscn", "**/*.tres"):
        for path in glob.glob(os.path.join(glob.escape(root), "features", pattern), recursive=True):
            try:
                with open(path, encoding="utf-8", errors="ignore") as handle:
                    values.extend(int(n) for n in FONT_RE.findall(handle.read()))
            except OSError:
                continue
    if not values:
        emit("font_min", "none", "PASS", ">=18")
        return
    smallest = min(values)
    emit("font_min", smallest, "PASS" if smallest >= 18 else "WARN", ">=18")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", default=None)
    args, _ = parser.parse_known_args()
    root = args.root or git_root()
    for part in (clip_metrics, font_min):  # a report never fails the build, and one part never hides the other
        try:
            part(root)
        except Exception as err:
            print("METRIC error:%s 0 WARN %s" % (part.__name__, type(err).__name__))
    return 0


if __name__ == "__main__":
    sys.exit(main())
