#!/usr/bin/env python3
"""base_red.py refuses a base holding a red tool test the brief does not name (rows 23, 24), on a toy git repo."""
import os
import subprocess
import sys
import tempfile
import time

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


def test_a_brief_naming_another_directorys_test_claims_nothing():
    assert base_red.foreign(["tools/b/test_x.py"], "## Tests\n- tools/a/test_x.py\n") == ["tools/b/test_x.py"]


def test_every_tests_section_of_a_brief_counts():  # row 25 DeepSeek lens: only the first section was read
    assert base_red.foreign(["tools/test_a.py"], "## Tests\n- other\n## Do\nx\n## Tests\n- tools/test_a.py\n") == []


def test_a_bare_name_still_claims_by_basename():
    assert base_red.foreign(["tools/b/test_x.py"], "## Tests\n- test_x.py\n") == []


def test_a_longer_file_name_claims_nothing():
    assert base_red.foreign(["tools/test_a.py"], "## Tests\n- tools/test_a.py.bak\n") == ["tools/test_a.py"]
    assert base_red.foreign(["tools/test_a.py"], "## Tests\n- tools/test_a.py.\n") == []  # a period ends the line
    assert base_red.foreign(["tools/test_a.py"], "## Tests\n- tools/test_a.py, tools/test_b.py\n") == []
    assert base_red.foreign(["tools/test_a.py"], "## Tests\n- (tools/test_a.py)\n") == []


def stale_worktree(g, age_s):
    """A registered worktree in a base_red* temp dir whose age is age_s: what a run killed by timeout leaves."""
    stale = tempfile.mkdtemp(prefix="base_red").replace("\\", "/")
    git(g, "worktree", "add", "-q", "--detach", stale + "/wt", "HEAD")
    old = time.time() - age_s
    os.utime(stale, (old, old))
    return stale


def test_a_worktree_left_by_a_killed_run_is_removed():
    top, g = toy()
    stale = stale_worktree(g, 2 * 3600)
    rc, out = run(top, g, "# brief\n")
    assert rc == 0, out
    assert len(git(g, "worktree", "list").stdout.splitlines()) == 1, "a killed run's worktree stayed registered"
    assert not os.path.exists(stale + "/wt"), "a killed run's worktree directory stayed"


def test_a_fresh_worktree_of_a_concurrent_run_stays():
    top, g = toy()
    live = stale_worktree(g, 5)  # another launch is still testing its base: never pull its checkout away
    rc, out = run(top, g, "# brief\n")
    assert rc == 0, out
    assert os.path.exists(live + "/wt") and len(git(g, "worktree", "list").stdout.splitlines()) == 2


def test_a_broken_tool_tests_import_is_exit_2_not_a_refusal():  # row 25 agy lens: exit 1 would refuse a clean base
    top, g = toy()
    lone = tempfile.mkdtemp().replace("\\", "/")
    with open(TOOLS + "/base_red.py", encoding="utf-8") as f:
        put(lone + "/base_red.py", f.read())  # beside no tool_tests.py: the import fails
    put(top + "/brief.md", "# brief\n")
    p = subprocess.run([sys.executable, lone + "/base_red.py", top + "/brief.md", "HEAD"], cwd=g, capture_output=True,
                       text=True, stdin=subprocess.DEVNULL)
    assert p.returncode == 2 and "could not run" in p.stdout + p.stderr, (p.returncode, p.stdout, p.stderr)


def test_pipeline_toys_with_wall_clock_bounds_run_alone_and_base_red_leaves_them_out():  # row 26, 11-02
    """test_routing and test_run_state flaked red under base_red's parallel load and refused a clean base (a wall-clock
    bound is a race, never loosened): a test that runs whole pipelines is SERIAL, which base_red skips."""
    import tool_tests
    for name in ("tools/test_build_pipeline.py", "tools/test_py_runs.py", "tools/test_run_state.py", "tools/test_scope_stage.py"):
        assert name in tool_tests.SERIAL, name


if __name__ == "__main__":
    from tool_tests import run_cases
    run_cases([v for k, v in sorted(globals().items()) if k.startswith("test_")], "test_base_red")
