#!/usr/bin/env python3
"""Self-test for tools/handoff.sh (row 23 b, 2026-11-01) in a throwaway repo with a bare origin and stub steps.
Order of steps: map, doc_check, check, commit, push, ci (only with --main). Output ends HANDOFF PASS or HANDOFF FAIL <step>."""
import os
import shutil
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__))).replace("\\", "/")
BASH = shutil.which("bash") or "bash"


def sh(cwd, *cmd, env=None):
    return subprocess.run(list(cmd), cwd=cwd, capture_output=True, text=True, env=env, encoding="utf-8")


def git(cwd, *a):
    return sh(cwd, "git", "-c", "user.name=t", "-c", "user.email=t@t", *a)


def put(path, text):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8", newline="\n") as f:
        f.write(text)


def toy(map_ok=True, doc_ok=True, check_ok=True):
    """(top, repo): origin.git bare + clone with tools/handoff.sh and three stub steps; one pushed commit on main."""
    top = tempfile.mkdtemp().replace("\\", "/")
    sh(top, "git", "init", "-q", "--bare", "-b", "main", "origin.git")
    sh(top, "git", "clone", "-q", "origin.git", "repo")
    g = top + "/repo"
    # handoff.sh runs plain `git commit`; the CI runner has no global identity (2026-11-01).
    sh(g, "git", "config", "user.name", "t")
    sh(g, "git", "config", "user.email", "t@t")
    os.makedirs(g + "/tools", exist_ok=True)
    shutil.copy(ROOT + "/tools/handoff.sh", g + "/tools/handoff.sh")
    put(g + "/tools/map.py", "import sys\nsys.exit(0 if %s else 1)\n" % map_ok)
    put(g + "/tools/doc_check.py", "import sys\nsys.exit(0 if %s else 1)\n" % doc_ok)
    put(g + "/tools/check.sh", "echo 'FAIL stub_check'\nexit 1\n" if not check_ok else "echo 'all checks passed'\n")
    put(g + "/README.md", "one\n")
    git(g, "add", "-A")
    git(g, "commit", "-qm", "base")
    git(g, "push", "-q", "origin", "HEAD:main")
    git(g, "checkout", "-q", "-b", "work")
    return top, g


def run(g, msg, *flags, ci=None):
    env = {**os.environ, "HANDOFF_CI": ci} if ci else dict(os.environ)
    return sh(g, BASH, "tools/handoff.sh", msg, *flags, env=env)


def origin_rev(top, ref):
    r = sh(top, "git", "--git-dir=origin.git", "rev-parse", "--verify", "-q", ref)
    return r.stdout.strip()


def last_line(r):
    return (r.stdout.strip().splitlines() or [""])[-1]


def test_pass_commits_and_pushes_the_current_branch_not_main():
    top, g = toy()
    put(g + "/README.md", "two\n")
    msg = "Row 23: thing\n\nCo-Authored-By: Claude <noreply@anthropic.com>"
    r = run(g, msg)
    assert r.returncode == 0 and last_line(r) == "HANDOFF PASS", r.stdout + r.stderr
    assert git(g, "log", "-1", "--format=%B").stdout.strip() == msg
    assert origin_rev(top, "refs/heads/work") == git(g, "rev-parse", "HEAD").stdout.strip()
    assert origin_rev(top, "refs/heads/main") != origin_rev(top, "refs/heads/work"), "only --main touches main"


def test_branch_tracking_another_branch_pushes_to_that_branch():
    top, g = toy()
    git(g, "push", "-q", "origin", "HEAD:shared")
    git(g, "branch", "-q", "--set-upstream-to=origin/shared")
    put(g + "/README.md", "two\n")
    r = run(g, "m")
    assert r.returncode == 0 and last_line(r) == "HANDOFF PASS", r.stdout + r.stderr
    assert origin_rev(top, "refs/heads/shared") == git(g, "rev-parse", "HEAD").stdout.strip()
    assert origin_rev(top, "refs/heads/work") == "", "no stray same-named branch on origin"


def test_each_failing_step_stops_the_run_and_names_itself():
    for kwargs, step in (({"map_ok": False}, "map"), ({"doc_ok": False}, "doc_check"), ({"check_ok": False}, "check")):
        top, g = toy(**kwargs)
        put(g + "/README.md", "two\n")
        r = run(g, "m")
        assert r.returncode != 0 and last_line(r) == f"HANDOFF FAIL {step}", (step, r.stdout, r.stderr)
        assert git(g, "log", "--oneline").stdout.count("\n") == 1, f"nothing is committed after a failed {step}"
        assert origin_rev(top, "refs/heads/work") == "", f"nothing is pushed after a failed {step}"
        if step == "check":
            assert "FAIL stub_check" in r.stdout + r.stderr, "the failing check's own FAIL line is shown"


def test_main_flag_pushes_head_to_main_and_reads_the_ci_result():
    top, g = toy()
    put(g + "/README.md", "two\n")
    r = run(g, "m", "--main", ci="echo success")
    assert r.returncode == 0 and last_line(r) == "HANDOFF PASS", r.stdout + r.stderr
    assert origin_rev(top, "refs/heads/main") == git(g, "rev-parse", "HEAD").stdout.strip()
    put(g + "/README.md", "three\n")
    r = run(g, "m2", "--main", ci="echo failure")
    assert r.returncode != 0 and last_line(r) == "HANDOFF FAIL ci", r.stdout + r.stderr


def test_nothing_to_commit_still_pushes_and_passes():
    top, g = toy()
    r = run(g, "m")
    assert r.returncode == 0 and last_line(r) == "HANDOFF PASS", r.stdout + r.stderr
    assert "nothing to commit" in r.stdout
    assert origin_rev(top, "refs/heads/work") == git(g, "rev-parse", "HEAD").stdout.strip()


def test_detached_head_fails_at_push_with_no_commit_lost():
    top, g = toy()
    git(g, "checkout", "-q", "--detach")
    put(g + "/README.md", "two\n")
    r = run(g, "m")
    assert r.returncode != 0 and last_line(r) == "HANDOFF FAIL push", r.stdout + r.stderr


def test_usage_and_script_hygiene():
    r = sh(ROOT, BASH, "tools/handoff.sh")
    assert r.returncode != 0 and "Usage" in r.stdout + r.stderr
    text = open(ROOT + "/tools/handoff.sh", encoding="utf-8").read()
    assert "set -o pipefail" in text or "pipefail" in text, "no pipe may hide an exit code"
    assert "--no-verify" not in text


def test_skill_moved_to_pm_plugin_and_old_door_points_at_it():
    new = open(ROOT + "/plugins/pm/skills/handoff/SKILL.md", encoding="utf-8").read()
    assert new.startswith("---\nname: handoff") and "tools/handoff.sh" in new and "decisions-log" in new
    assert "tools/check.sh" in new and len(new.splitlines()) <= 60
    old = open(ROOT + "/.claude/skills/handoff/SKILL.md", encoding="utf-8").read()
    assert "plugins/pm/skills/handoff/SKILL.md" in old and len(old.splitlines()) <= 8, "a pointer until row 25's cutover"


if __name__ == "__main__":
    from tool_tests import run_cases
    run_cases([v for k, v in sorted(globals().items()) if k.startswith("test_")], "test_handoff")
