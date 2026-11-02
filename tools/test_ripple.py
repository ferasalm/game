#!/usr/bin/env python3
"""Row 26 S13 (Feras 11-02): two builder runs on 11-02 ended BREACH because the brief's May edit missed existing tests the
change forces (tools/test_usage_row.py pinned the runs.csv header; three older tests built merge_run .result fixtures).
tools/ripple.py BRIEF lists, BEFORE launch, every existing test file that names a file the brief will edit, so the head adds
the unavoidable fixture edits to May edit with a reason."""
import os
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
RIPPLE = os.path.join(HERE, "ripple.py")


def put(root, rel, text):
    path = os.path.join(root, rel)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8", newline="\n") as f:
        f.write(text)


def brief(root, may, tests=()):
    block = "\n".join(f"`{p}`" for p in may) or "none"
    put(root, "brief.md", f"# Brief: x\n\n## May edit\n{block}\n\n## Tests\n"
        + "".join(f"- {t} :: every test\n" for t in tests) + "\n## Checklist\n- file: x\n")
    return os.path.join(root, "brief.md")


def ripple(root, b):
    r = subprocess.run([sys.executable, RIPPLE, b, "--root", root], capture_output=True, text=True, timeout=60)
    assert r.returncode == 0, (r.stdout, r.stderr)
    return r.stdout, r.stdout.splitlines()


def test_a_test_that_names_an_edited_file_is_listed_with_that_file():
    with tempfile.TemporaryDirectory() as d:
        put(d, "tools/merge_run.sh", "#!/bin/bash\n")
        put(d, "tools/test_old.py", "def test_x():\n    run('tools/merge_run.sh')\n")
        put(d, "tools/test_other.py", "def test_y():\n    pass\n")
        out, lines = ripple(d, brief(d, ["tools/merge_run.sh"]))
        assert lines[0].startswith("RIPPLE 1 test file"), out
        assert any("tools/test_old.py" in ln and "merge_run.sh" in ln for ln in lines), out
        assert "test_other" not in out, out


def test_a_bare_basename_counts_and_a_longer_name_does_not():
    with tempfile.TemporaryDirectory() as d:
        put(d, "tools/a.py", "A = 1\n")
        put(d, "tools/test_bare.py", "subprocess.run(['python', 'a.py'])\n")
        put(d, "tools/test_longer.py", "import data.py_helpers\nx = 'metadata.py'\n")  # contains a.py inside other names
        out, lines = ripple(d, brief(d, ["tools/a.py"]))
        assert lines[0].startswith("RIPPLE 1 test file") and "tools/test_bare.py" in out and "test_longer" not in out, out


def test_the_locked_tests_the_brief_names_are_not_listed():
    with tempfile.TemporaryDirectory() as d:
        put(d, "tools/a.py", "A = 1\n")
        put(d, "tools/test_a.py", "run('tools/a.py')\n")
        put(d, "tools/test_old.py", "run('tools/a.py')\n")
        out, lines = ripple(d, brief(d, ["tools/a.py"], tests=["tools/test_a.py"]))
        assert "tools/test_old.py" in out and "tools/test_a.py" not in out, out


def test_godot_tests_are_scanned_too():
    with tempfile.TemporaryDirectory() as d:
        put(d, "features/combat/logic/hit.gd", "extends RefCounted\n")
        put(d, "tests/test_hit.gd", "var s = load('res://features/combat/logic/hit.gd')\n")
        out, lines = ripple(d, brief(d, ["features/combat/logic/hit.gd"]))
        assert "tests/test_hit.gd" in out, out


def test_nothing_to_report_reads_ripple_0_and_none_means_no_scan():
    with tempfile.TemporaryDirectory() as d:
        put(d, "tools/a.py", "A = 1\n")
        put(d, "tools/test_x.py", "pass\n")
        assert ripple(d, brief(d, ["tools/a.py"]))[1][0] == "RIPPLE 0"
        assert ripple(d, brief(d, []))[1][0] == "RIPPLE 0"


def test_a_long_list_is_capped_at_20_lines():
    with tempfile.TemporaryDirectory() as d:
        put(d, "tools/a.py", "A = 1\n")
        for i in range(30):
            put(d, f"tools/test_n{i:02d}.py", "run('tools/a.py')\n")
        out, lines = ripple(d, brief(d, ["tools/a.py"]))
        assert lines[0].startswith("RIPPLE 30 test file") and len(lines) <= 22 and "10 more" in out, out


if __name__ == "__main__":
    from tool_tests import run_cases
    run_cases([v for k, v in sorted(globals().items()) if k.startswith("test_")], "test_ripple")
