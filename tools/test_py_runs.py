#!/usr/bin/env python3
"""Self-test for non-Godot builder runs (row 12 C, 2026-10-28): python tools/test_py_runs.py.
A py run (RUN_KIND=py) takes its builder's slot but no Godot slot and no memory floor, checks with
check.sh --no-godot, may change no Godot file (the gate fails it), and merge_run never reuses its check."""
import os
import shutil
import subprocess
import sys
import tempfile

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import build_gate as bg  # noqa: E402
from test_build_pipeline import TOOLS, PIPE, toy, put, git, sh, result  # noqa: E402

SLOTS = TOOLS + "/slots.sh"


def slots(wt_dir, *args, **env_extra):
    env = {**os.environ, "GAME_WT_DIR": wt_dir, "CAP_AGY": "2", "CAP_CF": "2", "CAP_OC": "1", "CAP_GODOT": "2",
           "FREE_MB": "99999", **env_extra}
    return subprocess.run(["bash", SLOTS, *args], env=env, capture_output=True, text=True)


def running(d, name, builder, kind=None):
    put(f"{d}/{name}.result", f"RUNNING 10:00 build\nbuilder {builder}\npid \n" + (f"kind {kind}\n" if kind else ""))
    put(f"{d}/{name}.log", "x")


def test_py_run_takes_no_godot_slot():
    d = tempfile.mkdtemp().replace("\\", "/")
    running(d, "a", "agy", "godot")
    running(d, "b", "cf")  # a result from before the kind line counts as a Godot run
    running(d, "c", "agy", "py")
    r = slots(d, CAP_AGY="3")
    assert "godot 2/2" in r.stdout and "agy 2/3" in r.stdout, r.stdout
    r = slots(d, "can-start", "agy", "py", CAP_AGY="3", FREE_MB="100")
    assert r.returncode == 0, ("a py run needs no Godot slot and no memory floor", r.stdout)
    for args in (("agy", "godot"), ("agy",)):  # no kind = godot
        r = slots(d, "can-start", *args, CAP_AGY="3")
        assert r.returncode == 1 and "REFUSED: godot" in r.stdout, (args, r.stdout)


def test_builder_cap_holds_for_every_kind():
    d = tempfile.mkdtemp().replace("\\", "/")
    running(d, "a", "agy", "py")
    running(d, "b", "agy", "py")
    r = slots(d, "can-start", "agy", "py")
    assert r.returncode == 1 and "REFUSED: agy 2/2" in r.stdout, r.stdout
    d = tempfile.mkdtemp().replace("\\", "/")
    running(d, "c", "cf", "py")
    r = slots(d, "can-start", "cf", "godot", CAP_CF="1")
    assert r.returncode == 1 and "REFUSED: cf 1/1" in r.stdout, ("CAP_CF was never checked", r.stdout)
    r = slots(d, "can-start", "agy", "py", CAP_AGY="1")
    assert r.returncode == 0, r.stdout


def check_toy():
    """A repo with the real check.sh, lib.sh, builders.conf, check_slot.sh, stub Python checks and a stub run_godot.sh
    that records every call in godot.calls."""
    d = tempfile.mkdtemp().replace("\\", "/")
    sh(d, "git", "init", "-q", "-b", "main")
    os.makedirs(d + "/tools")
    for f in ("check.sh", "lib.sh", "builders.conf", "check_slot.sh"):
        shutil.copy(f"{TOOLS}/{f}", f"{d}/tools/{f}")
    for f in ("doc_check.py", "lint_gd.py", "res_graph.py", "oc_agents.py"):
        put(f"{d}/tools/{f}", "print('ok')\n")
    put(d + "/tools/run_godot.sh", '#!/bin/bash\necho "$@" >> "$(dirname "$0")/../godot.calls"\n', 0o755)
    put(d + "/.gitignore", ".check/\ngodot.calls\n")
    git(d, "add", "-A")
    git(d, "commit", "-qm", "toy")
    return d


