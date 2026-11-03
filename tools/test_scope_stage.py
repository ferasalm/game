#!/usr/bin/env python3
"""Row 26 S5 (Feras 11-02, GLM max writes the tests, the head reads them, DeepSeek builds against them): the test-first
stage as tools. scope_gate.py judges a test-writing run (only tests changed, at least one new test, every new test fails
on the base), build_pipeline.sh with EXPECT_RED=1 runs that judgement instead of check + fix passes and writes the result
word SCOPED or REJECT, and lock_tests.sh turns a SCOPED run into the hand's base branch (generated docs refreshed, pushed),
replacing the branch-and-DOCMAP steps done by hand five times on 11-02."""
import os
import shutil
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from test_build_pipeline import BRIEF, pipeline, put, result, git, toy  # noqa: E402

GATE = os.path.join(HERE, "scope_gate.py")
LOCK = os.path.join(HERE, "lock_tests.sh")
RED_TEST = "import sys\n\n\ndef test_new_rule():\n    assert False, 'red until the rule is built'\n\n\nif __name__ == '__main__':\n    test_new_rule()\n"
GREEN_TEST = "def test_nothing():\n    assert True\n\n\nif __name__ == '__main__':\n    test_nothing()\n"


def repo():
    """A git repo with one commit (tools/a.py, tools/test_a.py) and a brief; returns (dir, base_sha, brief)."""
    d = tempfile.mkdtemp().replace("\\", "/")
    git(d, "init", "-q", "-b", "main")
    git(d, "config", "user.email", "t@t")
    git(d, "config", "user.name", "t")
    put(d + "/tools/a.py", "A = 1\n")
    put(d + "/tools/test_a.py", GREEN_TEST)
    put(d + "/docs/MAP.md", "map\n")
    git(d, "add", "-A")
    git(d, "commit", "-qm", "base")
    base = subprocess.run(["git", "-C", d, "rev-parse", "HEAD"], capture_output=True, text=True).stdout.strip()
    put(d + "/brief.md", "# Brief: x\n\n## May edit\nnone\n\n## Tests\n- tools/test_new.py :: every test\n")
    return d, base


def judge(d, base):
    r = subprocess.run([sys.executable, GATE, "check", "--wt", d, "--base", base, "--brief", d + "/brief.md"],
                       capture_output=True, text=True, timeout=120)
    return r.returncode, r.stdout


def commit(d, msg="work"):
    git(d, "add", "-A")
    git(d, "commit", "-qm", msg)


def test_a_new_failing_test_alone_is_scoped():
    d, base = repo()
    put(d + "/tools/test_new.py", RED_TEST)
    put(d + "/docs/MAP.md", "map\n+ tools/test_new.py\n")  # generated docs may move with it
    commit(d)
    rc, out = judge(d, base)
    assert rc == 0 and out.strip().splitlines()[-1] == "VERDICT SCOPED", (rc, out)


def test_product_code_in_a_test_run_is_rejected_and_named():
    d, base = repo()
    put(d + "/tools/test_new.py", RED_TEST)
    put(d + "/tools/a.py", "A = 2\n")
    commit(d)
    rc, out = judge(d, base)
    assert rc != 0 and out.strip().splitlines()[-1] == "VERDICT REJECT" and "tools/a.py" in out, (rc, out)


def test_a_new_test_that_passes_on_the_base_proves_nothing():
    d, base = repo()
    put(d + "/tools/test_new.py", GREEN_TEST)
    commit(d)
    rc, out = judge(d, base)
    assert rc != 0 and "passes on the base" in out and out.strip().splitlines()[-1] == "VERDICT REJECT", (rc, out)


def test_no_new_test_file_is_rejected():
    d, base = repo()
    put(d + "/docs/MAP.md", "changed\n")
    commit(d)
    rc, out = judge(d, base)
    assert rc != 0 and "no new test" in out and out.strip().splitlines()[-1] == "VERDICT REJECT", (rc, out)


