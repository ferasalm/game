#!/usr/bin/env python3
"""Self-test for row 23 c (2026-11-01): session_stats.py --row <session id> prints a USAGE row; tools/runs_log.py appends
to docs/runs.csv; build_pipeline.sh calls the logger; .gitattributes merges runs.csv with union."""
import csv
import json
import os
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__))).replace("\\", "/")
STATS = ROOT + "/tools/session_stats.py"
RUNS = ROOT + "/tools/runs_log.py"


def py(*args):
    return subprocess.run([sys.executable, *args], capture_output=True, text=True, encoding="utf-8")


def transcript(session="abc-123"):
    d = tempfile.mkdtemp().replace("\\", "/")
    os.makedirs(d + "/C--dev-game-wt1")
    events = [
        {"type": "user", "timestamp": "2026-11-01T09:00:00.000Z", "message": {"role": "user", "content": "hi"}},
        {"type": "assistant", "timestamp": "2026-11-01T09:00:05.000Z", "message": {"model": "claude-sonnet-5-5", "usage": {
            "input_tokens": 10, "cache_read_input_tokens": 1000, "cache_creation_input_tokens": 500, "output_tokens": 5},
            "content": [{"type": "tool_use", "name": "Bash"}, {"type": "tool_use", "name": "Read"}]}},
        {"type": "user", "message": {"role": "user", "content": [{"type": "tool_result", "is_error": True, "content": "boom"}]}},
        {"type": "assistant", "timestamp": "2026-11-01T09:10:00.000Z", "message": {"model": "claude-sonnet-5-5", "usage": {
            "input_tokens": 20, "cache_read_input_tokens": 2500, "cache_creation_input_tokens": 100, "output_tokens": 9},
            "content": [{"type": "tool_use", "name": "Edit"}]}},
    ]
    with open(f"{d}/C--dev-game-wt1/{session}.jsonl", "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(json.dumps(e) for e in events) + "\n")
    return d


def test_row_prints_one_usage_row_with_the_measured_cells():
    d = transcript()
    r = py(STATS, "--row", "abc-123", "--dir", d)
    assert r.returncode == 0, r.stderr
    lines = r.stdout.strip().splitlines()
    assert len(lines) == 1, r.stdout
    cells = [c.strip() for c in lines[0].strip().strip("|").split("|")]
    assert len(cells) == 6, cells  # Date | Model | Effort | Task | Window % | Result
    assert cells[0] == "2026-11-01" and cells[1] == "Sonnet 5.5 (`claude-sonnet-5-5`)", cells
    assert "TODO" in cells[3] and "TODO" in cells[5], "Claude fills task, result and Kaizen"
    result = cells[5]
    assert "calls 3" in result and "1 failed" in result, result
    assert "cache reads 3,500" in result, result
    assert "peak context 2" in result and "k" in result, result  # 2620 is the largest single request: "2k"


def test_row_for_an_unknown_session_fails_clearly():
    r = py(STATS, "--row", "no-such-id", "--dir", transcript())
    assert r.returncode != 0 and "no transcript" in (r.stdout + r.stderr).lower()


def test_default_table_still_works():
    r = py(STATS, "--dir", transcript(), "--days", "99999")
    assert r.returncode == 0 and ("chats" in r.stdout or "no transcripts" in r.stdout), r.stdout + r.stderr


def test_runs_log_appends_rows_with_a_header_once():
    path = tempfile.mkdtemp().replace("\\", "/") + "/runs.csv"
    base = [RUNS, "append", "--file", path, "--date", "2026-11-01", "--worker", "agy", "--effort", "medium", "--gate", "PASS",
            "--fix-passes", "1", "--minutes", "12.5", "--cost", "0", "--findings", "2"]
    assert py(*base, "--task", "pm, plugin").returncode == 0
    assert py(*base, "--task", "second").returncode == 0
    rows = list(csv.reader(open(path, encoding="utf-8", newline="")))
    header = ["date", "task", "worker", "effort", "gate", "fix_passes", "minutes", "cost", "real_findings"]
    assert rows[0] == header + ["tokens_in", "tokens_out", "usd_est", "cost_source", "idle_min"], rows[0]
    assert len(rows) == 3 and rows[1] == ["2026-11-01", "pm, plugin", "agy", "medium", "PASS", "1", "12.5", "0", "2",
                                          "?", "?", "?", "unknown", "?"], rows
    assert open(path, encoding="utf-8", newline="").read().count("\r") == 0, "LF only (LESSONS: Python writes CRLF)"


def test_repo_wiring_runs_csv_union_header_and_pipeline_call():
    assert "docs/runs.csv merge=union" in open(ROOT + "/.gitattributes", encoding="utf-8").read()
    first = open(ROOT + "/docs/runs.csv", encoding="utf-8").readline().strip()
    assert first == "date,task,worker,effort,gate,fix_passes,minutes,cost,real_findings", first
    pipe = open(ROOT + "/tools/build_pipeline.sh", encoding="utf-8").read()
    call = [l for l in pipe.splitlines() if "runs_log.py" in l]
    assert call and all("|| true" in l for l in call), "the pipeline logs the run, and a logging error never fails it"


if __name__ == "__main__":
    from tool_tests import run_cases
    run_cases([v for k, v in sorted(globals().items()) if k.startswith("test_")], "test_usage_row")
