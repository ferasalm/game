#!/usr/bin/env python3
"""Self-test for build_pipeline.sh, oc_task.sh, agy_task.sh and lib.sh on a toy repo: stub builder, stub memory, real git."""
import os
import subprocess
import sys
import tempfile
import time

TOOLS = os.path.dirname(os.path.abspath(__file__)).replace("\\", "/")
PIPE = TOOLS + "/build_pipeline.sh"
CHECK_TOY = '#!/bin/bash\n[ -f fail.flag ] && { echo "FAIL toy"; exit 1; }\necho "all checks passed"\n'
FAKE_BUILDER = r'''#!/bin/bash
# stub builder: <name> <prompt> <base> [model]; FAKE_MODE good|test_edit|nothing|hang
. "$LIBSH"
name="$1"; root="$(git rev-parse --show-toplevel)"; wt="$(wt_dir)/$name"
ensure_wt "$root" "$wt" "oc/$name" "$3" || exit 1
read -t 0.3 -r _ ; echo "$?" > "$(wt_dir)/$name.stdin.rc"
cp "$2" "$(wt_dir)/$name.prompt.seen"
cd "$wt"
case "${FAKE_MODE:-good}" in
  good) mkdir -p features; echo "## a" > features/a.gd; git add -A; git -c user.name=t -c user.email=t@t commit -qm feat ;;
  test_edit) echo "# edited" >> tests/t.gd; git add -A; git -c user.name=t -c user.email=t@t commit -qm cheat ;;
  nothing) : ;;
  hang) ping -n 60 127.0.0.1 > /dev/null & wait ;;
  commit_then_hang) mkdir -p features; echo "## a" > features/a.gd; git add -A
    git -c user.name=t -c user.email=t@t commit -qm feat; ping -n 60 127.0.0.1 > /dev/null & wait ;;
esac
'''
FAKE_BIN = r'''#!/bin/bash
echo "ARGS: $@"
if [ "$OS" = Windows_NT ]; then ping -n 30 127.0.0.1 > /dev/null & else sleep 30 & fi
wait
'''


def sh(cwd, *cmd, env=None, check=True):
    return subprocess.run(list(cmd), cwd=cwd, capture_output=True, text=True, env=env, check=check)


def git(cwd, *a):
    return sh(cwd, "git", "-c", "user.name=t", "-c", "user.email=t@t", *a)


def put(path, text, mode=None):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8", newline="\n") as f:
        f.write(text)
    if mode is not None:
        os.chmod(path, mode)


def ping_count():
    """Leaked fake-builder children: native PING.EXE on Windows, `sleep 30` elsewhere."""
    if os.name != "nt":
        return len(subprocess.run(["pgrep", "-f", "^sleep 30$"], capture_output=True, text=True).stdout.split())
    out = subprocess.run(["tasklist", "/FI", "IMAGENAME eq PING.EXE"], capture_output=True, text=True).stdout
    return out.upper().count("PING.EXE")


def toy():
    """(top, main checkout): origin.git bare, game/ with tests/t.gd, assets/a.png.import, stub check.sh, pushed."""
    top = tempfile.mkdtemp().replace("\\", "/")
    sh(top, "git", "init", "-q", "--bare", "-b", "main", "origin.git")
    sh(top, "git", "clone", "-q", "origin.git", "game")
    g = top + "/game"
    put(g + "/tools/check.sh", CHECK_TOY)
    put(g + "/tests/t.gd", "func test_a():\n\tcheck_true(true)\n")
    put(g + "/assets/a.png.import", "[remap]\nv=1\n")
    put(g + "/.claude/rules/code.md", "RULE-MARKER: typed GDScript\n")
    git(g, "add", "-A")
    git(g, "commit", "-qm", "base")
    git(g, "push", "-q", "origin", "HEAD:main")
    git(g, "fetch", "-q", "origin")
    return top, g


BRIEF = "# Brief: toy\n## What to build\n1. a\n## Do NOT edit\n`content/none.json`\n## Checklist\n- file: features/a.gd\n"


