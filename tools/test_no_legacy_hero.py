#!/usr/bin/env python3
"""Guard: the hero's old code id stays gone (renamed to rydan, save v7, Feras 2026-10-27). Fails on the old id in the
text of game code, content, localization, tools and tests, or in any tracked file name outside docs/. Allowed: the
save migration and its old fixtures, the story officer's own id and a real external picture's name.
Run: python tools/test_no_legacy_hero.py (tool_tests in check.sh runs it)."""
import pathlib
import re
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
OLD = "za" + "yd"  # spelled apart so this file does not trip itself
SCANNED = ("features/", "core/", "content/", "localization/", "tools/", "tests/", "project.godot")
ALLOWED_FILES = {"core/save/save_codec.gd"}  # LEGACY_HERO: the v6 -> v7 step renames the old id
ALLOWED_PREFIXES = ("core/tests/fixtures/save_v",)  # saves written before v7; never edited
ALLOWED_WORDS = re.compile(r"officer_" + OLD + r"|flow_" + OLD + r"_full_a")  # the story officer; inbox picture name
FIND = re.compile(OLD, re.I)


def hits(path: str, text: str) -> list[str]:
    """Lines of text that name the old id once the allowed words are taken out."""
    if path in ALLOWED_FILES or path.startswith(ALLOWED_PREFIXES):
        return []
    return [f"{path}:{n}: {line.strip()[:120]}" for n, line in enumerate(text.splitlines(), 1)
            if FIND.search(ALLOWED_WORDS.sub("", line))]


def scan() -> list[str]:
    files = subprocess.run(["git", "-C", str(ROOT), "ls-files"], capture_output=True, text=True).stdout.splitlines()
    bad = [f"file name: {f}" for f in files if FIND.search(ALLOWED_WORDS.sub("", f)) and not f.startswith("docs/")
           and not f.startswith(ALLOWED_PREFIXES)]
    for f in files:
        if f.startswith(SCANNED) and not f.endswith((".png", ".jpg", ".webp", ".ogg", ".wav", ".glb", ".ogv", ".bin")):
            try:
                bad += hits(f, (ROOT / f).read_text(encoding="utf-8"))
            except (UnicodeDecodeError, FileNotFoundError):
                continue
    return bad


def main() -> int:
    fails = []
    planted = hits("content/combat/combatants.json", '{"id": "%s", "name_key": "NAME_X"}' % OLD)
    if len(planted) != 1:
        fails.append(f"a planted old id was not caught: {planted}")
    if hits("features/x.gd", f'var officer: StringName = &"officer_{OLD}"'):
        fails.append("the officer's own id was flagged")
    if hits("core/tests/fixtures/save_v5.json", f'"party": ["{OLD}"]'):
        fails.append("an old save fixture was flagged")
    fails += scan()
    for f in fails:
        print("FAIL", f)
    print("test_no_legacy_hero:", "FAIL" if fails else "ok")
    return 1 if fails else 0


if __name__ == "__main__":
    sys.exit(main())