def test_check_no_godot_runs_no_godot():
    d = check_toy()
    env = {**os.environ, "CHECK_SLOT_DIR": d + "/slots"}
    r = subprocess.run(["bash", "tools/check.sh", "--no-godot"], cwd=d, env=env, capture_output=True, text=True)
    assert r.returncode == 0 and "all checks passed" in r.stdout, r.stdout + r.stderr
    assert not os.path.exists(d + "/godot.calls"), "check.sh --no-godot ran Godot: " + open(d + "/godot.calls").read()
    for name in ("docs", "lint", "res_graph", "tool_tests", "repo_untouched"):
        assert f"ok   {name}" in r.stdout, (name, r.stdout)
    assert "no Godot" in r.stdout, ("say that import, tests and boot were skipped", r.stdout)
    assert not os.path.isdir(d + "/slots") or not os.listdir(d + "/slots"), "a py check takes no Godot test slot"
    r = subprocess.run(["bash", "tools/check.sh"], cwd=d, env=env, capture_output=True, text=True)
    calls = open(d + "/godot.calls").read()
    assert "--import" in calls and "runner.gd" in calls, ("the full check still runs Godot", calls)


PY_BUILDER = r'''#!/bin/bash
. "$LIBSH"
name="$1"; root="$(git rev-parse --show-toplevel)"; wt="$(wt_dir)/$name"
ensure_wt "$root" "$wt" "oc/$name" "$3" || exit 1
cd "$wt"; mkdir -p tools docs
echo "print('x')" > tools/new_tool.py; echo "# x" > docs/x.md
[ "${FAKE_MODE:-}" = gd ] && { mkdir -p features; echo "## a" > features/a.gd; }
git add -A; git -c user.name=t -c user.email=t@t commit -qm feat
'''
CHECK_ARGS = '#!/bin/bash\necho "$@" > ../check.args\necho "all checks passed"\n'
BRIEF = "# Brief: toy\n## What to build\n1. a\n## Do NOT edit\n`content/none.json`\n## Checklist\n- file: tools/new_tool.py\n"


def py_pipeline(top, g, **env_extra):
    put(g + "/tools/check.sh", CHECK_ARGS)
    git(g, "add", "-A")
    git(g, "commit", "-qm", "check records its args")
    git(g, "push", "-q", "origin", "HEAD:main")
    put(top + "/py_builder.sh", PY_BUILDER)
    put(top + "/brief.md", BRIEF)
    for n, b in (("x", "agy"), ("y", "cf")):  # both Godot slots full
        put(f"{top}/game-wt/{n}.result", f"RUNNING 10:00 build\nbuilder {b}\n")
        put(f"{top}/game-wt/{n}.log", "x")
    env = {**os.environ, "BUILDER_CMD": top + "/py_builder.sh", "FREE_MB": "100", "NEWTEST_KINDS": "py",
           "LIBSH": TOOLS + "/lib.sh", "RUN_KIND": "py", "IMPORT_CMD": "touch ../imp.flag", **env_extra}
    env.pop("GAME_WT_DIR", None)
    r = subprocess.run(["bash", PIPE, "agy", "job", top + "/brief.md", "main"], cwd=g, env=env,
                       capture_output=True, text=True, stdin=subprocess.DEVNULL)
    assert os.path.exists(top + "/game-wt/job.result"), ("refused: a py run must start with Godot slots full", r.stdout)
    return r


def test_pipeline_py_run():
    top, g = toy()
    r = py_pipeline(top, g)
    res = result(top)
    assert r.returncode == 0 and res.startswith("PASS"), (r.stdout, r.stderr, res)
    assert "\nkind py\n" in res, res
    assert "--no-godot" in open(top + "/game-wt/check.args").read(), "a py run checks with check.sh --no-godot"
    assert not os.path.exists(top + "/game-wt/imp.flag"), "a py run never imports in Godot"


