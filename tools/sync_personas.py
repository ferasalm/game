#!/usr/bin/env python3
"""Copies the 10 Neon Glitch personas from their one source (.agents/skills/<name>/SKILL.md) to .claude/skills/<name>/SKILL.md
(verbatim) and .claude/agents/<name>.md (name + description + the source body); --check fails on drift (row 1 item 9, Feras 10-28).

Edit only the source, then run this. Usage: python tools/sync_personas.py [--check]
"""
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
PERSONAS = ("game-designer", "narrative-designer", "technical-artist", "level-designer", "game-audio-engineer",
            "godot-gameplay-scripter", "godot-shader-developer", "blender-addon-engineer", "ui-designer",
            "ui-finish-gate-reviewer")


def split(text):
    """(frontmatter dict, body) of a SKILL.md: name and description only."""
    m = re.match(r"---\n(.*?)\n---\n", text, re.S)
    if not m:
        return {}, text
    meta = {}
    for line in m.group(1).splitlines():
        key, _, value = line.partition(":")
        meta[key.strip()] = value.strip().strip("'\"")
    return meta, text[m.end():]


def outputs(name):
    """{path: text} this persona's source should produce."""
    src = (ROOT / ".agents/skills" / name / "SKILL.md").read_text(encoding="utf-8")
    meta, body = split(src)
    agent = f"---\nname: {name}\ndescription: {meta.get('description', '')}\n---\n{body}"
    return {ROOT / ".claude/skills" / name / "SKILL.md": src, ROOT / ".claude/agents" / f"{name}.md": agent}


def main(check):
    stale = []
    for name in PERSONAS:
        for path, text in outputs(name).items():
            old = path.read_text(encoding="utf-8") if path.exists() else None
            if old == text:
                continue
            stale.append(str(path.relative_to(ROOT)))
            if not check:
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_text(text, encoding="utf-8", newline="\n")
    if check and stale:
        print("FAIL persona copies drifted from .agents/skills (run python tools/sync_personas.py): " + ", ".join(stale))
        return 1
    print(f"personas: {'ok' if check else 'synced'} ({len(PERSONAS)}; {len(stale)} {'stale' if check else 'written'})")
    return 0


if __name__ == "__main__":
    sys.exit(main("--check" in sys.argv))
