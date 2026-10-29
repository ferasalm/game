#!/usr/bin/env python3
"""Self-test for tools/wait_run.sh (row 16): after its wait it reports each run and the best move: re-arm a running
run, read the log of a dead one, /handoff for a long one, gate a finished one."""
import os
import subprocess
import tempfile
import time

SCRIPT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "wait_run.sh")


def write(path, text):
    with open(path, "w", encoding="utf-8", newline="\n") as f:
        f.write(text)


def run(dir_, *tasks):
    env = dict(os.environ, GAME_WT_DIR=dir_, WAIT_SEC="0")
    r = subprocess.run(["bash", SCRIPT, *tasks], capture_output=True, text=True, env=env, stdin=subprocess.DEVNULL)
    assert r.returncode == 0, (r.returncode, r.stdout, r.stderr)
    return r.stdout


def test_running_run_is_re_armed_and_finished_one_is_gated():
    d = tempfile.mkdtemp()
    write(f"{d}/a.result", "RUNNING 21:04 build\nbuilder agy\nkind py\n")  # no pid line: liveness unknown
    write(f"{d}/a.prompt.md", "brief")
    write(f"{d}/b.result", "PASS 21:40 gemini/b\nbuilder agy\npid 1\n")
    out = run(d, "a", "b")
    assert "RUNNING a:" in out and "b: PASS 21:40" in out, out
    assert "Best move: re-arm in the background: bash tools/wait_run.sh a (" in out, out


def test_dead_and_long_runs_are_not_re_armed():
    d = tempfile.mkdtemp()
    write(f"{d}/dead.result", "RUNNING 21:04 build\npid 999999\n")
    write(f"{d}/long.result", "RUNNING 18:00 build\n")
    write(f"{d}/long.prompt.md", "brief")
    old = time.time() - 200 * 60
    os.utime(f"{d}/long.prompt.md", (old, old))
    out = run(d, "dead", "long", "gone")
    assert "DEAD dead:" in out and "do not re-arm" in out, out
    assert "LONG long: running 2" in out and "/handoff now" in out, out
    assert "MISSING gone" in out, out
    assert "Nothing to wait for" in out and "re-arm in the background" not in out, out


def test_no_task_is_a_timer_for_child_chats():  # father/child (Feras 10-29)
    out = run(tempfile.mkdtemp())
    assert out.startswith("Timer: check the child chats") and "re-arm" in out, out


if __name__ == "__main__":
    test_running_run_is_re_armed_and_finished_one_is_gated()
    test_dead_and_long_runs_are_not_re_armed()
    test_no_task_is_a_timer_for_child_chats()
    print("test_wait_run: 3 tests passed")
