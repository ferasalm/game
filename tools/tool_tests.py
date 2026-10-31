#!/usr/bin/env python3
"""Runs tool tests in parallel worker threads with logs in .check."""
import concurrent.futures
import os
import subprocess
import sys
import time
import traceback


def workers() -> int:
    val = os.environ.get("TEST_WORKERS")
    return int(val) if val else min(4, os.cpu_count() or 1)


def run_cases(tests, label, jobs=None):
    failures = []

    def _run(t):
        try:
            t()
            return None
        except Exception:
            return (t.__name__, traceback.format_exc())

    with concurrent.futures.ThreadPoolExecutor(max_workers=jobs or workers()) as ex:
        results = list(ex.map(_run, tests))

    failures = [r for r in results if r is not None]
    if failures:
        for name, tb in failures:
            print(f"FAIL {name}\n{tb}".rstrip())
        sys.exit(1)
    print(f"{label}: {len(tests)} tests passed")


def find_tests(root="tools"):
    found = []
    for cur, _, files in os.walk(root):
        for f in files:
            if f.startswith("test_") and f.endswith(".py"):
                found.append(os.path.join(cur, f).replace("\\", "/"))
    return sorted(found)


def run_files(paths, log_dir, serial=(), jobs=None):
    os.makedirs(log_dir, exist_ok=True)
    serial_set = {s.replace("\\", "/") for s in serial}

    def _run_one(path):
        t0 = time.time()
        norm = path.replace("\\", "/")
        log_name = f"{log_dir}/tool_{norm.replace('/', '_')}.log"
        with open(log_name, "wb") as f:
            p = subprocess.run([sys.executable, path], stdin=subprocess.DEVNULL, stdout=f, stderr=subprocess.STDOUT)
        return (path, p.returncode, round(time.time() - t0, 1))

    parallel = [p for p in paths if p.replace("\\", "/") not in serial_set]
    serials = [p for p in paths if p.replace("\\", "/") in serial_set]

    with concurrent.futures.ThreadPoolExecutor(max_workers=jobs or workers()) as ex:
        parallel_results = list(ex.map(_run_one, parallel))

    serial_results = [_run_one(p) for p in serials]

    res_map = {path: (rc, sec) for path, rc, sec in parallel_results + serial_results}
    return [(p, res_map[p][0], res_map[p][1]) for p in paths]


def main():
    SERIAL = ("tools/test_build_pipeline.py", "tools/test_py_runs.py")
    tests = find_tests()
    results = run_files(tests, ".check", serial=SERIAL)
    bad = []
    for path, rc, sec in results:
        if rc != 0:
            bad.append(path)
            print(f"--- {path}")
            norm = path.replace("\\", "/")
            log_file = f".check/tool_{norm.replace('/', '_')}.log"
            try:
                with open(log_file, encoding="utf-8", errors="replace") as f:
                    lines = f.readlines()
                for line in lines[-8:]:
                    sys.stdout.write(line)
                if lines and not lines[-1].endswith("\n"):
                    sys.stdout.write("\n")
            except Exception:
                pass
    for path in bad:
        print(f"FAIL tool test: {path}")
    slowest = sorted(results, key=lambda x: x[2], reverse=True)[:3]
    for path, rc, sec in slowest:
        print(f"slowest: {round(sec)} s {path}")
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
