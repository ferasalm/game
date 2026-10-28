#!/usr/bin/env python3
"""ContentDB loads every content/**/*.json and errors on a kind it does not know, which breaks boot and every Godot test
(10-28: a pipeline list put in content/ would have; it lives in tools/art/). This catches it without Godot."""
import glob
import json
import os
import re

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def known_kinds():
    with open(os.path.join(ROOT, "core", "content_db.gd"), encoding="utf-8") as f:
        text = f.read()
    block = text[text.index("const KINDS"):]
    block = block[:block.index("\n}")]
    return set(re.findall(r'^\s*"(\w+)":\s*preload\(', block, re.M))


def test_every_content_file_has_a_known_kind():
    kinds = known_kinds()
    assert len(kinds) > 20, f"KINDS parse found only {sorted(kinds)}"
    files = glob.glob(os.path.join(ROOT, "content", "**", "*.json"), recursive=True)
    assert files, "no content files found"
    for path in files:
        with open(path, encoding="utf-8") as f:
            kind = json.load(f).get("kind", "")
        rel = os.path.relpath(path, ROOT).replace("\\", "/")
        assert kind in kinds, f"{rel}: kind {kind!r} is not in ContentDB.KINDS (not game data? keep it out of content/)"


if __name__ == "__main__":
    tests = [v for k, v in sorted(globals().items()) if k.startswith("test_")]
    for t in tests:
        t()
    print(f"test_content_kinds: {len(tests)} tests passed")
