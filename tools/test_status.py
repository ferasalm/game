#!/usr/bin/env python3
"""Self-test for tools/status.sh: python tools/test_status.py (a temp repo with planted branches, exit 1 on failure)."""
import os
import subprocess
import sys
import tempfile

SCRIPT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "status.sh")
GIT_ENV = {"GIT_AUTHOR_NAME": "t", "GIT_AUTHOR_EMAIL": "t@t", "GIT_COMMITTER_NAME": "t", "GIT_COMMITTER_EMAIL": "t@t"}

HANDOFF = """# HANDOFF
## Queue
| # | task | lane | status |
|---|---|---|---|
| 1 | old work | builder | done |
| 2 | hooks | builder | running |
| 3 | M1 spike | chat | next |
| 4 | art bake | chat | next |
| 5 | fifth | builder | next |
## Open points
| what | since |
|---|---|
| play M1 | 10-28 |
## Notes
| not | a queue row |
|---|---|
| x | y |
"""


def git(repo, *args, env_extra=None):
    env = {**os.environ, **GIT_ENV, **(env_extra or {})}
    subprocess.run(["git", "-C", repo, *args], check=True, capture_output=True, env=env)


def write(path, text):
    with open(path, "w", encoding="utf-8", newline="\n") as f:
        f.write(text)


def commit(repo, name, env_extra=None):
    write(os.path.join(repo, name), name)
    git(repo, "add", name)
    git(repo, "commit", "-q", "-m", name, env_extra=env_extra)


def make_repo():
    root = tempfile.mkdtemp()
    repo = os.path.join(root, "game")
    os.makedirs(repo)
    git(repo, "init", "-q", "-b", "main")
    write(os.path.join(repo, "HANDOFF.md"), HANDOFF)
    git(repo, "add", "HANDOFF.md")
    git(repo, "commit", "-q", "-m", "base")
    git(repo, "branch", "done-br")
    git(repo, "worktree", "add", "-q", os.path.join(root, "wt-done"), "done-br")
    commit(os.path.join(root, "wt-done"), "done.txt")
    git(repo, "merge", "-q", "--ff-only", "done-br")
    git(repo, "worktree", "add", "-q", "-b", "open-br", os.path.join(root, "wt-open"), "main")
    commit(os.path.join(root, "wt-open"), "open.txt")
    write(os.path.join(root, "wt-open", "loose.txt"), "uncommitted")
    git(repo, "worktree", "add", "-q", "--detach", os.path.join(root, "wt-det-done"), "main")
    git(repo, "worktree", "add", "-q", "--detach", os.path.join(root, "wt-det-open"), "main")
    commit(os.path.join(root, "wt-det-open"), "det.txt")
    git(repo, "checkout", "-q", "-b", "old-br")
    commit(repo, "old.txt", env_extra={"GIT_COMMITTER_DATE": "2020-01-01T00:00:00"})
    git(repo, "checkout", "-q", "main")
    write(os.path.join(repo, "stray.txt"), "untracked")
    return root, repo


def run_status(repo):
    wt = tempfile.mkdtemp()
    env = {**os.environ, "GAME_WT_DIR": wt, "FREE_MB": "99999"}
    r = subprocess.run(["bash", SCRIPT], cwd=repo, env=env, capture_output=True, text=True)
    assert r.returncode == 0, r.stderr
    return r.stdout


def section(out, title):
    part = out.split("== " + title, 1)[1]
    return part.split("\n== ", 1)[0]


def test_branches_worktrees_and_queue():
    _, repo = make_repo()
    out = run_status(repo)
    unmerged = section(out, "Not on main yet")
    assert "open-br: 1 commits" in unmerged and "worktree wt-open, uncommitted changes" in unmerged, out
    assert "done-br" not in unmerged, "a merged branch is listed as unmerged:\n" + out
    assert "old-br" not in unmerged and "+ 1 older unmerged branches" in unmerged, out
    idle = section(out, "Worktrees with nothing beyond main")
    assert "wt-done" in idle and "wt-open" not in idle, out
    assert "wt-det-done" in idle and "wt-det-open" not in idle, "a detached worktree is missed:\n" + out
    assert "(detached) wt-det-open: 1 commits" in unmerged, out
    assert "Main checkout: 1 uncommitted or untracked paths" in out and "stray.txt" in out, out
    queue = section(out, "Queue")
    assert "hooks" in queue and "M1 spike" in queue and "art bake" in queue, out
    assert "old work" not in queue and "fifth" not in queue and "| # |" not in queue, out
    assert "|---" not in queue, out
    waiting = section(out, "Open points")
    assert "play M1" in waiting and "a queue row" not in waiting and "| what |" not in waiting, out


def test_no_queue_table():
    _, repo = make_repo()
    write(os.path.join(repo, "HANDOFF.md"), "# HANDOFF\n## Track: x\n- prose only\n")
    git(repo, "commit", "-q", "-am", "prose")
    out = run_status(repo)
    assert "(no Queue table in HANDOFF.md)" in section(out, "Queue"), out
    assert "(none)" in section(out, "Open points"), out


if __name__ == "__main__":
    failed = 0
    for name, fn in sorted(globals().items()):
        if name.startswith("test_") and callable(fn):
            try:
                fn()
                print("ok  ", name)
            except AssertionError as e:
                failed += 1
                print("FAIL", name, e)
    sys.exit(1 if failed else 0)
