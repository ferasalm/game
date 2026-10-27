#!/usr/bin/env python3
"""Tests kill_tree (tools/lib.sh): a tree with a native grandchild and a parent still forking during the kill dies whole.
Counts only this test's processes by a unique marker in their command lines. Run: python tools/test_kill_tree.py"""
import os
import random
import subprocess
import sys
import time

TOOLS = os.path.dirname(os.path.abspath(__file__)).replace("\\", "/")
# root -> subshell -> native python (grandchild); root keeps forking msys sleeps until it dies (forks mid-kill)
TREE = r'''( "$PYEXE" -c "import time; time.sleep(60)" "$MARK" & wait ) &
while :; do sleep "$MARK" & sleep 0.05; done
'''
DRIVER = r'''. "$LIBSH"
bash "$TREE" & root=$!
sleep 1.5
kill_tree "$root"
'''


def marked(mark: str) -> int:
    """Live processes whose command line holds the marker (Win32_Process on Windows, pgrep elsewhere)."""
    if os.name != "nt":
        return len(subprocess.run(["pgrep", "-f", mark], capture_output=True, text=True).stdout.split())
    ps = "@(Get-CimInstance Win32_Process | Where-Object { $_.CommandLine -like ('*' + $env:MARK + '*') }).Count"
    out = subprocess.run(["powershell", "-NoProfile", "-Command", ps], capture_output=True, text=True,
                         env={**os.environ, "MARK": mark}).stdout.strip()
    return int(out or 0)


def test_kill_tree_kills_grandchildren_and_late_forks() -> None:
    mark = "59.%06d" % random.randrange(10 ** 6)  # a valid sleep length and a unique command-line marker
    tmp = os.environ.get("TEMP", "/tmp").replace("\\", "/")
    tree, driver = tmp + "/kt_tree_%s.sh" % mark, tmp + "/kt_driver_%s.sh" % mark
    for path, text in ((tree, TREE), (driver, DRIVER)):
        with open(path, "w", encoding="utf-8", newline="\n") as f:
            f.write(text)
    env = {**os.environ, "MARK": mark, "PYEXE": sys.executable.replace("\\", "/"), "LIBSH": TOOLS + "/lib.sh", "TREE": tree}
    p = subprocess.Popen(["bash", driver], env=env, stdin=subprocess.DEVNULL)
    time.sleep(1.0)
    during = marked(mark)
    p.wait(timeout=60)
    time.sleep(1.0)
    after = marked(mark)
    for path in (tree, driver):
        os.remove(path)
    if after:  # leave nothing behind for the next test
        cmd = ["pkill", "-9", "-f", mark] if os.name != "nt" else ["powershell", "-NoProfile", "-Command",
               "Get-CimInstance Win32_Process | Where-Object { $_.CommandLine -like ('*' + $env:MARK + '*') } | "
               "ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }"]
        subprocess.run(cmd, env={**os.environ, "MARK": mark}, capture_output=True)
    assert during > 0, "the tree never started (no marked processes before the kill)"
    assert after == 0, "%d marked processes outlived kill_tree (had %d before)" % (after, during)


if __name__ == "__main__":
    test_kill_tree_kills_grandchildren_and_late_forks()
    print("test_kill_tree: 1 test passed")
