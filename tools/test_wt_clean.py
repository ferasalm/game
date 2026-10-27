#!/usr/bin/env python3
"""Self-test for tools/wt_clean.sh: merged and dead builder worktrees go, live and unmerged ones stay."""
import os
import subprocess
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__)).replace("\\", "/")


def test_wt_clean():
    top = tempfile.mkdtemp().replace("\\", "/")
    subprocess.run(["git", "init", "-q", "-b", "main", top + "/game"], check=True)
    g = ["git", "-C", top + "/game", "-c", "user.name=t", "-c", "user.email=t@t"]
    subprocess.run([*g, "commit", "-q", "--allow-empty", "-m", "base"], check=True)
    for n in ("merged", "unmerged", "live", "dead"):
        subprocess.run([*g, "worktree", "add", "-q", "-b", "oc/" + n, f"{top}/game-wt/{n}"], check=True)
    subprocess.run(["git", "-C", top + "/game-wt/unmerged", "-c", "user.name=t", "-c", "user.email=t@t", "commit", "-q",
                    "--allow-empty", "-m", "work"], check=True)
    sleeper = subprocess.Popen(["bash", "-c", "echo $$; sleep 30"], stdout=subprocess.PIPE, text=True)
    live_pid = sleeper.stdout.readline().strip()  # an msys pid, like the $$ the pipeline writes
    res = {"merged": "PASS 1:00 oc/merged\n", "unmerged": "PASS 1:00 oc/unmerged\n",
           "live": f"RUNNING 1:00 build\nbuilder cf\npid {live_pid}\n", "dead": "RUNNING 1:00 build\nbuilder cf\npid 999999\n"}
    for n, text in res.items():
        with open(f"{top}/game-wt/{n}.result", "w", newline="\n") as f:
            f.write(text)
    run = lambda *a: subprocess.run(["bash", HERE + "/wt_clean.sh", *a], cwd=top + "/game", capture_output=True, text=True).stdout
    dry = run()
    assert "would remove merged" in dry and "would remove dead" in dry and os.path.isdir(top + "/game-wt/merged"), dry
    run("--apply")
    left = sorted(d for d in os.listdir(top + "/game-wt") if os.path.isdir(f"{top}/game-wt/{d}"))
    assert left == ["live", "unmerged"], left
    assert not os.path.exists(top + "/game-wt/merged.result"), "its result file goes too"
    sleeper.kill()


if __name__ == "__main__":
    test_wt_clean()
    print("test_wt_clean: 1 tests passed")
