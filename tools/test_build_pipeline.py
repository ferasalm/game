#!/usr/bin/env python3
"""Self-test for build_pipeline.sh, oc_task.sh, agy_task.sh and lib.sh on a toy repo: stub builder, stub memory, real git."""
import json
import os
import subprocess
import sys
import random
import tempfile
import time

from test_kill_tree import marked

TOOLS = os.path.dirname(os.path.abspath(__file__)).replace("\\", "/")
# A py run's check.sh runs this file with the pipeline's own RUN_KIND=py set: the toy runs then judged a Godot edit as
# a py breach and every py run went red (race B, 10-28). The toys start from a clean pipeline env.
for _k in ("RUN_KIND", "SKIP_BUILD", "BUILDER_CMD", "IMPORT_CMD", "IDLE_SEC", "NEWTEST_KINDS", "FIX_PASSES"):
    os.environ.pop(_k, None)
PIPE = TOOLS + "/build_pipeline.sh"
CHECK_TOY = '#!/bin/bash\n[ -f fail.flag ] && { echo "FAIL toy"; exit 1; }\necho "all checks passed"\n'
FAKE_BUILDER = r'''#!/bin/bash
# stub builder: <name> <prompt> <base> [model]; FAKE_MODE good|test_edit|nothing|hang; hang children carry $FAKE_MARK
. "$LIBSH"
name="$1"; root="$(git rev-parse --show-toplevel)"; wt="$(wt_dir)/$name"
ensure_wt "$root" "$wt" "oc/$name" "$3" || exit 1
read -t 0.3 -r _ ; echo "$?" > "$(wt_dir)/$name.stdin.rc"
cp "$2" "$(wt_dir)/$name.prompt.seen"
echo "model=${4:-}" >> "$(wt_dir)/$name.models"
cd "$wt"
case "${FAKE_MODE:-good}" in
  good) mkdir -p features; echo "## a" > features/a.gd; git add -A; git -c user.name=t -c user.email=t@t commit -qm feat ;;
  test_edit) echo "# edited" >> tests/t.gd; git add -A; git -c user.name=t -c user.email=t@t commit -qm cheat ;;
  nothing) : ;;
  hang) "$PYEXE" -c "import time; time.sleep(60)" "$FAKE_MARK" & echo up > "$(wt_dir)/$name.child"; wait ;;
  quota) echo 'level=ERROR error.error="AI_APICallError: Free usage limit reached. Free models work in OpenCode"'
    "$PYEXE" -c "import time; time.sleep(60)" "$FAKE_MARK" & wait ;;
  commit_then_hang) mkdir -p features; echo "## a" > features/a.gd; git add -A
    git -c user.name=t -c user.email=t@t commit -qm feat; "$PYEXE" -c "import time; time.sleep(60)" "$FAKE_MARK" & wait ;;
  bg_check) mkdir -p features; echo "## a" > features/a.gd; echo '$ bash tools/check.sh --no-godot > log 2>&1'
    echo 'Command moved to the background (shell ID: sh_1).'; "$PYEXE" -c "import time; time.sleep(60)" "$FAKE_MARK" & wait ;;
  fork_fail) mkdir -p features; echo "## a" > features/a.gd; echo 'tools/lib.sh: fork: retry: Resource temporarily unavailable' ;;
esac
'''
FAKE_BIN = r'''#!/bin/bash
echo "ARGS: $@"
"$PYEXE" -c "import time; time.sleep(30)" "$FAKE_MARK" & echo up > "$HOME/child.up"
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


def child_env():
    """A per-test marker for the stub builders' native children (python.exe), so counts see only this test's."""
    return {"FAKE_MARK": "ngmark%06d" % random.randrange(10 ** 6), "PYEXE": sys.executable.replace("\\", "/")}


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


def pipeline(g, top, name="job", base="main", brief=BRIEF, **env_extra):
    put(top + "/fake_builder.sh", FAKE_BUILDER)
    put(top + "/brief.md", brief)
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



def test_missing_skill_warns():  # P2b review: a skill the brief loads but .agents/skills lacks was skipped silently
    top, g = toy()
    rc, out, err = pipeline(g, top, brief=BRIEF + "Load the ghost-skill skill.\n")
    assert rc == 0 and result(top).startswith("PASS"), (rc, err, result(top))
    assert "WARN" in err and "ghost-skill" in err, err

def test_nonzero_exit_unless_pass():
    top, g = toy()
    rc, out, err = pipeline(g, top, FAKE_MODE="test_edit")
    assert rc != 0 and result(top).startswith("BREACH"), (rc, result(top))
    top, g = toy()
    rc, out, err = pipeline(g, top, FAKE_MODE="nothing")
    assert rc != 0 and result(top).startswith("NOWORK"), (rc, result(top))


CHECK_COUNT = '#!/bin/bash\nn=$(( $(cat ../checks.n 2>/dev/null || echo 0) + 1 )); echo $n > ../checks.n\n' \
    '[ $n -ge 3 ] && { echo "all checks passed"; exit 0; }\necho "FAIL toy $n"; exit 1\n'


def test_two_free_fix_passes_by_default():  # Feras 10-28: builder time is free, so a second pass before Opus
    for passes, word in ((None, "PASS"), ("1", "FAIL")):
        top, g = toy()
        put(g + "/tools/check.sh", CHECK_COUNT)
        git(g, "add", "-A")
        git(g, "commit", "-qm", "check passes on its third run")
        git(g, "push", "-q", "origin", "HEAD:main")
        rc, out, err = pipeline(g, top, **({"FIX_PASSES": passes} if passes else {}))
        assert result(top).startswith(word), (passes, result(top), err)
        assert "Fix pass" in open(top + "/game-wt/job.fix.md", encoding="utf-8").read()


def test_fix_passes_move_to_the_reasoning_model():  # row 18: a no-reasoning build, its failures go to DeepSeek at max
    top, g = toy()
    put(g + "/tools/check.sh", CHECK_COUNT)
    git(g, "add", "-A")
    git(g, "commit", "-qm", "check passes on its third run")
    git(g, "push", "-q", "origin", "HEAD:main")
    rc, out, err = pipeline(g, top, FIX_MODEL="think-model")
    seen = open(top + "/game-wt/job.models", encoding="utf-8").read().split()
    assert seen == ["model=", "model=think-model", "model=think-model"], seen


def test_task_skills_and_pattern_files_reach_the_prompt():
    top, g = toy()
    brief = BRIEF + "Load the players-eye-gate skill.\nPattern: tests/t.gd, tests/ghost.gd\n"
    rc, out, err = pipeline(g, top, brief=brief)
    seen = open(top + "/game-wt/job.prompt.seen", encoding="utf-8").read()
    assert "## Skill: players-eye-gate" in seen, "a .claude/skills task skill is pasted"
    assert "## Pattern to follow: tests/t.gd" in seen and "check_true(true)" in seen, seen[-400:]
    assert "WARN" in err and "tests/ghost.gd" in err and "Pattern to follow: tests/ghost" not in seen, err


def test_fast_model_is_the_same_deepseek_without_reasoning():
    cfg = json.load(open(os.path.join(TOOLS, "..", "opencode.json"), encoding="utf-8"))
    models = cfg["provider"]["cloudflare-workers-ai"]["models"]
    fast = models["deepseek-v4.1-flash-fast"]
    assert fast["id"] in models and fast["options"]["reasoning_effort"] == "none", fast
    conf = open(os.path.join(TOOLS, "builders.conf"), encoding="utf-8").read()
    assert "cloudflare-workers-ai/deepseek-v4.1-flash-fast" in conf and "gemini-3.8-flash-medium" in conf


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
    kids = child_env()
    t0 = time.time()
    rc, out, err = pipeline(g, top, FAKE_MODE="hang", IDLE_SEC="3", WATCH_POLL="1", **kids)
    assert rc != 0 and result(top).startswith("NOWORK") and "idle" in result(top), (rc, result(top))
    assert time.time() - t0 < 60
    assert os.path.exists(top + "/game-wt/job.child"), "the stub builder never started its native child"
    time.sleep(1)
    assert marked(kids["FAKE_MARK"]) == 0, "the native child of the builder must die with it (kill_tree)"


def test_idle_after_commits_is_checked_not_nowork():  # review 2026-10-27: builders often hang after their last commit
    top, g = toy()
    # 3 s was shorter than the stub's worktree + first commit on a loaded machine: it read as NOWORK (10-31)
    rc, out, err = pipeline(g, top, FAKE_MODE="commit_then_hang", IDLE_SEC="10", WATCH_POLL="1", **child_env())
    res = result(top)
    assert rc == 0 and res.startswith("PASS") and "idle" in res, (rc, res)


def test_a_check_moved_to_the_background_is_killed_and_its_work_checked():  # fast-probe-stream's 25 idle min (row 18c)
    top, g = toy()
    t0 = time.time()
    rc, out, err = pipeline(g, top, FAKE_MODE="bg_check", BG_WAIT_SEC="2", IDLE_SEC="300", WATCH_POLL="1", **child_env())
    res = result(top)
    assert rc == 0 and res.startswith("PASS") and "background: build killed" in res, (rc, res, err)
    assert time.time() - t0 < 120, "the background line must stop the run long before the idle limit"


def test_builders_are_told_to_commit_first_and_keep_the_check_in_front():  # also the fix pass's prompt (row 18c)
    top, g = toy()
    rc, out, err = pipeline(g, top, FAKE_MODE="nothing", FIX_PASSES="0")
    prompt = open(top + "/game-wt/job.prompt.seen", encoding="utf-8").read()
    assert "Commit before your first check" in prompt and "in the foreground" in prompt, prompt[-400:]
    top, g = toy()
    put(g + "/fail.flag", "x\n")
    git(g, "add", "-A")
    git(g, "commit", "-qm", "fails")
    git(g, "push", "-q", "origin", "HEAD:main")
    rc, out, err = pipeline(g, top, FIX_PASSES="1")
    fix = open(top + "/game-wt/job.fix.md", encoding="utf-8").read()
    assert "Commit before your first check" in fix and "in the foreground" in fix, fix


def test_stale_map_is_refreshed_and_committed_before_the_check():  # a new file cost fast-probe-stream a fix pass (row 18c)
    top, g = toy()
    put(g + "/tools/map.py", "open('docs/MAP.md', 'w', newline='\\n').write(__import__('subprocess').run("
        "['git', 'ls-files'], capture_output=True, text=True).stdout)\n")
    put(g + "/docs/MAP.md", "stale\n")
    put(g + "/tools/check.sh", '#!/bin/bash\ngrep -q features/a.gd docs/MAP.md || { echo "FAIL stale"; exit 1; }\n'
        'echo "all checks passed"\n')
    git(g, "add", "-A")
    git(g, "commit", "-qm", "map")
    git(g, "push", "-q", "origin", "HEAD:main")
    rc, out, err = pipeline(g, top, FIX_PASSES="0")
    res = result(top)
    assert rc == 0 and res.startswith("PASS"), (rc, res, err)
    assert "docs/MAP.md refreshed" in res, res


def test_a_fork_failure_is_named_in_the_result():  # 600 MB free killed a build at its first check, exit 127 (row 18c)
    top, g = toy()
    rc, out, err = pipeline(g, top, FAKE_MODE="fork_fail")
    assert "memory: fork failed" in result(top), result(top)


def test_spent_free_quota_stops_the_run_at_once_as_nowork():  # row16-audit (10-29): 25 silent min on a spent quota
    top, g = toy()
    t0 = time.time()
    rc, out, err = pipeline(g, top, FAKE_MODE="quota", IDLE_SEC="300", WATCH_POLL="1", **child_env())
    res = result(top)
    assert rc != 0 and res.startswith("NOWORK") and "quota" in res and "cf_build" in res, (out, err, res)
    assert time.time() - t0 < 60, "the quota line must stop the run long before the idle limit"


def fake_bin(top):
    for n in ("opencode", "agy"):
        put(f"{top}/bin/{n}", FAKE_BIN, 0o755)
    return {**os.environ, "PATH": f"{top}/bin{os.pathsep}" + os.environ["PATH"], "HOME": top, "FREE_MB": "99999",
            "OC_BIN": "opencode"}


def task(g, top, script, name, base, **env_extra):
    env = {**fake_bin(top), **env_extra}
    return subprocess.run(["bash", f"{TOOLS}/{script}", name, top + "/brief.md", base], cwd=g, env=env,
                          capture_output=True, text=True, stdin=subprocess.DEVNULL)


def test_oc_task_default_model_deepseek_outer_timeout_and_base_check():
    top, g = toy()
    put(top + "/brief.md", BRIEF)
    kids = child_env()
    t0 = time.time()
    r = task(g, top, "oc_task.sh", "job", "origin/main", OC_TIMEOUT="2s", **kids)
    log = open(top + "/game-wt/job.log", encoding="utf-8").read()
    assert "deepseek" in log and "free" in log, log
    assert "--print-logs" in log, ("without it a spent free quota prints nothing (10-29)", log)
    # v2 (row 18): without --standalone the shared service runs it (no logs, other config, survives the timeout);
    # v2 rejects "ERROR" and exits 1
    assert "--standalone" in log and "--log-level error" in log, log
    assert "opencode exited 124" in log and time.time() - t0 < 40, (r.stdout, r.stderr, log)
    assert os.path.exists(top + "/child.up"), "the fake opencode never started its native child"
    time.sleep(1)
    assert marked(kids["FAKE_MARK"]) == 0, "timeout must kill native children too"
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
    task(g, top, "agy_task.sh", "job", "origin/main", AGY_TIMEOUT="2s", **child_env())
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
