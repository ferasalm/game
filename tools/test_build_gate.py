#!/usr/bin/env python3
"""Self-test for build_gate.py: python tools/test_build_gate.py (temp git repos, plain asserts, exit 1 on failure)."""
import os
import subprocess
import sys
import tempfile

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import build_gate as bg  # noqa: E402
from test_gate_checklist import (  # noqa: E402, F401
    test_checklist_forms_pass,
    test_checklist_forms_miss,
    test_nowork_wins_over_checklist_miss,
    test_no_checklist_warn,
    test_unknown_checklist_warn,
)

PASSED = "ok   docs\nok   tests\n     tests: 700 passed\nall checks passed\n"
BRIEF = "# Brief: x\n## What to build\n1. `features/ui/` is fine to read\n## Do NOT edit\n`content/world/areas.json`\n" \
    "`features/world/view/`\n`*.tscn`\n## Tests\nrender to inbox/x_shot.png\n"


def sh(repo, *args):
    import time
    for i in range(3):
        try:
            return subprocess.run(["git", "-C", repo, "-c", "user.name=t", "-c", "user.email=t@t", *args],
                                  check=True, capture_output=True)
        except subprocess.CalledProcessError:
            if i == 2:
                raise
            time.sleep(0.1)


def write(repo, path, text):
    full = os.path.join(repo, path)
    os.makedirs(os.path.dirname(full), exist_ok=True)
    with open(full, "w", encoding="utf-8", newline="\n") as f:
        f.write(text)


def commit(repo, msg):
    sh(repo, "add", "-A")
    sh(repo, "commit", "-q", "-m", msg)
    return bg.git(repo, "rev-parse", "HEAD").strip()


def new_repo():
    repo = tempfile.mkdtemp()
    sh(repo, "init", "-q", "-b", "main")
    write(repo, "a.gd", "## a\nvar x: int = 0\n")
    return repo, commit(repo, "base")


def gate(repo, base, check_text=PASSED, brief=BRIEF, fix_from=""):
    for name, text in (("check.txt", check_text), ("brief.md", brief)):
        write(repo + "_x", name, text)
    args = ["gate", "--wt", repo, "--base", base, "--brief", repo + "_x/brief.md", "--check", repo + "_x/check.txt",
            "--inbox", repo + "_x"] + (["--fix-from", fix_from] if fix_from else [])
    return bg.main(args)


def verdict_of(capsys_fn):
    from io import StringIO
    old, sys.stdout = sys.stdout, StringIO()
    try:
        code = capsys_fn()
        out = sys.stdout.getvalue()
    finally:
        sys.stdout = old
    return code, out


def test_uid_only_leftovers_are_nowork():  # the empty balance-gear run: a WIP commit of Godot's .uid files only
    repo, base = new_repo()
    write(repo, "features/x/test_x.gd.uid", "uid://abc\n")
    write(repo, "docs/MAP.md", "# Map\n")
    commit(repo, "WIP: build leftovers (build_pipeline)")
    code, out = verdict_of(lambda: gate(repo, base))
    assert code == 1 and out.strip().endswith("VERDICT NOWORK"), out


def test_fail_line_fails_even_with_commits():
    repo, base = new_repo()
    write(repo, "features/x/logic/x.gd", "## x\nvar y: int = 0\n")
    commit(repo, "feat")
    code, out = verdict_of(lambda: gate(repo, base, "ok   docs\nFAIL tests (.check/tests.log)\n1 check(s) FAILED\n"))
    assert code == 1 and "FAIL tests" in out and out.strip().endswith("VERDICT FAIL"), out
    code, out = verdict_of(lambda: gate(repo, base, "ok   docs\n"))  # a check that never finished is no pass
    assert out.strip().endswith("VERDICT FAIL"), out


def test_forbidden_file_is_breach():
    repo, base = new_repo()
    write(repo, "features/world/view/cam.gd", "## c\nvar z: int = 0\n")
    commit(repo, "feat")
    code, out = verdict_of(lambda: gate(repo, base))
    assert code == 1 and "BREACH features/world/view/cam.gd" in out and out.strip().endswith("VERDICT BREACH"), out
    assert bg.forbidden_paths(BRIEF) == ["content/world/areas.json", "features/world/view/", "*.tscn"]
    assert bg.breaches(["level.tscn", "features/world/viewer.gd"], bg.forbidden_paths(BRIEF)) == ["level.tscn"]


