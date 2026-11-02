#!/usr/bin/env python3
"""Red tests, written first (row 26), for the spec in docs/briefs/row26-a-runstate.md; stubs only, this base does not build it yet."""
import csv
import datetime
import os
import re
import shutil
import tempfile
import time

from test_build_pipeline import BRIEF, FAKE_BUILDER, TOOLS, child_env, pipeline, put, result, sh, git, toy
from test_kill_tree import marked

os.environ["OC_BIN"] = "true"  # the spec's runs.csv step meters cf/oc runs through opencode: `true` = 0 sessions

TOY_BUILDER = r'''#!/bin/bash
# stub builder: FAKE2_MODE picks the mischief; break_git: the gate's git call crashes, so no VERDICT line
. "$LIBSH"
name="$1"; root="$(git rev-parse --show-toplevel)"; wt="$(wt_dir)/$name"
ensure_wt "$root" "$wt" "oc/$name" "$3" || exit 1; cd "$wt"
commit() { mkdir -p features; echo "## a" > features/a.gd; git add -A; git -c user.name=t -c user.email=t@t commit -qm feat; }
case "${FAKE2_MODE:-}" in
  del_brief) commit; rm -f "$KILL_BRIEF" ;; break_git) commit; echo broken > .git ;;
  bad_check) touch fail.flag; commit ;;
  slow_fix) case "$2" in *.fix.md) sleep 8; rm -f fail.flag; commit ;; *) touch fail.flag; commit ;; esac ;; tick) commit; for i in 1 2 3 4 5 6 7 8; do echo "tick $i"; sleep 1; done ;;
  beat) commit; mkdir -p .check; for i in 1 2 3 4 5 6 7 8; do touch .check/alive; sleep 1; done; rm -rf .check ;;
  hang2) case "$2" in *.fix.md) echo x > f2; git add -A; git -c user.name=t -c user.email=t@t commit -qm fix; sleep 30 ;;
    *) touch fail.flag; commit; sleep 30 ;; esac ;;
esac
'''


def stub_builder(top, mode, **env_extra):
    put(top + "/toy_builder.sh", TOY_BUILDER)
    return {"BUILDER_CMD": top + "/toy_builder.sh", "FAKE2_MODE": mode, **env_extra}


def toy_tools():
    """A toy whose base carries the metering tools, so $py tools/<tool> resolves from the pipeline's cwd."""
    top, g = toy()
    for f in ("runs_log.py", "oc_usage.py", "model_effort.py"): shutil.copy(f"{TOOLS}/{f}", f"{g}/tools/{f}")
    git(g, "add", "-A")
    git(g, "commit", "-qm", "run-state tools")
    git(g, "push", "-q", "origin", "HEAD:main")
    return top, g


def runs_rows(g):
    with open(g + "/docs/runs.csv", encoding="utf-8", newline="") as f:
        return list(csv.DictReader(f))


def launch(g, top, builder, name, model="", **env_extra):  # pipeline() with the builder and model argv exposed
    put(top + "/fake_builder.sh", FAKE_BUILDER)
    put(top + "/brief.md", BRIEF)
    env = {**os.environ, "BUILDER_CMD": top + "/fake_builder.sh", "FREE_MB": "99999", "NEWTEST_KINDS": "py",
           "LIBSH": TOOLS + "/lib.sh", **env_extra}
    env.pop("GAME_WT_DIR", None)
    argv = ["bash", TOOLS + "/build_pipeline.sh", builder, name, top + "/brief.md", "main"] + ([model] if model else [])
    r = sh(g, *argv, env=env, check=False)
    return r.returncode, r.stdout, r.stderr


def test_a_crashing_gate_is_error_not_fail():
    top, g = toy()
    rc, out, err = pipeline(g, top, **stub_builder(top, "break_git"))
    res = result(top)
    assert rc != 0 and res.startswith("ERROR") and re.search(r"^gate error: \S", res, re.M), (rc, res)


def test_the_brief_is_copied_at_launch():
    top, g = toy()
    rc, out, err = pipeline(g, top, **stub_builder(top, "del_brief", KILL_BRIEF=top + "/brief.md"))
    assert rc == 0 and result(top).startswith("PASS"), (rc, result(top), err)
    assert os.path.exists(top + "/game-wt/job.brief.md") and not os.path.exists(top + "/brief.md"), \
        "the launch must copy the brief beside the result (the stub deleted the original)"


def test_a_refused_launch_removes_the_old_pass_result():
    top, g = toy()
    put(top + "/game-wt/job.result", "PASS 10:00 oc/job\nbuilder oc\npid 1\nkind godot\n")
    for n, b in (("a", "agy"), ("b", "cf")):
        put(f"{top}/game-wt/{n}.result", f"RUNNING 10:00 build\nbuilder {b}\n")
        put(f"{top}/game-wt/{n}.log", "x")
    rc, out, err = pipeline(g, top)
    assert rc == 3 and "REFUSED" in out + err, (rc, out, err)
    assert not os.path.exists(top + "/game-wt/job.result"), "a refused launch must remove the stale PASS first"


