#!/usr/bin/env python3
"""Self-test for tools/slots.sh: python tools/test_slots.py (temp dirs, plain asserts, exit 1 on failure)."""
import datetime
import os
import subprocess
import sys
import tempfile
import time

SCRIPT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "slots.sh")


def run_slots(wt_dir, *args):
    env = dict(os.environ, GAME_WT_DIR=wt_dir)
    return subprocess.run(["bash", SCRIPT, *args], env=env, capture_output=True, text=True)


def write(d, name, text, mtime=None):
    p = os.path.join(d, name)
    os.makedirs(os.path.dirname(p), exist_ok=True)
    with open(p, "w", encoding="utf-8", newline="\n") as f:
        f.write(text)
    if mtime is not None:
        os.utime(p, (mtime, mtime))
    return p


def test_slots_counts_per_builder():
    d = tempfile.mkdtemp()
    write(d, "task1.result", "RUNNING 10:00 build\nbuilder agy\n")
    write(d, "task1.log", "log1")
    write(d, "task2.result", "RUNNING 10:05 fix pass\nbuilder cf\n")
    write(d, "task2.log", "log2")
    write(d, "task3.result", "RUNNING 10:10 build\nbuilder oc\n")
    write(d, "task3.log", "log3")
    write(d, "task4.result", "PASS 09:00 oc/task4\nbuilder oc\n")
    r = run_slots(d)
    assert r.returncode == 0, r.stderr
    out = r.stdout
    assert "agy task1 build since 10:00" in out, out
    assert "cf task2 fix pass since 10:05" in out, out
    assert "oc task3 build since 10:10" in out, out
    assert "task4" not in out, out
    assert "agy 1/2  cf 1/2  oc 1/1" in out, out


def test_slots_flags_stale():
    d = tempfile.mkdtemp()
    now = time.time()
    write(d, "task1.result", "RUNNING 10:00 build\nbuilder agy\n")
    write(d, "task1.log", "old log", mtime=now - 7500)
    write(d, "task2.result", "RUNNING 10:30 build\nbuilder agy\n")
    write(d, "task2.log", "fresh log", mtime=now)
    r = run_slots(d)
    assert r.returncode == 0, r.stderr
    out = r.stdout
    assert "agy task1 build since 10:00 STALE?" in out, out
    assert "agy task2 build since 10:30" in out and "task2 build since 10:30 STALE?" not in out, out
    assert "agy 1/2  cf 0/2  oc 0/1" in out, out


def test_slots_exits_1_over_cap():
    d = tempfile.mkdtemp()
    write(d, "task1.result", "RUNNING 10:00 build\nbuilder agy\n")
    write(d, "task1.log", "log1")
    write(d, "task2.result", "RUNNING 10:01 build\nbuilder agy\n")
    write(d, "task2.log", "log2")
    write(d, "task3.result", "RUNNING 10:02 build\nbuilder agy\n")
    write(d, "task3.log", "log3")
    r = run_slots(d)
    assert r.returncode == 1, f"Expected returncode 1, got {r.returncode}:\n{r.stdout}\n{r.stderr}"
    assert "agy 3/2  cf 0/2  oc 0/1" in r.stdout, r.stdout


def test_spend_line_parses_sample_log_and_absent():
    d = tempfile.mkdtemp()
    today = datetime.date.today().isoformat()
    csv_path = os.path.join(d, "cf_spend.csv")
    log_sample = write(d, "sample.log", "Finished task\nInput tokens: 100,000\nOutput tokens: 50,000\n")
    r1 = run_slots(d, "append-spend", log_sample, "task_with_usage", "0.30", "1.20", csv_path)
    assert r1.returncode == 0, r1.stderr
    log_empty = write(d, "empty.log", "Completed without tokens printed.\n")
    r2 = run_slots(d, "append-spend", log_empty, "task_no_usage", "0.30", "1.20", csv_path)
    assert r2.returncode == 0, r2.stderr
    lines = open(csv_path, encoding="utf-8").read().splitlines()
    assert lines[0] == "date,task,input_tokens,output_tokens,usd", lines[0]
    assert lines[1] == f"{today},task_with_usage,100000,50000,0.09", lines[1]
    assert lines[2] == f"{today},task_no_usage,,,?", lines[2]


def test_slots_prints_monthly_spend():
    d = tempfile.mkdtemp()
    today = datetime.date.today().isoformat()
    month = datetime.date.today().strftime("%Y-%m")
    csv_text = (
        "date,task,input_tokens,output_tokens,usd\n"
        f"{month}-01,t1,100000,50000,0.09\n"
        f"{month}-02,t2,200000,100000,0.18\n"
        "2020-01-01,old,100000,50000,0.09\n"
        f"{month}-03,t3,,,?\n"
    )
    write(d, "cf_spend.csv", csv_text)
    r = run_slots(d)
    assert r.returncode == 0, r.stderr
    assert "cf spend this month: $0.27" in r.stdout, r.stdout


if __name__ == "__main__":
    tests = [v for k, v in sorted(globals().items()) if k.startswith("test_")]
    for t in tests:
        t()
    print(f"test_slots: {len(tests)} tests passed")
