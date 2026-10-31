#!/usr/bin/env python3
"""Self-test for tools/slots.sh: python tools/test_slots.py (temp dirs, plain asserts, exit 1 on failure)."""
import datetime
import os
import subprocess
import sys
import tempfile
import time

SCRIPT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "slots.sh")


def run_slots(wt_dir, *args, cwd=None, **env_extra):
    env = {**os.environ, "CAP_AGY": "2", "CAP_CF": "2", "CAP_OC": "1", "FREE_MB": "99999", **env_extra}
    if wt_dir:
        env["GAME_WT_DIR"] = wt_dir
    else:
        env.pop("GAME_WT_DIR", None)
    return subprocess.run(["bash", SCRIPT, *args], env=env, capture_output=True, text=True, cwd=cwd)


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
    assert "cf spend this month: $0.27 (+ 1 runs with no token count)" in r.stdout, r.stdout


def test_spend_counts_the_token_lines_of_cf_mcp_and_cf_probe():  # their 5th column is the model: slots read $0 (row 18c)
    d = tempfile.mkdtemp()
    month = datetime.date.today().strftime("%Y-%m")
    write(d, "cf_spend.csv", "date,task,input_tokens,output_tokens,usd\n"
          f"{month}-01,t1,100000,50000,0.09\n"
          f"{month}-02,cf_probe,1000000,1000000,@cf/zai-org/glm-5.3-flash\n")
    r = run_slots(d, CF_INPUT_RATE="0.30", CF_OUTPUT_RATE="1.20")
    assert "cf spend this month: $1.59\n" in r.stdout.replace("\r", ""), r.stdout


def running(d, name, builder, extra=""):
    write(d, name + ".result", f"RUNNING 10:00 build\nbuilder {builder}\n{extra}")
    write(d, name + ".log", "log")


def test_slots_find_game_wt_from_a_worktree():  # slots counted 0 runs from any worktree (audit 2026-10-27)
    top = tempfile.mkdtemp()
    repo = os.path.join(top, "game")
    os.makedirs(repo)
    git = ["git", "-C", repo, "-c", "user.name=t", "-c", "user.email=t@t"]
    subprocess.run([*git, "init", "-q", "-b", "main"], check=True)
    subprocess.run([*git, "commit", "-q", "--allow-empty", "-m", "x"], check=True)
    wt = os.path.join(repo, ".claude", "worktrees", "w")
    subprocess.run([*git, "worktree", "add", "-q", "-b", "w", wt], check=True)
    running(os.path.join(top, "game-wt"), "job", "cf")
    r = run_slots(None, cwd=wt)
    assert "cf job build since 10:00" in r.stdout and "cf 1/2" in r.stdout, r.stdout + r.stderr


def test_total_godot_cap_refuses_a_third_run():  # D1: agy + cf together <= 2; the oc run does not count
    d = tempfile.mkdtemp()
    running(d, "a", "agy")
    assert run_slots(d, "can-start", "cf").returncode == 0, "agy 1 + cf 0 leaves room"
    running(d, "b", "cf")
    r = run_slots(d, "can-start", "agy")
    assert r.returncode == 1 and "godot 2/2" in r.stdout, r.stdout
    assert run_slots(d, "can-start", "oc").returncode == 0, "the free text run has its own slot"
    running(d, "c", "oc")
    assert run_slots(d, "can-start", "oc").returncode == 1, "one text run only"


def test_memory_floor_refuses_a_start():  # FREE_MB stubs the Win32_OperatingSystem read
    d = tempfile.mkdtemp()
    r = run_slots(d, "can-start", "cf", FREE_MB="500", MIN_FREE_MB="3000")
    assert r.returncode == 1 and "memory" in r.stdout.lower(), r.stdout
    assert run_slots(d, "can-start", "cf", FREE_MB="5000", MIN_FREE_MB="3000").returncode == 0


def test_real_memory_read_is_a_number():  # the PowerShell CIM read itself, on this PC (stub off)
    out = subprocess.run(["bash", "-c", f". '{os.path.dirname(SCRIPT)}/lib.sh'; free_mb"], capture_output=True,
                         text=True, env={k: v for k, v in os.environ.items() if k != "FREE_MB"}).stdout.strip()
    assert out.isdigit() and int(out) > 0, out


def test_dead_pid_run_is_not_counted():  # a killed pipeline left RUNNING behind
    d = tempfile.mkdtemp()
    running(d, "dead", "cf", "pid 999999\n")
    r = run_slots(d)
    assert "DEAD" in r.stdout and "cf 0/2" in r.stdout, r.stdout


def test_spend_reads_the_saved_build_log_too():  # the fix pass overwrote <task>.log; the build's tokens were lost
    d = tempfile.mkdtemp()
    csv_path = os.path.join(d, "cf_spend.csv")
    write(d, "t.build.log", "Input tokens: 1,000\nOutput tokens: 2,000\n")
    write(d, "t.log", "Input tokens: 500\nOutput tokens: 500\n")
    run_slots(d, "append-spend", os.path.join(d, "t.log"), "t", "1.0", "1.0", csv_path)
    assert open(csv_path).read().splitlines()[1].split(",")[2:4] == ["1500", "2500"], open(csv_path).read()


def test_cf_mcp_triage_uses_deepseek():
    src = open(os.path.join(os.path.dirname(SCRIPT), "cf_mcp", "server.py"), encoding="utf-8").read()
    assert '"triage_trace": "@cf/deepseek' in src, "triage_trace must use DeepSeek (D1)"


if __name__ == "__main__":
    tests = [v for k, v in sorted(globals().items()) if k.startswith("test_")]
    for t in tests:
        t()
    print(f"test_slots: {len(tests)} tests passed")