def test_fix_passes_count_the_passes_that_ran():
    top, g = toy_tools()
    put(g + "/tools/check.sh", '#!/bin/bash\necho "FAIL toy always"\nexit 1\n')
    git(g, "add", "-A")
    git(g, "commit", "-qm", "check never passes")
    git(g, "push", "-q", "origin", "HEAD:main")
    rc, out, err = pipeline(g, top, FIX_PASSES="2")
    assert rc != 0 and result(top).startswith("FAIL"), (rc, out, err)
    row = runs_rows(g)[-1]
    assert row["task"] == "job" and row["gate"] == "FAIL" and row["fix_passes"] == "2", row


def test_result_header_has_model_and_idle_min():
    top, g = toy()
    rc, out, err = pipeline(g, top)
    res = result(top)
    assert rc == 0 and res.startswith("PASS"), (rc, res, err)
    model = re.search(r"CF_MODEL:=([^}]+)", open(TOOLS + "/builders.conf", encoding="utf-8").read()).group(1)
    assert f"\nmodel {model}\n" in res, res  # the builders.conf default for builder cf
    assert "\nidle_min 0\n" in res and "\nbuilder cf\n" in res and "\npid " in res and "\nkind godot\n" in res, res


def test_a_builder_that_commits_then_hangs_is_quiet_killed_early():
    top, g = toy()
    kids = child_env()
    t0 = time.time()
    rc, out, err = pipeline(g, top, FAKE_MODE="commit_then_hang", QUIET_SEC="3", IDLE_SEC="60", WATCH_POLL="1", **kids)
    res = result(top)
    assert rc == 0 and res.startswith("PASS") and time.time() - t0 < 40, (rc, res, err)
    assert re.search(r"^quiet: ", res, re.M) and re.search(r"^idle_min \d+$", res, re.M), res
    time.sleep(1)
    assert marked(kids["FAKE_MARK"]) == 0, "the quiet kill must take the builder's native child with it"


def test_a_builder_that_keeps_logging_is_not_quiet_killed():
    top, g = toy()
    rc, out, err = pipeline(g, top, QUIET_SEC="3", WATCH_POLL="1", **stub_builder(top, "tick"))
    res = result(top)
    assert rc == 0 and res.startswith("PASS"), (rc, res, err)
    assert not re.search(r"^quiet: ", res, re.M) and "\nidle_min 0\n" in res, res  # base: no header lines yet


def test_a_silent_fix_pass_with_no_commit_of_its_own_is_not_quiet_killed():
    top, g = toy()  # review 11-02: the build's commits made every fix pass look "committed", so it was cut after QUIET_SEC
    rc, out, err = pipeline(g, top, QUIET_SEC="3", WATCH_POLL="1", FIX_PASSES="1", **stub_builder(top, "slow_fix"))
    res = result(top)
    assert rc == 0 and res.startswith("PASS") and not re.search(r"^quiet: ", res, re.M), (rc, res, err)


def test_a_builder_waiting_on_its_check_heartbeat_is_not_quiet_killed():
    top, g = toy()  # review 11-02: check.sh prints nothing until a step ends; its .check/alive beat is the sign of life
    rc, out, err = pipeline(g, top, QUIET_SEC="3", WATCH_POLL="1", **stub_builder(top, "beat"))
    res = result(top)
    assert rc == 0 and res.startswith("PASS") and not re.search(r"^quiet: ", res, re.M), (rc, res, err)


def test_idle_minutes_are_summed_over_every_kill_of_the_run():
    top, g = toy_tools()  # a build kill AND a fix-pass kill: each costs QUIET_SEC; IDLE_UNIT=1 makes a "minute" one second
    kids = child_env()
    rc, out, err = pipeline(g, top, QUIET_SEC="3", WATCH_POLL="1", FIX_PASSES="1", IDLE_UNIT="1",
                            **stub_builder(top, "hang2"), **kids)
    idle = int(re.search(r"^idle_min (\d+)$", result(top), re.M).group(1))
    assert idle >= 6, (idle, "one kill costs 3-4 s here, two cost at least 6", result(top))
    assert runs_rows(g)[-1]["idle_min"] == str(idle), runs_rows(g)[-1]


def test_a_builder_with_no_commit_still_gets_the_idle_rule():
    top, g = toy()
    kids = child_env()
    rc, out, err = pipeline(g, top, FAKE_MODE="hang", IDLE_SEC="4", QUIET_SEC="2", WATCH_POLL="1", **kids)
    res = result(top)
    assert rc != 0 and res.startswith("NOWORK") and "idle" in res, (rc, res)
    assert re.search(r"^idle_min \d+$", res, re.M), res  # red on this base: NOWORK results gain the header lines too
    time.sleep(1)
    assert marked(kids["FAKE_MARK"]) == 0


