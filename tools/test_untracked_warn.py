#!/usr/bin/env python3
"""untracked_warn.sh: warns about an untracked file, stays quiet when it is added or ignored, never fails."""
import os
import subprocess
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__)).replace("\\", "/")


def make_repo():
    root = tempfile.mkdtemp().replace("\\", "/")
    subprocess.run(["git", "-C", root, "init", "-q"], check=True)
    return root


def run(root):
    return subprocess.run(["bash", HERE + "/untracked_warn.sh", root], capture_output=True, text=True)


def write(root, name, text="x\n"):
    with open(f"{root}/{name}", "w", encoding="utf-8", newline="\n") as f:
        f.write(text)


def test_untracked_file_warns_and_exits_zero():
    root = make_repo()
    write(root, "new_test.py")
    r = run(root)
    assert r.returncode == 0 and "WARN untracked" in r.stdout and "new_test.py" in r.stdout, (r.stdout, r.stderr)


def test_added_or_ignored_or_check_files_are_quiet():
    root = make_repo()
    write(root, "added.py")
    write(root, ".gitignore", "junk.tmp\n")
    write(root, "junk.tmp")
    os.makedirs(root + "/.check")
    write(root, ".check/alive")
    subprocess.run(["git", "-C", root, "add", "added.py", ".gitignore"], check=True)
    r = run(root)
    assert r.returncode == 0 and r.stdout == "", (r.stdout, r.stderr)


if __name__ == "__main__":
    test_untracked_file_warns_and_exits_zero()
    test_added_or_ignored_or_check_files_are_quiet()
    print("test_untracked_warn: 2 tests passed")
