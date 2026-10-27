#!/usr/bin/env python3
"""Self-test for doc_check.py: warns (exit 0) at 75% of a cap; every queue row needs a lane and a WORKFLOW department."""
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
WORKFLOW = ["# WORKFLOW", "## Departments", "| Id | Does | Skill(s) | Reviewer |", "|---|---|---|---|",
            "| Ops | process | ops-review | review-cost |", "| Gameplay | code | builders | review-code |",
            "| QA | eye | players-eye-gate | review-player |", "## Limits", "| Cap | Value |", "|---|---|", "| Art | not a department |"]


def run_check(handoff, claude_lines=61):
    root = tempfile.mkdtemp()
    os.makedirs(root + "/tools")
    shutil.copy(HERE + "/doc_check.py", root + "/tools/doc_check.py")
    write(root, "tools/map.py", ["import sys", "sys.exit(0)"])
    write(root, "CLAUDE.md", ["@HANDOFF.md", "@docs/DECISIONS.md", "@docs/LESSONS.md"] + ["x"] * claude_lines)
    write(root, "HANDOFF.md", handoff)
    write(root, "docs/WORKFLOW.md", WORKFLOW)
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


if __name__ == "__main__":
    test_warns_at_75_percent_but_passes()
    test_queue_rows_need_a_lane()
    test_queue_rows_need_a_department()
    print("test_doc_check: 3 tests passed")
