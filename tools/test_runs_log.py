#!/usr/bin/env python3
"""Row 26 S2 (Feras 11-02): docs/runs.csv is the pipeline's scoreboard. Cost columns are real or `?` (unknown is not
zero), a run that ended NOWORK/REFUSED/ERROR gets its row too, and an old 9-column file is migrated, not corrupted."""
import csv
import os
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
RUNS_LOG = os.path.join(HERE, "runs_log.py")
OLD_HEADER = "date,task,worker,effort,gate,fix_passes,minutes,cost,real_findings"
NEW_COLS = ["tokens_in", "tokens_out", "usd_est", "cost_source", "idle_min"]


def append(path, *extra, task="t1", gate="PASS"):
    cmd = [sys.executable, RUNS_LOG, "append", "--task", task, "--worker", "cf", "--effort", "max", "--gate", gate,
           "--fix-passes", "1", "--minutes", "9", "--cost", "0", "--findings", "0", "--file", path, "--date", "2026-11-02"]
    return subprocess.run(cmd + list(extra), capture_output=True, text=True, timeout=60)


def rows(path):
    with open(path, encoding="utf-8", newline="") as f:
        return list(csv.DictReader(f))


def test_new_columns_carry_tokens_usd_source_and_idle_minutes():
    with tempfile.TemporaryDirectory() as d:
        p = os.path.join(d, "runs.csv")
        r = append(p, "--tokens-in", "1300", "--tokens-out", "240", "--usd", "0.00", "--source", "opencode-export",
                   "--idle-min", "4")
        assert r.returncode == 0, r.stderr
        row = rows(p)[0]
        assert row["tokens_in"] == "1300" and row["tokens_out"] == "240" and row["usd_est"] == "0.00", row
        assert row["cost_source"] == "opencode-export" and row["idle_min"] == "4", row


def test_a_run_with_no_meter_reading_logs_question_marks_not_zero():
    with tempfile.TemporaryDirectory() as d:
        p = os.path.join(d, "runs.csv")
        assert append(p).returncode == 0
        row = rows(p)[0]
        for col in ("tokens_in", "tokens_out", "usd_est"):
            assert row[col] == "?", (col, row)
        assert row["cost_source"] == "unknown" and row["idle_min"] == "?", row


def test_an_old_nine_column_file_is_migrated_and_old_rows_read_unknown():
    with tempfile.TemporaryDirectory() as d:
        p = os.path.join(d, "runs.csv")
        with open(p, "w", encoding="utf-8", newline="\n") as f:
            f.write(OLD_HEADER + "\n2026-11-01,old,cf,none,FAIL,3,33,0,1\n")
        assert append(p, task="new").returncode == 0
        got = rows(p)
        assert [r["task"] for r in got] == ["old", "new"], got
        assert got[0]["usd_est"] == "?" and got[0]["cost_source"] == "unknown", got[0]  # the old 0 was never measured
        assert list(got[0].keys())[-5:] == NEW_COLS, list(got[0].keys())


def test_every_result_word_can_be_logged():
    with tempfile.TemporaryDirectory() as d:
        p = os.path.join(d, "runs.csv")
        for word in ("PASS", "FAIL", "NOWORK", "BREACH", "ERROR", "REFUSED"):
            assert append(p, task="t-" + word.lower(), gate=word).returncode == 0
        assert [r["gate"] for r in rows(p)] == ["PASS", "FAIL", "NOWORK", "BREACH", "ERROR", "REFUSED"]


if __name__ == "__main__":
    from tool_tests import run_cases
    run_cases([v for k, v in sorted(globals().items()) if k.startswith("test_")], "test_runs_log")
