#!/usr/bin/env python3
"""Self-test for .claude/hooks/session-start.sh (reports the session's own worktree) and the .gitignore .env rule."""
import json
import os
import subprocess
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
HOOK = ROOT + "/.claude/hooks/session-start.sh"


def repo_with_side_worktree():
    top = tempfile.mkdtemp()
    subprocess.run(["git", "init", "-q", "--bare", "-b", "main", top + "/o.git"], check=True)
    subprocess.run(["git", "clone", "-q", top + "/o.git", top + "/main"], check=True, capture_output=True)
    g = ["git", "-C", top + "/main", "-c", "user.name=t", "-c", "user.email=t@t"]
    subprocess.run([*g, "commit", "-q", "--allow-empty", "-m", "x"], check=True)
    subprocess.run([*g, "push", "-q", "origin", "HEAD:main"], check=True, capture_output=True)
    subprocess.run([*g, "worktree", "add", "-q", "-b", "side", top + "/side"], check=True)
    return top, dict(os.environ, CLAUDE_PROJECT_DIR=top + "/main")


def run_hook(cwd, env, stdin=""):
    return subprocess.run(["bash", HOOK], cwd=cwd, env=env, input=stdin, capture_output=True, text=True).stdout


def test_hook_reports_the_worktree_not_the_project_dir():
    top, env = repo_with_side_worktree()
    out = run_hook(top + "/side", env)
    assert "SYNC: side is 0 behind" in out, out


def test_hook_started_in_the_main_checkout_follows_the_session_cwd():
    # 10-28: the app ran the hook in C:\dev\game, so a worktree chat was told "main is 12 behind" by main's stale copy
    top, env = repo_with_side_worktree()
    out = run_hook(top + "/main", env, json.dumps({"session_id": "s", "cwd": os.path.normpath(top + "/side")}))
    assert "SYNC: side is 0 behind" in out, out
    os.makedirs(top + "/side/.claude/hooks")
    with open(top + "/side/.claude/hooks/session-start.sh", "w", encoding="utf-8", newline="\n") as f:
        f.write("echo OWN COPY $SESSION_START_REEXEC\n")
    out = run_hook(top + "/main", env, json.dumps({"cwd": top + "/side"}))
    assert out.strip() == "OWN COPY 1", out  # the worktree's own script runs, not the project dir's


def test_hook_prints_the_top_queue_row():  # row 15 (10-29): the owner hears the top row without a HANDOFF read
    top, env = repo_with_side_worktree()
    assert "TOP:" not in run_hook(top + "/side", env), "no HANDOFF.md: no TOP line, no crash"
    with open(top + "/side/HANDOFF.md", "w", encoding="utf-8", newline="\n") as f:
        f.write("# H\n| 1 | not the queue | A | b | c | d | - |\n## Queue\n| # | Task | Dept | Lane | Who | Status | Blocked by |\n"
                "|---|---|---|---|---|---|---|\n| 15 | Hook prints the row | Ops | builder | agy | queued | - |\n"
                "| 12 | Later row | Ops | builder | agy | queued | 15 |\n")
    out = run_hook(top + "/side", env)
    assert "TOP: #15 Hook prints the row | Ops | builder | agy" in out and "Later row" not in out, out


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
