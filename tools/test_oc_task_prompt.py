#!/usr/bin/env python3
"""Row 26 (11-02): GLM's scope run died at once with "Argument list too long" (exit 126): oc_task.sh passed the whole prompt
(brief + skill + Pattern file + code rules, over 32 KB) as a command-line argument, and Windows caps a command at ~32 KB.
The prompt now travels as an attached file (-f), whatever its size."""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from test_build_pipeline import BRIEF, child_env, put, task, toy  # noqa: E402


def test_a_prompt_far_over_the_command_line_cap_reaches_opencode_as_a_file():
    top, g = toy()
    put(top + "/brief.md", BRIEF + "\n" + ("padding line that makes the prompt huge\n" * 2500))  # ~100 KB
    assert os.path.getsize(top + "/brief.md") > 90000
    task(g, top, "oc_task.sh", "job", "origin/main", OC_TIMEOUT="2s", **child_env())
    log = open(top + "/game-wt/job.log", encoding="utf-8").read()
    assert "Argument list too long" not in log and "exited 126" not in log, log
    assert " -f " in log and "brief.md" in log, ("the prompt must be attached as a file", log)
    assert "padding line that makes the prompt huge" not in log, "the brief text must not travel as an argument"


if __name__ == "__main__":
    from tool_tests import run_cases
    run_cases([v for k, v in sorted(globals().items()) if k.startswith("test_")], "test_oc_task_prompt")
