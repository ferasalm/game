#!/usr/bin/env python3
"""Bandwidth guard (Feras 10-30: his internet is metered): git sends only new objects, so a sync costs kilobytes until
someone commits a big binary; then that file's every version is uploaded and downloaded once and kept forever.
Rule: no tracked file over 10 MB; over 2 MB only under assets/ (a listed asset). Renders, videos and exports stay
git-ignored (inbox/, export/). python tools/test_file_sizes.py"""
import os
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
HARD = 10 * 1024 * 1024
SOFT = 2 * 1024 * 1024


def offenders(sizes):
    """[(path, why)] for {path: bytes} that break the rule."""
    bad = []
    for path, n in sorted(sizes.items()):
        if n > HARD:
            bad.append((path, f"{n / 1048576:.1f} MB > 10 MB"))
        elif n > SOFT and not path.startswith("assets/"):
            bad.append((path, f"{n / 1048576:.1f} MB > 2 MB outside assets/"))
    return bad


def tracked_sizes():
    out = subprocess.run(["git", "-C", ROOT, "ls-files", "-z"], capture_output=True, text=True, check=True).stdout
    sizes = {}
    for p in filter(None, out.split("\0")):
        try:
            sizes[p] = os.path.getsize(os.path.join(ROOT, p))
        except OSError:
            pass  # deleted in the working tree, not yet committed
    return sizes


def test_rule_catches_big_files():  # probe each rule with one bad case (LESSONS 3)
    bad = offenders({"assets/a.glb": 3 * 1024 * 1024, "inbox/clip.mp4": 3 * 1024 * 1024,
                     "assets/huge.ogv": 11 * 1024 * 1024, "docs/x.md": 1000})
    assert [p for p, _ in bad] == ["assets/huge.ogv", "inbox/clip.mp4"], bad


def test_no_tracked_file_breaks_the_rule():
    bad = offenders(tracked_sizes())
    assert not bad, "big files cost Feras's metered bandwidth: " + "; ".join(f"{p} ({w})" for p, w in bad)


if __name__ == "__main__":
    tests = [v for k, v in sorted(globals().items()) if k.startswith("test_")]
    for t in tests:
        t()
    print(f"test_file_sizes: {len(tests)} tests passed")
    sys.exit(0)
