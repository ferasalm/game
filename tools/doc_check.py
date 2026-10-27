#!/usr/bin/env python3
"""Keeps the always-loaded notes small and well-formed (docs/WORKFLOW.md); exit 1 on any failure.

Warns (exit 0) at 75% of a cap. Caps: CLAUDE.md 80 lines, HANDOFF.md 60, docs/DECISIONS.md 70, docs/LESSONS.md 100, and 27 KB for all four
(about 6k tokens loaded at every session start). Every next step names a model and an effort; every decision
is dated; a struck decision says what superseded it; docs/MAP.md is current (tools/map.py --check).
"""
import pathlib, re, subprocess, sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
CAPS = {"CLAUDE.md": 80, "HANDOFF.md": 60, "docs/DECISIONS.md": 70, "docs/LESSONS.md": 100}
LOADED_BYTES = 27_000
fails = []
warns = []


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
    if cap * 3 // 4 <= n <= cap:
        warns.append(f"WARN {name} is at {n}/{cap} lines (75%+): curate before it hits the cap")
size = sum(len(t.encode()) for t in texts.values())
check(size <= LOADED_BYTES, f"always-loaded notes are {size} bytes (max {LOADED_BYTES})")
for name in ("HANDOFF.md", "docs/DECISIONS.md", "docs/LESSONS.md"):
    check(f"@{name}" in texts["CLAUDE.md"], f"CLAUDE.md loads @{name}")

# One queue (Feras 2026-10-27): every row names a lane; builder is the default, a chat says why (D1 as a check, not prose)
queue = texts["HANDOFF.md"].split("## Queue", 1)[-1].split("\n## ", 1)[0] if "## Queue" in texts["HANDOFF.md"] else ""
rows = [[c.strip() for c in r.split("|")[1:-1]] for r in re.findall(r"^\| *\d+ *\|.*\|$", queue, re.M)]
check(bool(rows), "HANDOFF.md has a '## Queue' table with numbered rows")
for row in rows:
    lane, who = (row[2], row[3]) if len(row) > 3 else ("", "")
    parts = lane.split(" + ")
    check(all(re.fullmatch(r"builder|Feras|chat \((taste|MCP|review|plan)\)", p) for p in parts),
          f"queue row lane is builder, Feras or 'chat (taste|MCP|review|plan)': {row[:3]}")
    check("builder" not in parts or re.search(r"\b(agy|cf|oc)\b", who), f"builder row names agy, cf or oc: {row[:4]}")
    check(not any(p.startswith("chat") for p in parts) or re.search(r"(Haiku|Sonnet|Opus) (low|medium|high|xhigh)", who),
          f"chat row names its model and effort (e.g. Opus high): {row[:4]}")

log = texts["docs/DECISIONS.md"].split("## Log", 1)[-1]
for line in (l for l in log.splitlines() if l.startswith("- ")):
    check(re.match(r"- (~~)?\d{4}-\d{2}-\d{2} ", line), f"decision dated: {line[:60]}")
    if line.startswith("- ~~"):
        check("supersed" in line.lower(), f"struck decision says what superseded it: {line[:60]}")

check(subprocess.run([sys.executable, str(ROOT / "tools/map.py"), "--check"]).returncode == 0, "docs/MAP.md current")
print("\n".join(warns)) if warns else None
print("\n".join(f"FAIL {f}" for f in fails) if fails else f"docs: ok ({size} bytes loaded at start)")
sys.exit(1 if fails else 0)
