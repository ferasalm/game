#!/usr/bin/env python3
"""Keeps the always-loaded notes small and well-formed (docs/EFFICIENCY.md); exit 1 on any failure.

Caps: CLAUDE.md 80 lines, HANDOFF.md 60, docs/DECISIONS.md 70, docs/LESSONS.md 100, and 27 KB for all four
(about 6k tokens loaded at every session start). Every next step names a model and an effort; every decision
is dated; a struck decision says what superseded it; docs/MAP.md is current (tools/map.py --check).
"""
import pathlib, re, subprocess, sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
CAPS = {"CLAUDE.md": 80, "HANDOFF.md": 60, "docs/DECISIONS.md": 70, "docs/LESSONS.md": 100}
LOADED_BYTES = 27_000
fails = []


def check(ok: bool, what: str) -> None:
    if not ok:
        fails.append(what)


texts = {}
for name, cap in CAPS.items():
    path = ROOT / name
    check(path.exists(), f"{name} exists")
    texts[name] = path.read_text(encoding="utf-8") if path.exists() else ""
    n = len(texts[name].splitlines())
    check(n <= cap, f"{name} has {n} lines (max {cap}): curate it")
size = sum(len(t.encode()) for t in texts.values())
check(size <= LOADED_BYTES, f"always-loaded notes are {size} bytes (max {LOADED_BYTES})")
for name in ("HANDOFF.md", "docs/DECISIONS.md", "docs/LESSONS.md"):
    check(f"@{name}" in texts["CLAUDE.md"], f"CLAUDE.md loads @{name}")

steps = texts["HANDOFF.md"]  # every numbered step: the shared ones and each track's
items = re.findall(r"^\d+\. .*(?:\n(?!\d+\. |#|`|- ).*)*", steps, re.M)
check(bool(items), "HANDOFF.md has numbered next steps")
for item in items:
    check(re.search(r"Model: (Haiku|Sonnet|Opus)", item) and re.search(r"Effort: (low|medium|high)", item),
          f"next step names 'Model: Haiku|Sonnet|Opus' and 'Effort: low|medium|high': {item[:60]}")

log = texts["docs/DECISIONS.md"].split("## Log", 1)[-1]
for line in (l for l in log.splitlines() if l.startswith("- ")):
    check(re.match(r"- (~~)?\d{4}-\d{2}-\d{2} ", line), f"decision dated: {line[:60]}")
    if line.startswith("- ~~"):
        check("supersed" in line.lower(), f"struck decision says what superseded it: {line[:60]}")

check(subprocess.run([sys.executable, str(ROOT / "tools/map.py"), "--check"]).returncode == 0, "docs/MAP.md current")
print("\n".join(f"FAIL {f}" for f in fails) if fails else f"docs: ok ({size} bytes loaded at start)")
sys.exit(1 if fails else 0)