def test_clean_run_passes_with_checklist():
    repo, base = new_repo()
    write(repo, "features/x/logic/x.gd", "## x\nfunc f() -> float:\n\treturn 37.5\n\tvar b: int = r.integer(\"bits\", 1, 7)\n")
    write(repo, "features/x/tests/test_x.gd", "## t\nvar n: int = 99\n")
    write(repo, "localization/x.csv", "keys,en\nX_A,A\n")
    fix = commit(repo, "feat")
    write(repo, "features/x/tests/test_x.gd", "## t\nvar n: int = 98\n")
    commit(repo, "fix pass")
    code, out = verdict_of(lambda: gate(repo, base, fix_from=fix))
    assert code == 0 and out.strip().endswith("VERDICT PASS"), out
    assert "WARN numbers in code: 1 line(s)" in out and "37.5" in out, out  # tests may hold numbers; code may not
    assert "WARN render: inbox/x_shot.png missing" in out, out
    assert "WARN fix pass edited tests: features/x/tests/test_x.gd" in out, out
    assert "player text: 2 new line(s)" in out, out


def test_moving_base_is_not_the_runs_work():  # puzzle-logic: the session branch gained commits during the run
    repo, base = new_repo()
    sh(repo, "checkout", "-q", "-b", "run")
    write(repo, "features/x/tests/test_x.gd", "## t\nvar n: int = 3\n")
    commit(repo, "run work")
    sh(repo, "checkout", "-q", "main")
    write(repo, "features/world/view/cam.gd", "## c\n")
    commit(repo, "session work after the fork")
    sh(repo, "checkout", "-q", "run")
    code, out = verdict_of(lambda: gate(repo, "main"))
    assert code == 0 and "BREACH" not in out and out.strip().endswith("VERDICT PASS"), out


def test_code_without_tests_warns():
    items = bg.checklist(["features/x/logic/x.gd"], {}, "", ".", [])
    assert ("WARN", "tests", "code changed but no test file changed") in items


def test_can_skip_only_on_fast_forward_to_checked():
    repo, base = new_repo()
    sh(repo, "checkout", "-q", "-b", "run")
    write(repo, "b.gd", "## b\n")
    checked = commit(repo, "run work")
    sh(repo, "checkout", "-q", "main")
    assert bg.can_skip(repo, checked, "run") == "SKIP"
    sh(repo, "checkout", "-q", "run")
    write(repo, "c.gd", "## c\n")
    commit(repo, "after the check")  # the tip moved past the checked commit
    sh(repo, "checkout", "-q", "main")
    assert bg.can_skip(repo, checked, "run") == "CHECK"
    write(repo, "d.gd", "## d\n")
    commit(repo, "session moved")  # no fast-forward: the merged tree was never checked
    assert bg.can_skip(repo, checked, "run") == "CHECK"
    assert bg.can_skip(repo, "", "run") == "CHECK"


def test_merge_run_refuses_non_pass_and_fast_forwards_a_pass():
    top = tempfile.mkdtemp()
    repo = os.path.join(top, "game")
    os.makedirs(repo)
    sh(repo, "init", "-q", "-b", "main")
    write(repo, "a.gd", "## a\n")
    commit(repo, "base")
    wt = os.path.join(top, "game-wt", "job")
    sh(repo, "worktree", "add", "-q", "-b", "gemini/job", wt)
    write(wt, "b.gd", "## b\n")
    checked = commit(wt, "work")
    script = os.path.join(os.path.dirname(os.path.abspath(__file__)), "merge_run.sh")
    run = lambda: subprocess.run(["bash", script, "job"], cwd=repo, capture_output=True, text=True)
    write(top, "game-wt/job.result", f"FAIL 12:00 gemini/job\nchecked {checked}\n")
    r = run()
    assert r.returncode != 0 and "refusing" in r.stderr, r.stderr
    write(top, "game-wt/job.result", f"PASS 12:00 gemini/job\nchecked {checked}\n")
    r = run()
    assert r.returncode == 0 and "check reused" in r.stdout, r.stdout + r.stderr
    assert bg.git(repo, "rev-parse", "HEAD").strip() == checked and not os.path.isdir(wt)


if __name__ == "__main__":
    tests = [v for k, v in sorted(globals().items()) if k.startswith("test_")]
    for t in tests:
        t()
    print(f"build_gate: {len(tests)} tests passed")
