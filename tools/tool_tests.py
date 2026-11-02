#!/usr/bin/env python3
"""Runs tool tests in parallel worker threads with logs in .check; the 2 slow toy tests skip while tools/ is unchanged."""
import concurrent.futures
import hashlib
import os
import subprocess
import sys
import time
import traceback

SERIAL = ("tools/test_build_pipeline.py", "tools/test_py_runs.py", "tools/test_run_state.py")  # each runs whole pipelines with wall-clock bounds (alone, so load cannot flake them); the skippable ones; base_red leaves them out


def workers() -> int:
    val = os.environ.get("TEST_WORKERS")
    return int(val) if val else min(4, os.cpu_count() or 1)


def run_cases(tests, label, jobs=None, serial=()):
    """Names in serial run alone after the pool: a time limit flakes under load, and a limit is never loosened (10-31)."""

    def _run(t):
        try:
            t()
            return None
        except BaseException:  # a test's sys.exit(0) must not read as a pass
            return (t.__name__, traceback.format_exc())

    with concurrent.futures.ThreadPoolExecutor(max_workers=jobs or workers()) as ex:
        results = list(ex.map(_run, [t for t in tests if t.__name__ not in serial]))
    results += [_run(t) for t in tests if t.__name__ in serial]

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


def fingerprint() -> str:
    """tools/ as it stands: committed, uncommitted and new files alike, git-ignored ones left out."""
    names = subprocess.run(["git", "ls-files", "-z", "--cached", "--others", "--exclude-standard", "--", "tools"],
                           capture_output=True, check=True).stdout
    h = hashlib.sha256()
    for name in sorted(set(names.split(b"\0")) - {b""}):
        h.update(name + b"\0")
        try:
            with open(name, "rb") as f:
                h.update(f.read().replace(b"\r\n", b"\n"))  # the same file reads CRLF in one checkout, LF in another
        except OSError:  # a deleted file changes the hash too
            h.update(b"gone\0")
    return h.hexdigest()[:32]


def pass_dir() -> str:
    """Shared by every worktree: lib.sh wt_dir, <main checkout's parent>/game-wt."""
    wt = os.environ.get("GAME_WT_DIR")
    if not wt:
        common = subprocess.run(["git", "rev-parse", "--path-format=absolute", "--git-common-dir"],
                                capture_output=True, text=True, check=True).stdout.strip()
        wt = os.path.dirname(os.path.dirname(common)) + "/game-wt"
    return wt + "/tool_tests_passed"


def stamp(key: str, path: str) -> str:
    return f"{pass_dir()}/{key}-{os.path.basename(path)}"


def main():
    tests = find_tests()
    if not tests:
        print("FAIL tool test: no tools/**/test_*.py found (run from the repo root)")
        return 1
    key = None if os.environ.get("CI") else fingerprint()  # CI never skips and never stores
    cached = [p for p in SERIAL if key and os.path.exists(stamp(key, p))]
    results = run_files([t for t in tests if t not in cached], ".check", serial=SERIAL)
    for path, rc, sec in results:
        if key and rc == 0 and path in SERIAL:
            os.makedirs(pass_dir(), exist_ok=True)
            open(stamp(key, path), "w").close()
    for path in cached:
        print(f"cached: {path} (tools/ unchanged since it passed)")
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
