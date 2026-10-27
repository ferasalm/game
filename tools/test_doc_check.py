#!/usr/bin/env python3
"""Self-test for doc_check.py: warns (exit 0) at 75% of a cap; every queue row needs a lane and a WORKFLOW department;
a subagent-mode department needs its Opus .claude/agents/dept-<id>.md."""
import os
import shutil
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))


def write(root, name, lines):
    os.makedirs(os.path.dirname(f"{root}/{name}"), exist_ok=True)
    with open(f"{root}/{name}", "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(lines) + "\n")


QUEUE = ["## Queue", "| # | Task | Dept | Lane | Who | Status | Blocked by |", "|---|---|---|---|---|---|---|",
         "| 1 | hooks | Ops | builder + chat (review) | cf; Opus high | next | - |",
         "| 2 | M1 brief | Gameplay | chat (plan) | Opus high | queued | 1 |",
         "| 3 | play M1 | QA | Feras | - | queued | 2 |", "## Waiting on Feras", "| What | Since |", "|---|---|", "| 9 | not a queue row |"]
WORKFLOW = ["# WORKFLOW", "## Departments", "| Id | Mode | Agent | Does | Reviewer |", "|---|---|---|---|---|",
            "| Ops | subagent + chat | dept-ops | process | review-cost |", "| Gameplay | subagent | dept-gameplay | code | review-code |",
            "| QA | chat | - | eye | review-player |", "## Limits", "| Cap | Value |", "|---|---|", "| Art | not a department |"]
AGENT = ["---", "name: dept-x", "model: opus", "---", "# body"]


def run_check(handoff, claude_lines=61, workflow=WORKFLOW, agents=None):
    root = tempfile.mkdtemp()
    os.makedirs(root + "/tools")
    shutil.copy(HERE + "/doc_check.py", root + "/tools/doc_check.py")
    write(root, "tools/map.py", ["import sys", "sys.exit(0)"])
    write(root, "CLAUDE.md", ["@HANDOFF.md", "@docs/DECISIONS.md", "@docs/LESSONS.md"] + ["x"] * claude_lines)
    write(root, "HANDOFF.md", handoff)
    write(root, "docs/WORKFLOW.md", workflow)
    for name, lines in (agents if agents is not None else {"dept-ops": AGENT, "dept-gameplay": AGENT}).items():
        write(root, f".claude/agents/{name}.md", lines)
    write(root, "docs/DECISIONS.md", ["x"] * 10)
    write(root, "docs/LESSONS.md", ["x"] * 10)
    return subprocess.run([sys.executable, root + "/tools/doc_check.py"], capture_output=True, text=True)


def test_warns_at_75_percent_but_passes():
    r = run_check(QUEUE + ["x"] * 10)  # CLAUDE.md 64 of 80; HANDOFF 20 of 60: below 75%
    assert r.returncode == 0, r.stdout + r.stderr
    assert "WARN CLAUDE.md is at 64/80" in r.stdout and "WARN HANDOFF.md" not in r.stdout, r.stdout


def test_queue_rows_need_a_lane():
    for bad, why in (("| 4 | x | Ops | Opus | Opus high | next | - |", "lane is builder"),  # a model is not a lane
                     ("| 4 | x | Ops | chat | Opus high | next | - |", "lane is builder"),  # a chat without its reason
                     ("| 4 | x | Ops | builder | Opus high | next | - |", "names agy, cf or oc"),
                     ("| 4 | x | Ops | chat (taste) | - | next | - |", "names Opus and its effort"),
                     ("| 4 | x | Ops | chat (taste) | Sonnet medium | next | - |", "names Opus and its effort")):
        r = run_check(QUEUE[:6] + [bad] + QUEUE[6:])
        assert r.returncode == 1 and why in r.stdout, bad + "\n" + r.stdout
    r = run_check(["# HANDOFF", "1. step. Model: Sonnet. Effort: medium."])  # the old numbered steps
    assert r.returncode == 1 and "'## Queue' table" in r.stdout, r.stdout


def test_queue_rows_need_a_department():
    r = run_check(QUEUE)
    assert r.returncode == 0, r.stdout + r.stderr
    for bad in ("| 4 | x | Art | builder | agy | next | - |",  # only in a non-Departments table of WORKFLOW
                "| 4 | x | - | Feras | - | next | - |", "| 4 | x | art department | builder | agy | next | - |"):
        r = run_check(QUEUE[:6] + [bad] + QUEUE[6:])
        assert r.returncode == 1 and "names a department from WORKFLOW" in r.stdout, bad + "\n" + r.stdout
    old = [l.replace("| Dept ", "").replace("|---|---|---|---|---|---|---|", "|---|---|---|---|---|---|") for l in QUEUE]
    r = run_check([l.replace("| Ops ", "").replace("| Gameplay ", "").replace("| QA ", "") for l in old])
    assert r.returncode == 1 and "Dept, Lane and Who columns" in r.stdout, r.stdout  # an old 6-column table


def test_subagent_departments_need_an_opus_agent_file():
    ok = {"dept-ops": AGENT, "dept-gameplay": AGENT}
    for agents, workflow, why in (
            ({"dept-ops": AGENT}, WORKFLOW, "has .claude/agents/dept-gameplay.md"),  # the file is missing
            ({**ok, "dept-ops": [l.replace("opus", "sonnet") for l in AGENT]}, WORKFLOW, "dept-ops runs on Opus"),
            ({**ok, "dept-art": AGENT}, WORKFLOW, "dept-art.md is named in the WORKFLOW"),  # an orphan agent file
            (ok, [l.replace("| QA | chat | - |", "| QA | chat | dept-qa |") for l in WORKFLOW], "names no agent (-)"),
            (ok, [l.replace("subagent + chat", "subagent + session") for l in WORKFLOW], "mode is subagent, chat or father"),
            (ok, [l.replace("| Id | Mode | Agent |", "| Id | Agent | Mode |") for l in WORKFLOW], "starting Id | Mode | Agent")):
        r = run_check(QUEUE, workflow=workflow, agents=agents)
        assert r.returncode == 1 and why in r.stdout, why + "\n" + r.stdout


if __name__ == "__main__":
    test_warns_at_75_percent_but_passes()
    test_queue_rows_need_a_lane()
    test_queue_rows_need_a_department()
    test_subagent_departments_need_an_opus_agent_file()
    print("test_doc_check: 4 tests passed")
