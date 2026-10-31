#!/usr/bin/env python3
"""Tests tool_tests.py parallel test execution and process runner."""
from contextlib import redirect_stdout
import io
import os
import shutil
import subprocess
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


def test_run_cases_serial_names_run_alone_after_the_pool():
    log = []

    def stamp(name):
        log.append(name + " start")
        time.sleep(0.2)
        log.append(name + " end")

    def t1():
        stamp("t1")

    def t2():
        stamp("t2")

    def timed():
        stamp("timed")

    with redirect_stdout(io.StringIO()):
        run_cases([timed, t1, t2], "demo", jobs=2, serial=("timed",))
    assert log[-2:] == ["timed start", "timed end"], log


def test_a_test_that_calls_sys_exit_fails():  # DeepSeek's find on check-parallel (10-31): exit 0 read as a pass
    def bad():
        sys.exit(0)

    buf = io.StringIO()
    code = None
    with redirect_stdout(buf):
        try:
            run_cases([bad], "demo")
        except SystemExit as e:
            code = e.code
    assert code == 1 and "FAIL bad" in buf.getvalue(), (code, buf.getvalue())


def test_workers_reads_test_workers():
    old = os.environ.pop("TEST_WORKERS", None)
    try:
        assert workers() == min(4, os.cpu_count() or 1)
        os.environ["TEST_WORKERS"] = "6"
        assert workers() == 6
    finally:
        if old is not None:
            os.environ["TEST_WORKERS"] = old
        else:
            os.environ.pop("TEST_WORKERS", None)


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
        # P2 runs long, so a run_files that ignored serial would start SER (it gets P1's free worker) before P2 ends
        for path, name, nap in ((p_par1, "P1", 0.2), (p_par2, "P2", 1.0), (p_ser, "SER", 0.2)):
            with open(path, "w", encoding="utf-8") as f:
                f.write(
                    f"import time\n"
                    f"with open('{stamps}', 'a') as f: f.write('{name} START {{}}\\n'.format(time.time()))\n"
                    f"time.sleep({nap})\n"
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


REAL = os.path.join(os.path.dirname(os.path.abspath(__file__)), "tool_tests.py")
SLOW = 'import os, sys\nopen("../runs", "a").write("{name}\\n")\nsys.exit(1 if os.path.exists("../fail.flag") else 0)\n'


def put(path, text):
    with open(path, "w", encoding="utf-8", newline="\n") as f:
        f.write(text)


def skip_repo():
    """<top>/repo with the 2 slow names as fast stubs that count their runs in <top>/repo/../runs; shared dir: <top>/game-wt."""
    top = tempfile.mkdtemp().replace("\\", "/")
    repo = top + "/repo"
    os.makedirs(repo + "/tools")
    os.makedirs(repo + "/docs")
    put(repo + "/.gitignore", ".check/\n__pycache__/\n")
    put(repo + "/docs/d.md", "d\n")
    put(repo + "/tools/helper.py", "x = 1\n")
    for name in ("test_build_pipeline", "test_py_runs"):
        put(f"{repo}/tools/{name}.py", SLOW.format(name=name))
    git(repo, "init", "-q")
    commit(repo)
    return top, repo


def git(repo, *args):
    subprocess.run(["git", "-c", "user.name=t", "-c", "user.email=t@t", *args], cwd=repo, check=True, capture_output=True)


def commit(repo):
    git(repo, "add", "-A")
    git(repo, "commit", "-qm", "x")


def run_main(repo, **extra):
    env = {k: v for k, v in os.environ.items() if k not in ("CI", "GAME_WT_DIR")}
    return subprocess.run([sys.executable, REAL], cwd=repo, env={**env, **extra}, capture_output=True, text=True,
                          stdin=subprocess.DEVNULL)


def runs(top):
    path = top + "/runs"
    return len(open(path, encoding="utf-8").readlines()) if os.path.exists(path) else 0


def test_a_passed_slow_test_is_skipped_and_said():
    top, repo = skip_repo()
    try:
        r = run_main(repo)
        assert r.returncode == 0 and runs(top) == 2 and "cached:" not in r.stdout, (r.stdout, r.stderr, runs(top))
        r = run_main(repo)
        assert r.returncode == 0 and runs(top) == 2, ("both must skip", runs(top), r.stdout)
        assert "cached: tools/test_build_pipeline.py" in r.stdout and "cached: tools/test_py_runs.py" in r.stdout, r.stdout
        put(repo + "/docs/d.md", "changed outside tools/\n")
        run_main(repo)
        assert runs(top) == 2, "a change outside tools/ keeps the skip"
        os.remove(repo + "/docs/d.md")
        git(repo, "checkout", "--", "docs/d.md")
        wt = top + "/wt"
        git(repo, "worktree", "add", "-q", wt)
        r = run_main(wt)
        assert runs(top) == 2 and "cached:" in r.stdout, ("a pass is shared with every worktree", r.stdout, r.stderr)
    finally:
        shutil.rmtree(top, ignore_errors=True)


def test_a_changed_tool_reruns_the_slow_tests():  # the one bad case: a skip here would pass broken tools
    top, repo = skip_repo()
    try:
        run_main(repo)
        expected = 2
        put(repo + "/tools/helper.py", "x = 2\n")  # uncommitted
        run_main(repo)
        expected += 2
        assert runs(top) == expected, ("an uncommitted tools/ change must rerun", runs(top))
        put(repo + "/tools/new_tool.py", "y = 1\n")  # new, not added
        run_main(repo)
        expected += 2
        assert runs(top) == expected, ("a new tools/ file must rerun", runs(top))
        commit(repo)
        run_main(repo)
        assert runs(top) == expected, ("committing the same files changes nothing", runs(top))
        put(repo + "/tools/helper.py", "x = 3\n")
        commit(repo)
        run_main(repo)
        expected += 2
        assert runs(top) == expected, ("a committed tools/ change must rerun", runs(top))
    finally:
        shutil.rmtree(top, ignore_errors=True)


def test_a_failed_slow_test_is_never_stored():
    top, repo = skip_repo()
    try:
        put(top + "/fail.flag", "x")
        assert run_main(repo).returncode == 1
        assert run_main(repo).returncode == 1
        assert runs(top) == 4, runs(top)
        os.remove(top + "/fail.flag")
        run_main(repo)
        assert runs(top) == 6, ("no stale pass from the failing runs", runs(top))
    finally:
        shutil.rmtree(top, ignore_errors=True)


def test_ci_never_skips_or_stores():
    top, repo = skip_repo()
    try:
        run_main(repo, CI="true")
        r = run_main(repo, CI="true")
        assert runs(top) == 4 and "cached:" not in r.stdout, (runs(top), r.stdout)
        assert not os.path.exists(top + "/game-wt"), "CI stores no pass"
        run_main(repo)
        r = run_main(repo, CI="true")
        assert runs(top) == 8 and "cached:" not in r.stdout, "CI ignores a stored pass"
    finally:
        shutil.rmtree(top, ignore_errors=True)


if __name__ == "__main__":
    tests = [v for k, v in sorted(globals().items()) if k.startswith("test_")]
    for t in tests:
        t()
    print(f"test_tool_tests: {len(tests)} tests passed")
