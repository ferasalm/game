#!/usr/bin/env python3
"""Keeps the always-loaded notes small and well-formed (docs/WORKFLOW.md); exit 1 on any failure.

Warns (exit 0) at 75% of a cap. Caps: CLAUDE.md 80 lines, HANDOFF.md 60, docs/DECISIONS.md 70, docs/LESSONS.md 100, and 27 KB for all four
(about 6k tokens loaded at every session start). Every HANDOFF queue row names a department from the
docs/WORKFLOW.md Departments table and a lane; a subagent-mode department has its Opus .claude/agents/dept-<id>.md and
every dept-*.md is in the table; every decision is dated; a struck decision says what superseded it;
docs/MAP.md is current (tools/map.py --check).
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
# and a department (Feras 2026-10-28): the father opens that department's Opus child chat (docs/WORKFLOW.md, Start here)
def table(text: str, heading: str) -> list:
    """The rows of the first table under a '## heading' line, header row first, the |---| line dropped."""
    part = text.split(heading, 1)[-1].split("\n## ", 1)[0] if heading in text else ""
    lines = [l for l in part.splitlines() if l.startswith("|") and not re.fullmatch(r"\|[-: |]+\|", l.strip())]
    return [[c.strip() for c in l.strip().split("|")[1:-1]] for l in lines]


workflow = ROOT / "docs/WORKFLOW.md"
dtable = table(workflow.read_text(encoding="utf-8"), "## Departments") if workflow.exists() else []
dhead = dtable[0] if dtable else []
dhead_ok = dhead[:3] == ["Id", "Mode", "Agent"]
check(dhead_ok, f"docs/WORKFLOW.md has a '## Departments' table starting Id | Mode | Agent: {dhead}")
depts = {r[0].strip("*") for r in dtable[1:] if r}
# Hybrid departments (Feras 2026-10-28): a subagent-mode department has an Opus agent file .claude/agents/dept-<id>.md
agents = {p.stem: p for p in (ROOT / ".claude/agents").glob("dept-*.md")}
for row in (r for r in dtable[1:] if dhead_ok and len(r) >= 3):
    dept, modes, agent = row[0].strip("*"), row[1].split(" + "), row[2]
    check(all(m in ("subagent", "chat", "father") for m in modes), f"department mode is subagent, chat or father: {row[:3]}")
    if "subagent" in modes:
        check(agent == f"dept-{dept.lower()}" and agent in agents, f"subagent department has .claude/agents/dept-{dept.lower()}.md: {row[:3]}")
        text = agents[agent].read_text(encoding="utf-8") if agent in agents else ""
        check(re.search(r"^model: opus$", text, re.M) is not None, f"{agent} runs on Opus (Feras 10-28): model: opus")
    else:
        check(agent == "-", f"a department with no subagent mode names no agent (-): {row[:3]}")
named = {r[2] for r in dtable[1:] if len(r) >= 3}
for stem in agents:
    check(stem in named, f".claude/agents/{stem}.md is named in the WORKFLOW Departments table")
queue = table(texts["HANDOFF.md"], "## Queue")
head = queue[0] if queue else []
rows = [r for r in queue[1:] if r and r[0].isdigit()]
check(bool(rows), "HANDOFF.md has a '## Queue' table with numbered rows")
cols = {name: head.index(name) for name in ("Dept", "Lane", "Who") if name in head}
check(len(cols) == 3, f"HANDOFF queue header has Dept, Lane and Who columns: {head}")
for row in rows if len(cols) == 3 else []:
    dept, lane, who = (row[cols[n]] if len(row) > cols[n] else "" for n in ("Dept", "Lane", "Who"))
    check(dept in depts, f"queue row names a department from WORKFLOW ({', '.join(sorted(depts))}): {row[:3]}")
    parts = lane.split(" + ")
    check(all(re.fullmatch(r"builder|Feras|chat \((taste|MCP|review|plan)\)", p) for p in parts),
          f"queue row lane is builder, Feras or 'chat (taste|MCP|review|plan)': {row[:4]}")
    check("builder" not in parts or re.search(r"\b(agy|cf|oc)\b", who), f"builder row names agy, cf or oc: {row[:5]}")
    check(not any(p.startswith("chat") for p in parts) or re.search(r"Opus (low|medium|high|xhigh)", who),
          f"chat row names Opus and its effort (Feras 10-28: Opus for every child), e.g. Opus high: {row[:5]}")

log = texts["docs/DECISIONS.md"].split("## Log", 1)[-1]
for line in (l for l in log.splitlines() if l.startswith("- ")):
    check(re.match(r"- (~~)?\d{4}-\d{2}-\d{2} ", line), f"decision dated: {line[:60]}")
    if line.startswith("- ~~"):
        check("supersed" in line.lower(), f"struck decision says what superseded it: {line[:60]}")

check(subprocess.run([sys.executable, str(ROOT / "tools/map.py"), "--check"]).returncode == 0, "docs/MAP.md current")
print("\n".join(warns)) if warns else None
print("\n".join(f"FAIL {f}" for f in fails) if fails else f"docs: ok ({size} bytes loaded at start)")
sys.exit(1 if fails else 0)
