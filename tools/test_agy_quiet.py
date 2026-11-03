#!/usr/bin/env python3
"""Row 26 (11-02): `agy -p` prints its log only when it finishes, so an agy run's log stays 0 bytes while it works. The quiet
watchdog (kill a builder whose log stopped growing after a commit) is for streaming builders (opencode: nv, oc); it must never
cut a working agy run. agy keeps only the idle rule (no commit for IDLE_MIN)."""
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from test_build_pipeline import BRIEF, child_env, put, result, sh, toy  # noqa: E402

SILENT_AFTER_COMMIT = r"""#!/bin/bash
# a builder that commits, then works silently for 9 s (no log output) and finishes
. "$LIBSH"
name="$1"; root="$(git rev-parse --show-toplevel)"; wt="$(wt_dir)/$name"
ensure_wt "$root" "$wt" "gemini/$name" "$3" || exit 1; cd "$wt"
mkdir -p features; echo "## a" > features/a.gd; git add -A; git -c user.name=t -c user.email=t@t commit -qm feat
sleep 9
"""


def launch(builder):
    top, g = toy()
    put(top + "/silent.sh", SILENT_AFTER_COMMIT)
    put(top + "/brief.md", BRIEF)
    env = {**os.environ, "BUILDER_CMD": top + "/silent.sh", "FREE_MB": "99999", "NEWTEST_KINDS": "py",
           "LIBSH": HERE + "/lib.sh", "QUIET_SEC": "3", "WATCH_POLL": "1", "IDLE_SEC": "300", **child_env()}
    env.pop("GAME_WT_DIR", None)
    r = sh(g, "bash", HERE + "/build_pipeline.sh", builder, "job", top + "/brief.md", "main", env=env, check=False)
    return r.returncode, result(top)


def test_an_agy_run_with_a_silent_log_is_never_quiet_killed():
    rc, res = launch("agy")
    assert not re.search(r"^quiet: ", res, re.M), res
    assert res.startswith("PASS"), (rc, res)


def test_a_streaming_builder_that_goes_silent_after_a_commit_still_is():
    rc, res = launch("nv")
    assert re.search(r"^quiet: ", res, re.M), res


if __name__ == "__main__":
    from tool_tests import run_cases
    run_cases([v for k, v in sorted(globals().items()) if k.startswith("test_")], "test_agy_quiet", serial=())