def test_pipeline_py_run_that_touches_godot_fails():
    top, g = toy()
    r = py_pipeline(top, g, FAKE_MODE="gd")
    res = result(top)
    assert r.returncode != 0 and res.startswith("FAIL") and "py run" in res and "features/a.gd" in res, res


def gate_repo():
    repo = tempfile.mkdtemp()
    sh(repo, "git", "init", "-q", "-b", "main")
    put(repo + "/a.gd", "## a\nvar x: int = 0\n")
    git(repo, "add", "-A")
    git(repo, "commit", "-qm", "base")
    return repo, bg.git(repo, "rev-parse", "HEAD").strip()


def run_gate(repo, base, kind):
    put(repo + "_x/check.txt", "ok   docs\nall checks passed\n")
    put(repo + "_x/brief.md", "# Brief\n## Do NOT edit\n`content/none.json`\n")
    args = ["gate", "--wt", repo, "--base", base, "--brief", repo + "_x/brief.md", "--check", repo + "_x/check.txt",
            "--inbox", repo + "_x", "--kind", kind]
    from io import StringIO
    old, sys.stdout = sys.stdout, StringIO()
    try:
        code = bg.main(args)
        out = sys.stdout.getvalue()
    finally:
        sys.stdout = old
    return code, out


def test_gate_fails_a_py_run_that_changes_godot_files():
    for path in ("features/b.gd", "scenes/x.tscn", "assets/p.png", "content/k/a.json", "project.godot",
                 "localization/x.csv", "a.gd"):
        repo, base = gate_repo()
        put(f"{repo}/tools/t.py", "print(1)\n")
        put(f"{repo}/{path}", "## x\n")
        git(repo, "add", "-A")
        git(repo, "commit", "-qm", "feat")
        code, out = run_gate(repo, base, "py")
        assert code == 1 and "py run" in out and path in out and out.strip().endswith("VERDICT FAIL"), (path, out)
        code, out = run_gate(repo, base, "godot")
        assert "py run" not in out, (path, out)
    repo, base = gate_repo()
    put(f"{repo}/tools/t.py", "print(1)\n")
    put(f"{repo}/docs/d.md", "# d\n")
    git(repo, "add", "-A")
    git(repo, "commit", "-qm", "feat")
    code, out = run_gate(repo, base, "py")
    assert code == 0 and out.strip().endswith("VERDICT PASS"), out


def test_merge_run_never_reuses_a_py_check():
    top = tempfile.mkdtemp().replace("\\", "/")
    repo = top + "/game"
    os.makedirs(repo)
    sh(repo, "git", "init", "-q", "-b", "main")
    put(repo + "/tools/check.sh", '#!/bin/bash\ntouch ../full.check\necho "all checks passed"\n')
    git(repo, "add", "-A")
    git(repo, "commit", "-qm", "base")
    wt = top + "/game-wt/job"
    git(repo, "worktree", "add", "-q", "-b", "gemini/job", wt)
    put(wt + "/tools/new.py", "print(1)\n")
    git(wt, "add", "-A")
    git(wt, "commit", "-qm", "work")
    checked = bg.git(wt, "rev-parse", "HEAD").strip()
    put(top + "/game-wt/job.result", f"PASS 12:00 gemini/job\nbuilder agy\npid 1\nkind py\nchecked {checked}\n")
    r = subprocess.run(["bash", TOOLS + "/merge_run.sh", "job"], cwd=repo, capture_output=True, text=True)
    assert r.returncode == 0 and "check reused" not in r.stdout, r.stdout + r.stderr
    assert os.path.exists(top + "/full.check"), "a py run's --no-godot check must not stand in for the full check"


if __name__ == "__main__":
    tests = [v for k, v in sorted(globals().items()) if k.startswith("test_")]
    for t in tests:
        t()
    print(f"test_py_runs: {len(tests)} tests passed")
