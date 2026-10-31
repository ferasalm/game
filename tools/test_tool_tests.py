#!/usr/bin/env python3
"""Tests tool_tests.py parallel test execution and process runner."""
from contextlib import redirect_stdout
import io
import os
import shutil
import sys
import tempfile
import time

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from tool_tests import find_tests, run_cases, run_files, workers


def test_run_cases_runs_every_test_and_exits_1_on_a_failure():
    ran = []

    def test_first():
        ran.append("first")

    def test_failing():
        ran.append("failing")
        assert False, "boom"

    def test_third():
        ran.append("third")

    buf = io.StringIO()
    code = None
    with redirect_stdout(buf):
        try:
            run_cases([test_first, test_failing, test_third], "sample")
        except SystemExit as e:
            code = e.code
    assert code == 1, f"expected exit 1, got {code}"
    assert set(ran) == {"first", "failing", "third"}, f"expected all 3 to run, got {ran}"
    out = buf.getvalue()
    assert "FAIL test_failing" in out, out
    assert "AssertionError: boom" in out, out


def test_run_cases_all_passing():
    def t1():
        pass

    def t2():
        pass

    def t3():
        pass

    buf = io.StringIO()
    with redirect_stdout(buf):
        run_cases([t1, t2, t3], "demo")
    assert buf.getvalue().strip() == "demo: 3 tests passed", buf.getvalue()


def test_run_cases_parallel_timing():
    def s1():
        time.sleep(1.0)

    def s2():
        time.sleep(1.0)

    buf = io.StringIO()
    t0 = time.time()
    with redirect_stdout(buf):
        run_cases([s1, s2], "sleep", jobs=2)
    dt = time.time() - t0
    assert dt < 1.8, f"expected under 1.8 s, took {dt}"


def test_workers_reads_test_workers():
    old = os.environ.get("TEST_WORKERS")
    try:
        os.environ["TEST_WORKERS"] = "6"
        assert workers() == 6
    finally:
        if old is not None:
            os.environ["TEST_WORKERS"] = old
        else:
            os.environ.pop("TEST_WORKERS", None)
    assert workers() == min(4, os.cpu_count() or 1)


def test_find_tests_nested_and_skips_others():
    tmp = tempfile.mkdtemp().replace("\\", "/")
    try:
        os.makedirs(f"{tmp}/sub/nested")
        for name in ("sub/nested/test_deep.py", "sub/test_mid.py", "sub/not_a_test.py", "test_top.py", "other.txt"):
            with open(f"{tmp}/{name}", "w", encoding="utf-8") as f:
                f.write("# dummy\n")
        found = find_tests(tmp)
        expected = sorted([f"{tmp}/sub/nested/test_deep.py", f"{tmp}/sub/test_mid.py", f"{tmp}/test_top.py"])
        assert found == expected, (found, expected)
    finally:
        shutil.rmtree(tmp)


def test_run_files_writes_logs_and_returns_order():
    tmp = tempfile.mkdtemp().replace("\\", "/")
    try:
        log_dir = f"{tmp}/logs"
        p1 = f"{tmp}/test_one.py"
        p2 = f"{tmp}/test_two.py"
        p3 = f"{tmp}/test_three.py"
        with open(p1, "w", encoding="utf-8") as f:
            f.write("import sys; print('one'); sys.exit(0)\n")
        with open(p2, "w", encoding="utf-8") as f:
            f.write("import sys; print('two'); sys.exit(2)\n")
        with open(p3, "w", encoding="utf-8") as f:
            f.write("import sys; print('three'); sys.exit(0)\n")
        paths = [p2, p1, p3]
        results = run_files(paths, log_dir)
        assert [r[0] for r in results] == paths, "input order must be preserved"
        assert [r[1] for r in results] == [2, 0, 0], "return codes must match input order"
        log2 = f"{log_dir}/tool_{p2.replace('/', '_')}.log"
        log1 = f"{log_dir}/tool_{p1.replace('/', '_')}.log"
        log3 = f"{log_dir}/tool_{p3.replace('/', '_')}.log"
        assert os.path.exists(log2) and "two" in open(log2, encoding="utf-8").read()
        assert os.path.exists(log1) and "one" in open(log1, encoding="utf-8").read()
        assert os.path.exists(log3) and "three" in open(log3, encoding="utf-8").read()
    finally:
        shutil.rmtree(tmp)


def test_serial_never_overlaps_side_by_side():
    tmp = tempfile.mkdtemp().replace("\\", "/")
    try:
        log_dir = f"{tmp}/logs"
        stamps = f"{tmp}/stamps.txt"
        p_par1 = f"{tmp}/test_p1.py"
        p_par2 = f"{tmp}/test_p2.py"
        p_ser = f"{tmp}/test_ser.py"
        for path, name in ((p_par1, "P1"), (p_par2, "P2"), (p_ser, "SER")):
            with open(path, "w", encoding="utf-8") as f:
                f.write(
                    f"import time\n"
                    f"with open('{stamps}', 'a') as f: f.write('{name} START {{}}\\n'.format(time.time()))\n"
                    f"time.sleep(0.2)\n"
                    f"with open('{stamps}', 'a') as f: f.write('{name} END {{}}\\n'.format(time.time()))\n"
                )
        run_files([p_par1, p_par2, p_ser], log_dir, serial=(p_ser,), jobs=2)
        intervals = {}
        with open(stamps, encoding="utf-8") as f:
            for line in f:
                parts = line.strip().split()
                if len(parts) == 3:
                    name, event, ts = parts[0], parts[1], float(parts[2])
                    intervals.setdefault(name, {})[event] = ts
        assert intervals["SER"]["START"] >= intervals["P1"]["END"], "serial overlapped with parallel P1"
        assert intervals["SER"]["START"] >= intervals["P2"]["END"], "serial overlapped with parallel P2"
    finally:
        shutil.rmtree(tmp)


if __name__ == "__main__":
    tests = [v for k, v in sorted(globals().items()) if k.startswith("test_")]
    for t in tests:
        t()
    print(f"test_tool_tests: {len(tests)} tests passed")
