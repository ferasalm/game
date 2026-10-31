#!/usr/bin/env python3
"""Self-test for tools/main_file.sh and tools/merge_base.sh (row 23 d, 2026-11-01) in a throwaway repo with a bare origin."""
import os
import shutil
import subprocess
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__))).replace("\\", "/")
BASH = shutil.which("bash") or "bash"


def sh(cwd, *cmd):
    return subprocess.run(list(cmd), cwd=cwd, capture_output=True, text=True, encoding="utf-8")


def git(cwd, *a):
    return sh(cwd, "git", "-c", "user.name=t", "-c", "user.email=t@t", *a)


def commit(g, name, text):
    with open(f"{g}/{name}", "w", encoding="utf-8", newline="\n") as f:
        f.write(text)
    git(g, "add", "-A")
    git(g, "commit", "-qm", f"edit {name}")


def toy():
    """(origin, a, b): two clones of one bare origin with main pushed; b is the one that falls behind."""
    top = tempfile.mkdtemp().replace("\\", "/")
    sh(top, "git", "init", "-q", "--bare", "-b", "main", "origin.git")
    sh(top, "git", "clone", "-q", "origin.git", "a")
    commit(top + "/a", "f.txt", "one\n")
    git(top + "/a", "push", "-q", "origin", "HEAD:main")
    sh(top, "git", "clone", "-q", "origin.git", "b")
    return top, top + "/a", top + "/b"


def test_main_file_prints_origin_main_even_when_the_checkout_is_behind():
    top, a, b = toy()
    commit(a, "f.txt", "two\n")
    git(a, "push", "-q", "origin", "HEAD:main")
    r = sh(b, BASH, ROOT + "/tools/main_file.sh", "f.txt")
    assert r.returncode == 0 and r.stdout == "two\n", (r.stdout, r.stderr)
    assert open(b + "/f.txt", encoding="utf-8").read() == "one\n", "the work tree is not touched"


def test_main_file_usage_and_missing_path():
    top, a, b = toy()
    assert sh(b, BASH, ROOT + "/tools/main_file.sh").returncode == 2
    assert sh(b, BASH, ROOT + "/tools/main_file.sh", "nope.txt").returncode != 0


def test_merge_base_fast_forwards_the_current_branch():
    top, a, b = toy()
    commit(a, "f.txt", "two\n")
    git(a, "push", "-q", "origin", "HEAD:main")
    r = sh(b, BASH, ROOT + "/tools/merge_base.sh")
    assert r.returncode == 0 and r.stdout.startswith("MERGE_BASE PASS "), (r.stdout, r.stderr)
    assert open(b + "/f.txt", encoding="utf-8").read() == "two\n"


def test_merge_base_takes_a_branch_argument():
    top, a, b = toy()
    git(a, "checkout", "-q", "-b", "side")
    commit(a, "g.txt", "side\n")
    git(a, "push", "-q", "origin", "side")
    git(b, "checkout", "-q", "-b", "mine", "origin/main")
    r = sh(b, BASH, ROOT + "/tools/merge_base.sh", "side")
    assert r.returncode == 0 and os.path.exists(b + "/g.txt"), (r.stdout, r.stderr)


def test_merge_base_refuses_a_diverged_branch_and_makes_no_merge_commit():
    top, a, b = toy()
    commit(a, "f.txt", "two\n")
    git(a, "push", "-q", "origin", "HEAD:main")
    commit(b, "h.txt", "local\n")
    before = git(b, "rev-parse", "HEAD").stdout
    r = sh(b, BASH, ROOT + "/tools/merge_base.sh", "main")
    assert r.returncode == 1 and "MERGE_BASE FAIL" in r.stdout, (r.stdout, r.stderr)
    assert git(b, "rev-parse", "HEAD").stdout == before


if __name__ == "__main__":
    from tool_tests import run_cases
    run_cases([v for k, v in sorted(globals().items()) if k.startswith("test_")], "test_git_helpers")