def test_opencode_free_models_are_refused():
    free = "opencode/deepseek-v4.1-flash-free"
    top, g = toy()
    rc, out, err = launch(g, top, "oc", "job", free)
    assert rc == 3 and "REFUSED" in out + err and "cf_build.sh" in out + err, (rc, out, err)
    top, g = toy()
    rc, out, err = launch(g, top, "oc", "job", free, OC_ALLOW_FREE="1")
    assert rc == 0 and result(top).startswith("PASS"), (rc, out, err)


def test_every_end_path_appends_one_runs_csv_row():
    top, g = toy_tools()
    pipeline(g, top, name="p")
    pipeline(g, top, name="f", FIX_PASSES="0", **stub_builder(top, "bad_check"))
    pipeline(g, top, name="n", FAKE_MODE="nothing")
    for n, b in (("a", "agy"), ("b", "cf")):
        put(f"{top}/game-wt/{n}.result", f"RUNNING 10:00 build\nbuilder {b}\n")
        put(f"{top}/game-wt/{n}.log", "x")
    pipeline(g, top, name="r")
    rows = runs_rows(g)
    assert len(rows) == 4, rows
    for name, word in (("p", "PASS"), ("f", "FAIL"), ("n", "NOWORK"), ("r", "REFUSED")):
        mine = [r for r in rows if r["task"] == name]
        assert len(mine) == 1 and mine[0]["gate"] == word and mine[0]["cost_source"] == "unknown", (name, mine)
        assert mine[0]["tokens_in"] == mine[0]["tokens_out"] == mine[0]["usd_est"] == "?", mine[0]
        assert mine[0]["cost"] == mine[0]["real_findings"] == "?", ("unknown is ?, never 0", mine[0])


def test_a_refused_launch_appends_no_spend_line():
    stub = tempfile.mkdtemp().replace("\\", "/")
    put(stub + "/build_pipeline.sh", "#!/bin/bash\nexit 3\n")
    put(stub + "/lib.sh", 'lib_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"\npy=python\n'
        '$py -c "" > /dev/null 2>&1 || py=python3\nwt_dir() { echo "$GAME_WT_DIR"; }\n')
    for f in ("cf_build.sh", "slots.sh"): shutil.copy(f"{TOOLS}/{f}", f"{stub}/{f}")
    before = "date,task,input_tokens,output_tokens,usd\n2026-10-31,old,1,2,0.00\n"
    put(stub + "/wtd/cf_spend.csv", before)
    env = {**os.environ, "GAME_WT_DIR": stub + "/wtd", "CLOUDFLARE_ACCOUNT_ID": "x", "CF_MODEL": "m",
           "CF_INPUT_RATE": "0.30", "CF_OUTPUT_RATE": "1.20"}
    r = sh(stub, "bash", stub + "/cf_build.sh", "t", stub + "/b.md", "main", env=env, check=False)
    spend = open(stub + "/wtd/cf_spend.csv", encoding="utf-8").read()
    assert r.returncode == 3 and spend == before, (r.returncode, r.stdout, r.stderr, spend)


def test_append_spend_prefers_the_sessions_of_a_worktree():
    top = tempfile.mkdtemp().replace("\\", "/")
    put(top + "/oc_bin.sh", '#!/bin/bash\n[ "$2" = list ] && { printf "ses_1\\t2026-11-02\\tmain\\n"; exit 0; }\n'
        'printf \'{"info":{"location":{"directory":"' + top + '"},"tokens":{"input":1000,"output":200,"reasoning":0,'
        '"cache":{"read":0,"write":0}}}}\\n\'\n', 0o755)  # location = the worktree: the meter counts only this run's sessions
    put(top + "/job.log", "no token counts in this log\n")
    day = datetime.date.today().isoformat()
    env = {**os.environ, "OC_BIN": top + "/oc_bin.sh", "GAME_WT_DIR": top + "/wtd"}
    sh(TOOLS, "bash", TOOLS + "/slots.sh", "append-spend", top + "/job.log", "task", "0.30", "1.20", top + "/s1.csv", top, env=env)
    assert open(f"{top}/s1.csv", encoding="utf-8").read().splitlines()[-1] == f"{day},task,1000,200,0.00", "with WT"
    sh(TOOLS, "bash", TOOLS + "/slots.sh", "append-spend", top + "/job.log", "task", "0.30", "1.20", top + "/s2.csv", env=env)
    assert open(f"{top}/s2.csv", encoding="utf-8").read().splitlines()[-1] == f"{day},task,,,?", "no WT"


if __name__ == "__main__":
    from tool_tests import run_cases
    tests = [v for k, v in sorted(globals().items()) if k.startswith("test_")]
    run_cases(tests, "test_run_state", serial=(  # wall-clock bounds run alone; a limit is never loosened (10-31)
        "test_a_builder_that_commits_then_hangs_is_quiet_killed_early",
        "test_a_builder_that_keeps_logging_is_not_quiet_killed",
        "test_a_silent_fix_pass_with_no_commit_of_its_own_is_not_quiet_killed",
        "test_a_builder_waiting_on_its_check_heartbeat_is_not_quiet_killed",
        "test_idle_minutes_are_summed_over_every_kill_of_the_run",
        "test_a_builder_with_no_commit_still_gets_the_idle_rule"))
