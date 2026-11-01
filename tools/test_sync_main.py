#!/usr/bin/env python3
"""Self-test for tools/sync_main.sh (row 25, 2026-11-01) in a throwaway repo with a bare origin and a stub run_godot.sh.
A checkout left on a side branch must come back to main and pull origin/main; the last line is SYNC PASS or SYNC FAIL <step>."""
import os
import shutil
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__))).replace("\\", "/")
BASH = shutil.which("bash") or "bash"


def sh(cwd, *cmd):
    return subprocess.run(list(cmd), cwd=cwd, capture_output=True, text=True, encoding="utf-8")


def git(cwd, *a):
    return sh(cwd, "git", "-c", "user.name=t", "-c", "user.email=t@t", *a)


def put(path, text):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8", newline="\n") as f:
        f.write(text)


def toy(godot_rc=0):
    """(top, repo, other): origin.git bare, repo = the main checkout with sync_main.sh and a stub run_godot.sh, other = a second clone."""
    top = tempfile.mkdtemp().replace("\\", "/")
    sh(top, "git", "init", "-q", "--bare", "-b", "main", "origin.git")
    sh(top, "git", "clone", "-q", "origin.git", "repo")
    g = top + "/repo"
    put(g + "/tools/sync_main.sh", open(ROOT + "/tools/sync_main.sh", encoding="utf-8").read())
    put(g + "/tools/run_godot.sh", "exit %d\n" % godot_rc)
    put(g + "/README.md", "one\n")
    git(g, "add", "-A")
    git(g, "commit", "-qm", "base")
    git(g, "push", "-q", "origin", "HEAD:main")
    sh(top, "git", "clone", "-q", "origin.git", "other")
    return top, g, top + "/other"


def push_new_commit(other, text):
    put(other + "/README.md", text)
    git(other, "commit", "-qam", "newer")
    git(other, "push", "-q", "origin", "HEAD:main")


def run(g):
    return sh(g, BASH, "tools/sync_main.sh")


def last_line(r):
    lines = [ln for ln in r.stdout.strip().splitlines() if ln]  # the script's verdict is its last stdout line; git's stderr is not
    return lines[-1] if lines else ""


def head(g):
    return git(g, "rev-parse", "--abbrev-ref", "HEAD").stdout.strip()


def test_a_side_branch_is_switched_to_main_and_pulled():
    top, g, other = toy()
    try:
        git(g, "checkout", "-q", "-b", "side")
        push_new_commit(other, "two\n")
        r = run(g)
        assert last_line(r).startswith("SYNC PASS"), r.stdout + r.stderr
        assert head(g) == "main", head(g)
        assert open(g + "/README.md", encoding="utf-8").read() == "two\n"
    finally:
        shutil.rmtree(top, ignore_errors=True)


def test_main_stays_main_and_passes():
    top, g, other = toy()
    try:
        push_new_commit(other, "two\n")
        r = run(g)
        assert last_line(r).startswith("SYNC PASS") and head(g) == "main", r.stdout + r.stderr
    finally:
        shutil.rmtree(top, ignore_errors=True)


def test_a_switch_that_would_lose_local_work_fails_on_branch():
    top, g, other = toy()
    try:
        git(g, "checkout", "-q", "-b", "side")
        put(g + "/README.md", "side edit\n")
        git(g, "commit", "-qam", "side")
        put(g + "/README.md", "uncommitted\n")  # dirty file that differs on main: switch refuses
        r = run(g)
        assert last_line(r) == "SYNC FAIL branch", r.stdout + r.stderr
        assert head(g) == "side"
    finally:
        shutil.rmtree(top, ignore_errors=True)


def test_a_failing_import_is_reported():
    top, g, other = toy(godot_rc=1)
    try:
        r = run(g)
        assert last_line(r) == "SYNC FAIL import", r.stdout + r.stderr
    finally:
        shutil.rmtree(top, ignore_errors=True)


def test_uncommitted_tracked_change_fails_on_dirty():
    top, g, other = toy()
    try:
        git(g, "checkout", "-q", "-b", "side")
        put(g + "/extra.txt", "tracked\n")
        git(g, "add", "extra.txt")
        git(g, "commit", "-qm", "extra")  # extra.txt is tracked on side and absent on main
        put(g + "/extra.txt", "uncommitted\n")  # uncommitted tracked edit: must refuse before any switch or pull
        r = run(g)
        assert last_line(r) == "SYNC FAIL dirty", r.stdout + r.stderr
        assert head(g) == "side", head(g)
        assert open(g + "/extra.txt", encoding="utf-8").read() == "uncommitted\n"
    finally:
        shutil.rmtree(top, ignore_errors=True)


def test_a_dirty_file_a_switch_would_carry_still_fails_on_dirty():
    top, g, other = toy()
    try:
        git(g, "checkout", "-q", "-b", "side")  # side == main, so git switch alone would carry the edit onto main
        put(g + "/README.md", "carried?\n")
        r = run(g)
        assert last_line(r) == "SYNC FAIL dirty" and head(g) == "side", r.stdout + r.stderr
    finally:
        shutil.rmtree(top, ignore_errors=True)


def test_untracked_file_does_not_fail():
    top, g, other = toy()
    try:
        put(g + "/untracked.txt", "scratch\n")  # untracked, so the dirty check must not fire
        r = run(g)
        assert last_line(r).startswith("SYNC PASS"), r.stdout + r.stderr
        assert head(g) == "main", head(g)
    finally:
        shutil.rmtree(top, ignore_errors=True)


if __name__ == "__main__":
    tests = [v for k, v in sorted(globals().items()) if k.startswith("test_")]
    for t in tests:
        t()
    print(f"test_sync_main: {len(tests)} tests passed")
