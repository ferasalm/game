#!/usr/bin/env python
"""Transliterate Arabic to Musnad (Old South Arabian) letter by letter; scan files for Arabic.
Usage: python tools/musnad.py "text" | python tools/musnad.py --scan"""
import os
import re
import sys

MAP = {"ا": 0x10A71, "ب": 0x10A68, "ت": 0x10A69, "ث": 0x10A7B, "ج": 0x10A74, "ح": 0x10A62,
       "خ": 0x10A6D, "د": 0x10A75, "ذ": 0x10A79, "ر": 0x10A67, "ز": 0x10A78, "س": 0x10A66,
       "ش": 0x10A6A, "ص": 0x10A6E, "ض": 0x10A73, "ط": 0x10A77, "ظ": 0x10A7C, "ع": 0x10A72,
       "غ": 0x10A76, "ف": 0x10A70, "ق": 0x10A64, "ك": 0x10A6B, "ل": 0x10A61, "م": 0x10A63,
       "ن": 0x10A6C, "ه": 0x10A60, "و": 0x10A65, "ي": 0x10A7A,
       "أ": 0x10A71, "إ": 0x10A71, "آ": 0x10A71, "ء": 0x10A71, "ة": 0x10A60, "ى": 0x10A7A}
DROP = set("ًٌٍَُِّْـٰ")
ARABIC = re.compile("[؀-ۿݐ-ݿﭐ-﷿ﹰ-﻿]")


def to_musnad(text: str) -> str:
    out = []
    for ch in text:
        if ch in DROP:
            continue
        out.append(chr(MAP[ch]) if ch in MAP else ch)
    return "".join(out)


def scan() -> int:
    bad = 0
    for d, ds, fs in os.walk("."):
        ds[:] = [x for x in ds if x not in (".godot", ".claude", ".git", "inbox", "tools", "docs")]
        for f in fs:
            if f.endswith((".csv", ".json", ".gd", ".tscn", ".tres")):
                p = os.path.join(d, f)
                if ARABIC.search(open(p, encoding="utf8").read()):
                    print(p)
                    bad += 1
    return bad


if __name__ == "__main__":
    if sys.argv[1:] == ["--scan"]:
        sys.exit(1 if scan() else 0)
    sys.stdout.reconfigure(encoding="utf8")
    print(to_musnad(" ".join(sys.argv[1:])))
