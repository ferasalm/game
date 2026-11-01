#!/usr/bin/env python3
"""base_red.py refuses a base holding a red tool test the brief does not name (rows 23, 24), on a toy git repo."""
import os
import subprocess
import sys
import tempfile

TOOLS = os.path.dirname(os.path.abspath(__file__)).replace("\\", "/")
sys.path.insert(0, TOOLS)
import base_red  # noqa: E402


def put(path, text):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8", newline="\n") as f:
        f.write(text)


def git(cwd, *a):
    return subprocess.run(["git", "-c", "user.name=t", "-c", "user.email=t@t", *a], cwd=cwd, capture_output=True,
                          text=True, check=True)


def toy(*red):
    """A repo with a green tool test, a red slow toy (it must stay out) and the red tests named."""
    top = tempfile.mkdtemp().replace("\\", "/")
    g = top + "/game"
    os.makedirs(g)
    git(g, "init", "-q", "-b", "main")
    put(g + "/tools/test_green.py", "print('ok')\n")
    put(g + "/tools/test_build_pipeline.py", "raise SystemExit(1)\n")
    for name in red:
        put(f"{g}/tools/{name}", "raise SystemExit(1)\n")
    git(g, "add", "-A")
    git(g, "commit", "-qm", "base")
    return top, g


def run(top, g, brief, base="HEAD"):
    put(top + "/brief.md", brief)
    p = subprocess.run([sys.executable, TOOLS + "/base_red.py", top + "/brief.md", base], cwd=g, capture_output=True,
                       text=True, stdin=subprocess.DEVNULL)
    return p.returncode, p.stdout + p.stderr


def test_a_failing_test_the_brief_names_is_the_parts_own():
    assert base_red.foreign(["tools/test_a.py", "tools/test_b.py"], "## Tests\n- tools/test_a.py\n") == ["tools/test_b.py"]


def test_a_name_outside_the_tests_section_claims_nothing():
    brief = "## Do NOT edit\n`tools/test_a.py`\n## Tests\n- tools/my_test_a.py\n## Checklist\n- tools/test_a.py\n"
    assert base_red.foreign(["tools/test_a.py"], brief) == ["tools/test_a.py"]


def test_a_foreign_red_test_is_refused_and_the_worktree_goes():
    top, g = toy("test_sibling.py")
    rc, out = run(top, g, "# brief\n")
    assert rc == 1 and "tools/test_sibling.py" in out, out
    assert "test_build_pipeline" not in out, out  # a slow toy tests the pipeline, not a part
    assert len(git(g, "worktree", "list").stdout.splitlines()) == 1, "the throwaway worktree stayed"


def test_the_owner_of_a_red_test_may_launch():
    top, g = toy("test_mine.py")
    rc, out = run(top, g, "## Tests\n- tools/test_mine.py\n")
    assert rc == 0, out


def test_a_clean_base_passes():
    top, g = toy()
    rc, out = run(top, g, "# brief\n")
    assert rc == 0, out


def test_a_base_with_no_tool_tests_passes():
    top = tempfile.mkdtemp().replace("\\", "/")
    g = top + "/game"
    os.makedirs(g)
    git(g, "init", "-q", "-b", "main")
    put(g + "/a.txt", "a\n")
    git(g, "add", "-A")
    git(g, "commit", "-qm", "base")
    rc, out = run(top, g, "# brief\n")
    assert rc == 0, out


def test_it_says_when_it_could_not_run():
    top, g = toy()
    rc, out = run(top, g, "# brief\n", base="no-such-commit")
    assert rc == 2 and "could not run" in out, out


if __name__ == "__main__":
    from tool_tests import run_cases
    run_cases([v for k, v in sorted(globals().items()) if k.startswith("test_")], "test_base_red")
