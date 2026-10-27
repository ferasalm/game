#!/usr/bin/env python3
"""Self-test for map.py: only tracked files are mapped (an untracked file made CI fail "MAP.md current")."""
import os
import shutil
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))


def test_untracked_files_are_not_listed():
    root = tempfile.mkdtemp()
    os.makedirs(root + "/tools")
    shutil.copy(HERE + "/map.py", root + "/tools/map.py")
    os.makedirs(root + "/docs")
    for name in ("kept", "stray"):
        with open(f"{root}/{name}.gd", "w", encoding="utf-8", newline="\n") as f:
            f.write(f"## {name} purpose\nvar x: int = 0\n")
    git = ["git", "-C", root, "-c", "user.name=t", "-c", "user.email=t@t"]
    subprocess.run([*git, "init", "-q"], check=True)
    subprocess.run([*git, "add", "kept.gd", "tools/map.py"], check=True)
    r = subprocess.run([sys.executable, root + "/tools/map.py"], capture_output=True, text=True)
    text = open(root + "/docs/MAP.md", encoding="utf-8").read()
    assert "kept.gd" in text and "stray.gd" not in text, (r.stdout, r.stderr, text)


if __name__ == "__main__":
    test_untracked_files_are_not_listed()
    print("test_map: 1 tests passed")
