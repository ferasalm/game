#!/usr/bin/env python3
"""Refuses a base holding a red tool test the brief does not name (rows 23 and 24; the rule alone did not hold): a sibling's
red test failed every part's check, and a fix pass edited a protected tool to turn it green. Runs the tool tests of <base>
in a throwaway worktree, less the 2 slow toys (they test the pipeline, not a part). A red GDScript test is not seen.
At the start it removes the worktrees a run killed by timeout left registered (a base_red* temp dir older than 30 min).
Exit 0 clean, 1 a foreign red test (build_pipeline.sh refuses), 2 it could not run (build_pipeline.sh warns and goes on).
Usage (cwd = a checkout): python tools/base_red.py <brief> <base-commit>. Test: tools/test_base_red.py.
"""
import os
import re
import shutil
import subprocess
import sys
import tempfile
import time

STALE_SEC = 30 * 60  # a live run lasts at most BASE_RED_SEC = 600 s: a fresher worktree is a concurrent launch
END = r"(?![\w-])(?!\.\w)"  # a name ends at a period, comma, space, ) or backtick, not at .bak or .py.orig
BEFORE = r"(?<![\w/\\-])"  # a path starts at a line start or a space, not inside a longer path or a word


def names(section, path):
    """True when the Tests section names path: its full repo path, or a bare basename (no directory before it)."""
    return any(re.search(BEFORE + re.escape(name) + END, section)
               for name in (path, os.path.basename(path)))


def foreign(failed, brief_text):
    """The failing tests the brief's Tests section does not name; a name in Do NOT edit claims nothing."""
    m = re.search(r"^## Tests[^\n]*\n(.*?)(?=^## |\Z)", brief_text, re.M | re.S)
    section = m.group(1) if m else ""
    return [p for p in failed if not names(section, p)]


def temp_base(path):
    """The base_red* temp directory holding a registered worktree path, or None."""
    top = os.path.dirname(os.path.normpath(path))
    if not os.path.basename(top).startswith("base_red"):
        return None
    root = os.path.normcase(os.path.realpath(tempfile.gettempdir()))
    return top if os.path.normcase(os.path.realpath(os.path.dirname(top))) == root else None


def sweep_stale():
    """Removes the worktrees a killed run left registered; the age of its base_red* dir is the clock."""
    listed = subprocess.run(["git", "worktree", "list", "--porcelain"], capture_output=True, text=True, check=True)
    for line in listed.stdout.splitlines():
        if not line.startswith("worktree "):
            continue
        path = line[len("worktree "):].strip()
        top = temp_base(path)
        if not top or time.time() - os.path.getmtime(top) < STALE_SEC:
            continue
        subprocess.run(["git", "worktree", "remove", "--force", path], capture_output=True)
        shutil.rmtree(top, ignore_errors=True)
        subprocess.run(["git", "worktree", "prune"], capture_output=True)


def red_tests(root):
    """The failing tool tests of the checkout at root, the slow toys left out."""
    start = os.getcwd()
    os.chdir(root)
    try:
        import tool_tests  # inside the try of main(): an import fault is exit 2, not a refusal
        paths = [p for p in tool_tests.find_tests() if p not in tool_tests.SERIAL]
        return [p for p, rc, _ in tool_tests.run_files(paths, ".check") if rc != 0]
    finally:
        os.chdir(start)


def main(argv):
    if len(argv) != 2:
        print("usage: base_red.py <brief> <base-commit>")
        return 2
    brief, base = argv
    try:
        sweep_stale()  # a stale sweep fault must not refuse a clean base
    except Exception:
        pass
    top = tempfile.mkdtemp(prefix="base_red")
    wt = os.path.join(top, "wt")
    try:
        with open(brief, encoding="utf-8") as f:
            text = f.read()
        subprocess.run(["git", "worktree", "add", "-q", "--detach", wt, base], check=True, capture_output=True)
        bad = foreign(red_tests(wt), text)
    except Exception as e:  # exit 1 means a red test: any fault of its own must not refuse a clean base
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
