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


def test_warns_at_75_percent_but_passes():
    root = tempfile.mkdtemp()
    os.makedirs(root + "/tools")
    shutil.copy(HERE + "/doc_check.py", root + "/tools/doc_check.py")
    write(root, "tools/map.py", ["import sys", "sys.exit(0)"])
    write(root, "CLAUDE.md", ["@HANDOFF.md", "@docs/DECISIONS.md", "@docs/LESSONS.md"] + ["x"] * 61)  # 64 of 80
    write(root, "HANDOFF.md", ["1. step. Model: Sonnet. Effort: medium."] + ["x"] * 20)  # 21 of 60: below 75%
    write(root, "docs/DECISIONS.md", ["x"] * 10)
    write(root, "docs/LESSONS.md", ["x"] * 10)
    r = subprocess.run([sys.executable, root + "/tools/doc_check.py"], capture_output=True, text=True)
    assert r.returncode == 0, r.stdout + r.stderr
    assert "WARN CLAUDE.md is at 64/80" in r.stdout and "WARN HANDOFF.md" not in r.stdout, r.stdout


if __name__ == "__main__":
    test_warns_at_75_percent_but_passes()
    print("test_doc_check: 1 tests passed")
