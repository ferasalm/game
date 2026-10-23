#!/usr/bin/env python3
"""Makes one opencode subagent per game skill (.agents/skills/<name> -> .opencode/agent/<name>.md); --check fails when stale.

opencode builders (Inkling, DeepSeek) call them with the task tool; each reads its SKILL.md, GEMINI.md wins. Feras 2026-10-23.
Usage: python tools/oc_agents.py [--check]
"""
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
SKILLS = ROOT / ".agents" / "skills"
AGENTS = ROOT / ".opencode" / "agent"
BODY = """---
description: {desc}
mode: subagent
---
You are the {name} specialist, called by the build agent for one part of its brief. First read
`.agents/skills/{name}/SKILL.md` and follow it. GEMINI.md and the brief win where they differ: typed GDScript only,
no C#, <= 200 lines a file, logic/ folders pure, numbers in content JSON, player text as localization keys. Edit only
the files the build agent names, never a brief's Do NOT edit list, then report the files you changed in one list.
"""


def description(skill_md):
    m = re.search(r"^description:\s*'?(.*?)'?\s*$", skill_md, re.M)
    return (m.group(1) if m else "Game dev specialist").replace('"', "'")


def wanted():
    out = {}
    for d in sorted(p for p in SKILLS.iterdir() if (p / "SKILL.md").is_file()):
        text = (d / "SKILL.md").read_text(encoding="utf-8")
        out[d.name + ".md"] = BODY.format(desc=description(text), name=d.name)
    return out


def stale(want, have_dir):
    have = {p.name: p.read_text(encoding="utf-8") for p in have_dir.glob("*.md")} if have_dir.is_dir() else {}
    return sorted(n for n in set(want) | set(have) if want.get(n) != have.get(n))


def main(argv):
    want = wanted()
    if "--check" in argv:
        bad = stale(want, AGENTS)
        for n in bad:
            print(f"FAIL .opencode/agent/{n} is stale or extra; run python tools/oc_agents.py")
        if not want:
            print("FAIL no skills found in .agents/skills")
        print(f"oc_agents: {len(want)} subagents" + ("" if bad or not want else " current"))
        return 1 if bad or not want else 0
    AGENTS.mkdir(parents=True, exist_ok=True)
    for p in AGENTS.glob("*.md"):
        if p.name not in want:
            p.unlink()
    for n, text in want.items():
        (AGENTS / n).write_text(text, encoding="utf-8", newline="\n")
    print(f"oc_agents: wrote {len(want)} subagents")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
