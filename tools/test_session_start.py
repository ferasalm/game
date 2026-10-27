#!/usr/bin/env python3
"""Self-test for .claude/hooks/session-start.sh (reports the session's own worktree) and the .gitignore .env rule."""
import os
import subprocess
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
HOOK = ROOT + "/.claude/hooks/session-start.sh"


def test_hook_reports_the_worktree_not_the_project_dir():
    top = tempfile.mkdtemp()
    subprocess.run(["git", "init", "-q", "--bare", "-b", "main", top + "/o.git"], check=True)
    subprocess.run(["git", "clone", "-q", top + "/o.git", top + "/main"], check=True, capture_output=True)
    g = ["git", "-C", top + "/main", "-c", "user.name=t", "-c", "user.email=t@t"]
    subprocess.run([*g, "commit", "-q", "--allow-empty", "-m", "x"], check=True)
    subprocess.run([*g, "push", "-q", "origin", "HEAD:main"], check=True, capture_output=True)
    subprocess.run([*g, "worktree", "add", "-q", "-b", "side", top + "/side"], check=True)
    env = dict(os.environ, CLAUDE_PROJECT_DIR=top + "/main")
    out = subprocess.run(["bash", HOOK], cwd=top + "/side", env=env, capture_output=True, text=True).stdout
    assert "SYNC: side is 0 behind" in out, out


def test_fetch_is_capped_by_timeout():
    assert "timeout 15 git fetch" in open(HOOK, encoding="utf-8").read()


def test_env_files_are_git_ignored():
    r = subprocess.run(["git", "-C", ROOT, "check-ignore", "-q", ".env"])
    assert r.returncode == 0, ".env must be in .gitignore"


if __name__ == "__main__":
    tests = [v for k, v in sorted(globals().items()) if k.startswith("test_")]
    for t in tests:
        t()
    print(f"test_session_start: {len(tests)} tests passed")
