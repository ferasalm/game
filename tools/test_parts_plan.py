#!/usr/bin/env python3
"""Row 26 S12 (Feras 11-02): one model may run several times at once (three DeepSeek max, two agy, two GLM) to finish
sooner, but the parts must complement each other. tools/parts_plan.py checks the briefs BEFORE launch (disjoint May edit,
no part editing what another part locks or tests, no shared test file) and the finished branches BEFORE merge (a dry-run
merge of each pair with `git merge-tree`, so a conflict is known without touching a checkout)."""
import os
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
PLAN = os.path.join(HERE, "parts_plan.py")


def brief(d, name, may=(), tests=(), dont=()):
    def block(paths):
        return "\n".join(f"`{p}`" for p in paths) or "none"
    text = (f"# Brief: {name}\n\n## Do NOT edit\nD6 defaults.\n{block(dont) if dont else ''}\n\n## May edit\n{block(may)}\n\n"
            f"## Tests\n" + "".join(f"- {t} :: every test\n" for t in tests) + "\n## Checklist\n- file: x\n")
    path = os.path.join(d, name + ".md")
    with open(path, "w", encoding="utf-8", newline="\n") as f:
        f.write(text)
    return path


def plan(*args):
    return subprocess.run([sys.executable, PLAN, *args], capture_output=True, text=True, timeout=60)


def test_disjoint_parts_are_ok_and_the_order_is_the_argument_order():
    with tempfile.TemporaryDirectory() as d:
        a = brief(d, "a", may=["tools/a.py"], tests=["tools/test_a.py"])
        b = brief(d, "b", may=["tools/b.py", "docs/MAP.md"], tests=["tools/test_b.py"])
        c = brief(d, "c", may=["docs/MAP.md", "tools/c.py"], tests=["tools/test_c.py"])  # generated files may be shared
        r = plan(a, b, c)
        assert r.returncode == 0 and r.stdout.startswith("OK 3 parts"), (r.stdout, r.stderr)
        assert "order: a b c" in r.stdout.splitlines(), r.stdout  # brief file stems, in the order given


def test_two_parts_editing_the_same_file_conflict():
    with tempfile.TemporaryDirectory() as d:
        a = brief(d, "a", may=["tools/shared.sh"])
        b = brief(d, "b", may=["tools/shared.sh"])
        r = plan(a, b)
        assert r.returncode == 1 and "tools/shared.sh" in r.stdout and "a" in r.stdout and "b" in r.stdout, r.stdout


def test_a_folder_overlaps_the_files_inside_it():
    with tempfile.TemporaryDirectory() as d:
        a = brief(d, "a", may=["features/combat/"])
        b = brief(d, "b", may=["features/combat/logic/hit.gd"])
        r = plan(a, b)
        assert r.returncode == 1 and "features/combat" in r.stdout, r.stdout


def test_a_part_may_not_edit_what_another_part_locks_or_tests():
    with tempfile.TemporaryDirectory() as d:
        a = brief(d, "a", may=["tools/a.py"], tests=["tools/test_a.py"])
        b = brief(d, "b", may=["tools/test_a.py"])  # edits a's locked test
        c = brief(d, "c", may=["tools/c.py"], dont=["tools/a.py"])  # c forbids what a must edit
        assert plan(a, b).returncode == 1
        r = plan(a, c)
        assert r.returncode == 1 and "tools/a.py" in r.stdout, r.stdout


def test_two_parts_may_not_share_a_test_file():
    with tempfile.TemporaryDirectory() as d:
        a = brief(d, "a", may=["tools/a.py"], tests=["tools/test_x.py"])
        b = brief(d, "b", may=["tools/b.py"], tests=["tools/test_x.py"])
        r = plan(a, b)
        assert r.returncode == 1 and "tools/test_x.py" in r.stdout, r.stdout


def git(cwd, *a):
    subprocess.run(["git", "-C", cwd, *a], check=True, capture_output=True)


def toy_branches():
    g = tempfile.mkdtemp().replace("\\", "/")
    git(g, "init", "-q", "-b", "main")
    git(g, "config", "user.email", "t@t")
    git(g, "config", "user.name", "t")
    with open(g + "/shared.txt", "w", newline="\n") as f:
        f.write("one\ntwo\nthree\n")
    git(g, "add", "-A")
    git(g, "commit", "-qm", "base")
    for name, fname, text in (("p1", "one.txt", "x\n"), ("p2", "two.txt", "y\n"), ("p3", "shared.txt", "ONE\ntwo\nthree\n"),
                              ("p4", "shared.txt", "uno\ntwo\nthree\n")):
        git(g, "checkout", "-q", "-b", name, "main")
        with open(f"{g}/{fname}", "w", newline="\n") as f:
            f.write(text)
        git(g, "add", "-A")
        git(g, "commit", "-qm", name)
    git(g, "checkout", "-q", "main")
    return g


def test_branches_that_touch_different_files_merge_clean():
    g = toy_branches()
    r = subprocess.run([sys.executable, PLAN, "--branches", "p1", "p2", "p3"], cwd=g, capture_output=True, text=True, timeout=60)
    assert r.returncode == 0 and "no conflicts" in r.stdout.lower(), (r.stdout, r.stderr)


def test_branches_that_edit_the_same_lines_are_reported_with_the_pair_and_file():
    g = toy_branches()
    r = subprocess.run([sys.executable, PLAN, "--branches", "p1", "p3", "p4"], cwd=g, capture_output=True, text=True, timeout=60)
    assert r.returncode == 1 and "p3" in r.stdout and "p4" in r.stdout and "shared.txt" in r.stdout, (r.stdout, r.stderr)
    assert not any("p1" in ln and "conflict" in ln.lower() for ln in r.stdout.splitlines()), r.stdout  # p1 is clean
    status = subprocess.run(["git", "-C", g, "status", "--porcelain"], capture_output=True, text=True).stdout
    assert status.strip() == "", "a dry run must leave the checkout untouched"


if __name__ == "__main__":
    from tool_tests import run_cases
    run_cases([v for k, v in sorted(globals().items()) if k.startswith("test_")], "test_parts_plan")
