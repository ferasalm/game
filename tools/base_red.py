#!/usr/bin/env python3
"""Refuses a base holding a red tool test the brief does not name (rows 23 and 24; the rule alone did not hold): a sibling's
red test failed every part's check, and a fix pass edited a protected tool to turn it green. Runs the tool tests of <base>
in a throwaway worktree, less the 2 slow toys (they test the pipeline, not a part). A red GDScript test is not seen.
Exit 0 clean, 1 a foreign red test (build_pipeline.sh refuses), 2 it could not run (build_pipeline.sh warns and goes on).
Usage (cwd = a checkout): python tools/base_red.py <brief> <base-commit>. Test: tools/test_base_red.py.
"""
import os
import shutil
import subprocess
import sys
import tempfile

import tool_tests


def foreign(failed, brief_text):
    """The failing tests the brief does not name; a named one is the part's own red test."""
    return [p for p in failed if os.path.basename(p) not in brief_text]


def red_tests(root):
    """The failing tool tests of the checkout at root, the slow toys left out."""
    start = os.getcwd()
    os.chdir(root)
    try:
        paths = [p for p in tool_tests.find_tests() if p not in tool_tests.SERIAL]
        return [p for p, rc, _ in tool_tests.run_files(paths, ".check") if rc != 0]
    finally:
        os.chdir(start)


def main(argv):
    if len(argv) != 2:
        print("usage: base_red.py <brief> <base-commit>")
        return 2
    brief, base = argv
    top = tempfile.mkdtemp(prefix="base_red")
    wt = os.path.join(top, "wt")
    try:
        with open(brief, encoding="utf-8") as f:
            text = f.read()
        subprocess.run(["git", "worktree", "add", "-q", "--detach", wt, base], check=True, capture_output=True)
        bad = foreign(red_tests(wt), text)
    except (OSError, subprocess.CalledProcessError) as e:
        print(f"base_red could not run: {e}")
        return 2
    finally:
        subprocess.run(["git", "worktree", "remove", "--force", wt], capture_output=True)
        shutil.rmtree(top, ignore_errors=True)
        subprocess.run(["git", "worktree", "prune"], capture_output=True)
    if bad:
        print("base holds a red test this brief does not name: " + " ".join(bad)
              + " (keep it on the branch of the part that owns it: builders skill, The loop)")
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
