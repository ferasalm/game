#!/usr/bin/env python3
"""Row 26 (11-02): two opencode v2 servers started in the same second share one SQLite database; the second died with
"database is locked / Standalone server exited before reporting readiness" before doing any work, and the pipeline reported a
bare NOWORK quoting the first (useless) INFO line. oc_task.sh now retries a STARTUP failure (no commit yet) a few times with a
short random wait, never a real failure; and a NOWORK reason names the log's error line, not its first line."""
import os
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from test_build_pipeline import BRIEF, child_env, pipeline, put, result, toy  # noqa: E402

STUB = r"""#!/usr/bin/env bash
n=$(cat "$STUB_TOP/n" 2> /dev/null || echo 0); n=$((n + 1)); echo $n > "$STUB_TOP/n"
echo "ARGS $*"
if [ "${STUB_MODE:-}" = locked ] && [ "$n" -le "${FAIL_FIRST:-0}" ]; then
  echo 'timestamp=2026-11-02T08:34:02Z level=ERROR message="cli process failed" cause="Cause([Die(SQLiteError: database is locked)])"'
  echo "Error: Standalone server exited before reporting readiness"
  exit 1
fi
[ "${STUB_MODE:-}" = boom ] && { echo "Error: model refused the request"; exit 2; }
echo "ran ok"
"""


def run_task(mode, fail_first=0, tries=None):
    top, g = toy()
    put(top + "/brief.md", BRIEF)
    put(top + "/bin/opencode", STUB)
    os.chmod(top + "/bin/opencode", 0o755)
    env = {**os.environ, "PATH": f"{top}/bin{os.pathsep}" + os.environ["PATH"], "HOME": top, "FREE_MB": "99999",
           "OC_BIN": "opencode", "STUB_TOP": top, "STUB_MODE": mode, "FAIL_FIRST": str(fail_first), "OC_START_WAIT": "0",
           "OC_TIMEOUT": "30s", **child_env()}
    if tries is not None:
        env["OC_START_TRIES"] = str(tries)
    subprocess.run(["bash", HERE + "/oc_task.sh", "job", top + "/brief.md", "origin/main"], cwd=g, env=env,
                   capture_output=True, text=True, stdin=subprocess.DEVNULL, timeout=120)
    log = open(top + "/game-wt/job.log", encoding="utf-8").read()
    attempts = int(open(top + "/n", encoding="utf-8").read())
    return log, attempts


def test_a_startup_collision_is_retried_and_the_second_try_runs():
    log, attempts = run_task("locked", fail_first=1)
    assert attempts == 2 and "ran ok" in log and "opencode exited" not in log, (attempts, log[-400:])


def test_a_startup_failure_gives_up_after_the_configured_tries_and_says_so():
    log, attempts = run_task("locked", fail_first=9, tries=3)
    assert attempts == 3 and "opencode exited 1" in log and "database is locked" in log, (attempts, log[-400:])


def test_a_real_failure_is_not_retried():
    log, attempts = run_task("boom")
    assert attempts == 1 and "opencode exited 2" in log and "model refused the request" in log, (attempts, log[-400:])


def test_a_nowork_reason_is_the_error_line_not_the_first_log_line():
    top, g = toy()
    put(top + "/info_then_error.sh", "#!/bin/bash\n"
        '. "$LIBSH"\nname="$1"; root="$(git rev-parse --show-toplevel)"; wt="$(wt_dir)/$name"\n'
        'ensure_wt "$root" "$wt" "oc/$name" "$3" || exit 1\n'  # the worktree exists, the builder then dies with no commit
        "echo 'timestamp=2026-11-02T08:34:01Z level=INFO message=\"cli starting\"'\n"
        "echo 'timestamp=2026-11-02T08:34:02Z level=INFO message=\"spawning process\"'\n"
        "echo 'Error: Standalone server exited before reporting readiness'\nexit 1\n")
    rc, out, err = pipeline(g, top, BUILDER_CMD=top + "/info_then_error.sh", LIBSH=HERE + "/lib.sh")
    res = result(top)
    assert rc != 0 and res.startswith("NOWORK"), (rc, res)
    why = [ln for ln in res.splitlines() if ln.startswith("why:")]
    assert why and "Standalone server exited before reporting readiness" in why[0] and "cli starting" not in why[0], res


if __name__ == "__main__":
    from tool_tests import run_cases
    run_cases([v for k, v in sorted(globals().items()) if k.startswith("test_")], "test_oc_start_retry", serial=())
