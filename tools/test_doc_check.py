#!/usr/bin/env python3
"""Self-test for doc_check.py: warns (exit 0) when an always-loaded note passes 75% of its cap."""
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


QUEUE = ["## Queue", "| # | Task | Lane | Who | Status | Blocked by |", "|---|---|---|---|---|---|",
         "| 1 | hooks | builder + chat (review) | cf; Opus high | next | - |", "| 2 | M1 brief | chat (plan) | Opus high | queued | 1 |",
         "| 3 | play M1 | Feras | - | queued | 2 |", "## Waiting on Feras", "| What | Since |", "|---|---|", "| 9 | not a queue row |"]


def run_check(handoff, claude_lines=61):
    root = tempfile.mkdtemp()
    os.makedirs(root + "/tools")
    shutil.copy(HERE + "/doc_check.py", root + "/tools/doc_check.py")
    write(root, "tools/map.py", ["import sys", "sys.exit(0)"])
    write(root, "CLAUDE.md", ["@HANDOFF.md", "@docs/DECISIONS.md", "@docs/LESSONS.md"] + ["x"] * claude_lines)
    write(root, "HANDOFF.md", handoff)
    write(root, "docs/DECISIONS.md", ["x"] * 10)
    write(root, "docs/LESSONS.md", ["x"] * 10)
    return subprocess.run([sys.executable, root + "/tools/doc_check.py"], capture_output=True, text=True)


def test_warns_at_75_percent_but_passes():
    r = run_check(QUEUE + ["x"] * 10)  # CLAUDE.md 64 of 80; HANDOFF 20 of 60: below 75%
    assert r.returncode == 0, r.stdout + r.stderr
    assert "WARN CLAUDE.md is at 64/80" in r.stdout and "WARN HANDOFF.md" not in r.stdout, r.stdout


def test_queue_rows_need_a_lane():
    for bad, why in (("| 4 | x | Opus | Opus high | next | - |", "lane is builder"),  # a model is not a lane
                     ("| 4 | x | chat | Opus high | next | - |", "lane is builder"),  # a chat without its reason
                     ("| 4 | x | builder | Opus high | next | - |", "names agy, cf or oc"),
                     ("| 4 | x | chat (taste) | - | next | - |", "names its model and effort")):
        r = run_check(QUEUE[:6] + [bad] + QUEUE[6:])
        assert r.returncode == 1 and why in r.stdout, bad + "\n" + r.stdout
    r = run_check(["# HANDOFF", "1. step. Model: Sonnet. Effort: medium."])  # the old numbered steps
    assert r.returncode == 1 and "'## Queue' table" in r.stdout, r.stdout


if __name__ == "__main__":
    test_warns_at_75_percent_but_passes()
    test_queue_rows_need_a_lane()
    print("test_doc_check: 2 tests passed")