def pipeline(g, top, name="job", base="main", **env_extra):
    put(top + "/fake_builder.sh", FAKE_BUILDER)
    put(top + "/brief.md", BRIEF)
    env = {**os.environ, "BUILDER_CMD": top + "/fake_builder.sh", "FREE_MB": "99999", "NEWTEST_KINDS": "py", "LIBSH": TOOLS + "/lib.sh", **env_extra}
    env.pop("GAME_WT_DIR", None)
    p = subprocess.Popen(["bash", PIPE, "cf", name, top + "/brief.md", base], cwd=g, env=env, stdin=subprocess.PIPE,
                         stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    out, err = p.stdout.read(), p.stderr.read()
    p.wait()
    p.stdin.close()
    return p.returncode, out, err


def result(top, name="job"):
    return open(f"{top}/game-wt/{name}.result", encoding="utf-8").read()


def test_good_run_passes_with_pid_rules_import_and_detached_stdin():
    top, g = toy()
    rc, out, err = pipeline(g, top, IMPORT_CMD="touch ../imp.flag; echo x >> assets/a.png.import")
    res = result(top)
    assert rc == 0 and res.startswith("PASS"), (rc, out, err, res)
    assert "\npid " in res, res
    assert "RULE-MARKER" in open(top + "/game-wt/job.prompt.seen", encoding="utf-8").read(), "code.md pasted"
    assert os.path.exists(top + "/game-wt/imp.flag"), "--import ran in the worktree"
    assert open(top + "/game-wt/job.stdin.rc").read().strip() == "1", "builder stdin must be /dev/null, not the caller's pipe"
    assert "BREACH" not in res, "import churn on assets/*.import must not breach: " + res


def test_nonzero_exit_unless_pass():
    top, g = toy()
    rc, out, err = pipeline(g, top, FAKE_MODE="test_edit")
    assert rc != 0 and result(top).startswith("BREACH"), (rc, result(top))
    top, g = toy()
    rc, out, err = pipeline(g, top, FAKE_MODE="nothing")
    assert rc != 0 and result(top).startswith("NOWORK"), (rc, result(top))


def test_refuses_when_slots_full():
    top, g = toy()
    for n, b in (("a", "agy"), ("b", "cf")):
        put(f"{top}/game-wt/{n}.result", f"RUNNING 10:00 build\nbuilder {b}\n")
        put(f"{top}/game-wt/{n}.log", "x")
    rc, out, err = pipeline(g, top)
    assert rc != 0 and "REFUSED" in out + err and not os.path.exists(top + "/game-wt/job.result"), (rc, out, err)


def test_refuses_an_unpushed_base():
    top, g = toy()
    git(g, "checkout", "-q", "-b", "work")
    put(g + "/x.txt", "x")
    git(g, "add", "-A")
    git(g, "commit", "-qm", "unpushed")
    git(g, "push", "-q", "origin", "work")
    put(g + "/y.txt", "y")
    git(g, "add", "-A")
    git(g, "commit", "-qm", "more, unpushed")
    rc, out, err = pipeline(g, top, base="work")
    assert rc != 0 and "unpushed" in out + err, (rc, out, err)


def test_idle_watchdog_kills_the_tree_and_says_nowork():
    top, g = toy()
    before = ping_count()
    t0 = time.time()
    rc, out, err = pipeline(g, top, FAKE_MODE="hang", IDLE_SEC="3", WATCH_POLL="1")
    assert rc != 0 and result(top).startswith("NOWORK") and "idle" in result(top), (rc, result(top))
    assert time.time() - t0 < 60
    time.sleep(1)
    assert ping_count() <= before, "the native child of the builder must die with it (taskkill //T)"


def test_idle_after_commits_is_checked_not_nowork():  # review 2026-10-27: builders often hang after their last commit
    top, g = toy()
    rc, out, err = pipeline(g, top, FAKE_MODE="commit_then_hang", IDLE_SEC="3", WATCH_POLL="1")
    res = result(top)
    assert rc == 0 and res.startswith("PASS") and "idle" in res, (rc, res)


def fake_bin(top):
    for n in ("opencode", "agy"):
        put(f"{top}/bin/{n}", FAKE_BIN, 0o755)
    return {**os.environ, "PATH": f"{top}/bin{os.pathsep}" + os.environ["PATH"], "HOME": top, "FREE_MB": "99999"}


def task(g, top, script, name, base, **env_extra):
    env = {**fake_bin(top), **env_extra}
    return subprocess.run(["bash", f"{TOOLS}/{script}", name, top + "/brief.md", base], cwd=g, env=env,
                          capture_output=True, text=True, stdin=subprocess.DEVNULL)


def test_oc_task_default_model_deepseek_outer_timeout_and_base_check():
    top, g = toy()
    put(top + "/brief.md", BRIEF)
    before = ping_count()
    t0 = time.time()
    r = task(g, top, "oc_task.sh", "job", "origin/main", OC_TIMEOUT="2s")
    log = open(top + "/game-wt/job.log", encoding="utf-8").read()
    assert "deepseek" in log and "free" in log, log
    assert "opencode exited 124" in log and time.time() - t0 < 40, (r.stdout, r.stderr, log)
    time.sleep(1)
    assert ping_count() <= before, "timeout must kill native children too"
    put(g + "/z.txt", "z")
    git(g, "add", "-A")
    git(g, "commit", "-qm", "newer")
    git(g, "push", "-q", "origin", "HEAD:main")
    git(g, "fetch", "-q", "origin")
    r = task(g, top, "oc_task.sh", "job", "origin/main", OC_TIMEOUT="2s")
    assert r.returncode != 0 and "another base" in r.stderr, (r.returncode, r.stderr)


def test_agy_task_has_an_outer_timeout():
    top, g = toy()
    put(top + "/brief.md", BRIEF)
    t0 = time.time()
    task(g, top, "agy_task.sh", "job", "origin/main", AGY_TIMEOUT="2s")
    log = open(top + "/game-wt/job.log", encoding="utf-8").read()
    assert "agy exited 124" in log and time.time() - t0 < 40, log


def test_coreutils_timeout_is_the_gnu_one():
    r = sh(".", "bash", "-c", "timeout 1 sleep 5; echo $?")
    assert r.stdout.strip() == "124", r.stdout + r.stderr


if __name__ == "__main__":
    tests = [v for k, v in sorted(globals().items()) if k.startswith("test_")]
    for t in tests:
        t()
    print(f"test_build_pipeline: {len(tests)} tests passed")