def test_editing_or_deleting_an_existing_test_is_rejected():
    d, base = repo()
    put(d + "/tools/test_new.py", RED_TEST)
    put(d + "/tools/test_a.py", "def test_nothing():\n    pass\n")
    commit(d)
    rc, out = judge(d, base)
    assert rc != 0 and "tools/test_a.py" in out, (rc, out)


SCOPER = r"""#!/bin/bash
# stub test-writing builder: SCOPE_MODE red | product
. "$LIBSH"
name="$1"; root="$(git rev-parse --show-toplevel)"; wt="$(wt_dir)/$name"
ensure_wt "$root" "$wt" "oc/$name" "$3" || exit 1; cd "$wt"
mkdir -p features
printf 'def test_new_rule():\n    assert False\n\n\nif __name__ == "__main__":\n    test_new_rule()\n' > features/test_new.py
[ "${SCOPE_MODE:-red}" = product ] && echo "## a" > features/a.gd
git add -A; git -c user.name=t -c user.email=t@t commit -qm scoped
"""


def scope_run(mode):
    top, g = toy()
    put(top + "/scoper.sh", SCOPER)
    shutil.copy(HERE + "/scope_gate.py", g + "/tools/scope_gate.py")
    git(g, "add", "-A")
    git(g, "commit", "-qm", "scope gate")
    git(g, "push", "-q", "origin", "HEAD:main")
    rc, out, err = pipeline(g, top, EXPECT_RED="1", NEWTEST_KINDS="py", BUILDER_CMD=top + "/scoper.sh", SCOPE_MODE=mode,
                            LIBSH=HERE + "/lib.sh")
    return rc, result(top), out + err


def test_expect_red_runs_the_scope_gate_not_check_and_fix_passes():
    rc, res, log = scope_run("red")
    assert rc == 0 and res.startswith("SCOPED"), (rc, res, log)
    assert "VERDICT SCOPED" in res and "fix pass" not in res, res


def test_expect_red_rejects_product_code():
    rc, res, log = scope_run("product")
    assert rc != 0 and res.startswith("REJECT") and "features/a.gd" in res, (rc, res, log)


def test_lock_tests_makes_the_hand_base_from_a_scoped_run():
    top, g = toy()
    wt = top + "/game-wt"
    git(g, "worktree", "add", "-q", "-b", "oc/job", wt + "/job")
    put(wt + "/job/features/test_new.py", RED_TEST)
    git(wt + "/job", "add", "-A")
    git(wt + "/job", "commit", "-qm", "tests")
    put(wt + "/job.result", "SCOPED 10:00 oc/job\nbuilder nv\nVERDICT SCOPED\n")
    env = {**os.environ, "GAME_WT_DIR": wt}
    r = subprocess.run(["bash", LOCK, "job", "job-base"], cwd=g, env=env, capture_output=True, text=True, timeout=120)
    assert r.returncode == 0 and r.stdout.strip().splitlines()[-1].startswith("LOCKED job-base "), (r.stdout, r.stderr)
    assert subprocess.run(["git", "-C", g, "ls-remote", "--heads", "origin", "job-base"], capture_output=True,
                          text=True).stdout.strip(), "the base branch must be pushed (build_pipeline refuses an unpushed base)"
    put(wt + "/job.result", "REJECT 10:00 oc/job\nbuilder nv\nVERDICT REJECT\n")
    r = subprocess.run(["bash", LOCK, "job", "job-base2"], cwd=g, env=env, capture_output=True, text=True, timeout=120)
    assert r.returncode != 0 and "SCOPED" in r.stdout + r.stderr, (r.stdout, r.stderr)


if __name__ == "__main__":
    from tool_tests import run_cases
    run_cases([v for k, v in sorted(globals().items()) if k.startswith("test_")], "test_scope_stage")
