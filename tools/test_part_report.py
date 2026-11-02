#!/usr/bin/env python3
"""Row 26 S10 (Feras 11-02, no context pollution): the head reads ONE short report per part instead of a log or a diff.
tools/part_report.py <task> prints at most 15 lines of at most 160 characters from the run's .result, docs/runs.csv and the
cross-review file. It never prints a log, a diff or a test body."""
import os
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
REPORT = os.path.join(HERE, "part_report.py")
RUNS = ("date,task,worker,effort,gate,fix_passes,minutes,cost,real_findings,tokens_in,tokens_out,usd_est,cost_source,"
        "idle_min\n2026-11-02,job,cf,max,PASS,1,22,0,0,15000,3000,0.0081,opencode-export,4\n")
PASS = ("PASS 07:50 oc/job\nbuilder cf\npid 12\nkind py\nmodel cloudflare-workers-ai/deepseek-v4.1-flash-high\nidle_min 4\n"
        "quiet: build killed after 300s without log output; its commits were checked\nchecked 4e0abbcd17502ef3c7ff21cbb7c11462b7495796\n"
        "ok   new test fails on base: tools/test_x.py\nWARN fix pass edited tests: tools/test_y.py\nVERDICT PASS\n"
        "--- commits\n2ce7a3e docs: regenerate MAP\n07b7ce9 tools: add x\n--- diffstat\n docs/MAP.md | 1 +\n"
        " tools/x.py | 90 ++++\n 2 files changed, 91 insertions(+)\n")
XR = "BEGIN FINDINGS\nhigh | tools/x.py:3 | empty name crashes | refuse it\nmed | tools/x.py:9 | no test | add one\nEND FINDINGS\n"


def setup(d, result=PASS, runs=RUNS, xr=XR):
    wt = os.path.join(d, "game-wt")
    os.makedirs(wt)
    os.makedirs(os.path.join(d, ".check", "reviews"))
    for rel, text in (("game-wt/job.result", result), ("runs.csv", runs), (".check/reviews/job-cross.md", xr)):
        if text is not None:
            with open(os.path.join(d, rel), "w", encoding="utf-8", newline="\n") as f:
                f.write(text)
    return wt


def report(d, task="job"):
    r = subprocess.run([sys.executable, REPORT, task, "--wt-dir", os.path.join(d, "game-wt"), "--runs-csv",
                        os.path.join(d, "runs.csv"), "--reviews-dir", os.path.join(d, ".check", "reviews")],
                       capture_output=True, text=True, timeout=60)
    assert r.returncode == 0, (r.stdout, r.stderr)
    lines = r.stdout.splitlines()
    assert 1 <= len(lines) <= 15 and all(len(ln) <= 160 for ln in lines), lines
    return r.stdout, lines


def test_a_pass_report_has_the_word_model_cost_flags_and_the_next_step():
    with tempfile.TemporaryDirectory() as d:
        setup(d)
        out, lines = report(d)
        assert lines[0].startswith("PASS job") and "deepseek-v4.1-flash-high" in lines[0], lines[0]
        assert "4e0abbc" in out and "2 files" in out and "2 commits" in out, out
        assert "15000" in out and "3000" in out and "0.0081" in out and "opencode-export" in out, out
        assert "idle_min 4" in out and "quiet:" in out, out
        assert "WARN fix pass edited tests" in out, out
        assert "empty name crashes" in out and "2 flag" in out, out
        assert "merge_run.sh job" in out, out


def test_the_report_never_prints_a_log_a_diff_or_a_test_body():
    with tempfile.TemporaryDirectory() as d:
        huge = PASS + "".join(f"WARN lens {i}: " + "x" * 400 + "\n" for i in range(60))
        setup(d, result=huge)
        with open(os.path.join(d, "game-wt", "job.log"), "w", encoding="utf-8") as f:
            f.write("SECRET-LOG-LINE\n" * 5000)
        out, lines = report(d)
        assert "SECRET-LOG-LINE" not in out and len(lines) <= 15


def test_non_pass_words_say_why_and_never_suggest_a_merge():
    cases = {"BREACH": "BREACH tools/test_a.py (the brief's Do NOT edit list)", "NOWORK": "why: opencode exited 126",
             "ERROR": "gate error: FileNotFoundError brief", "FAIL": "FAIL tool_tests (126 s)"}
    for word, detail in cases.items():
        with tempfile.TemporaryDirectory() as d:
            setup(d, result=f"{word} 08:00 oc/job\nbuilder cf\nkind py\nidle_min 0\n{detail}\n--- commits\n--- diffstat\n")
            out, lines = report(d)
            assert lines[0].startswith(f"{word} job") and detail in out, (word, out)
            assert "merge_run.sh" not in out, (word, out)


def test_missing_pieces_read_question_marks_not_zero():
    with tempfile.TemporaryDirectory() as d:
        setup(d, runs=None, xr=None)
        out, lines = report(d)
        assert "cost ?" in out and "flags ?" in out, out
    with tempfile.TemporaryDirectory() as d:
        os.makedirs(os.path.join(d, "game-wt"))
        out, lines = report(d)
        assert lines[0].startswith("NO RESULT job"), lines


if __name__ == "__main__":
    from tool_tests import run_cases
    run_cases([v for k, v in sorted(globals().items()) if k.startswith("test_")], "test_part_report")
