#!/usr/bin/env python3
"""Self-test for the D6 gate rules (2026-10-27): protected tests and assets, removed checks, new tests fail on base."""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import build_gate as bg  # noqa: E402
from test_build_gate import PASSED, commit, new_repo, verdict_of, write  # noqa: E402

BRIEF = "# Brief: x\n## What to build\n1. a thing\n## Do NOT edit\n`content/world/areas.json`\n## Tests\nsome\n"
MAY = BRIEF + "## May edit\n`features/x/tests/test_x.gd`\n"
OLD = "## t\nfunc test_a() -> void:\n\tcheck_eq(f(), 1, \"a\")\n\tcheck_eq(f(), 2, \"b\")\nfunc test_b() -> void:\n\tcheck_true(true, \"c\")\n"


def gate(repo, base, brief=BRIEF, extra=()):
    for name, text in (("check.txt", PASSED), ("brief.md", brief)):
        write(repo + "_x", name, text)
    args = ["gate", "--wt", repo, "--base", base, "--brief", repo + "_x/brief.md", "--check", repo + "_x/check.txt",
            "--inbox", repo + "_x", *extra]
    return verdict_of(lambda: bg.main(args))


def repo_with_test():
    repo, _ = new_repo()
    write(repo, "features/x/tests/test_x.gd", OLD)
    write(repo, "assets/a.png", "png")
    write(repo, "assets/a.png.import", "[remap]\nv=1\n")
    return repo, commit(repo, "tests first")


def test_brief_without_do_not_edit_fails():
    repo, base = new_repo()
    write(repo, "features/x/logic/x.gd", "## x\nvar a: int = 1\n")
    commit(repo, "feat")
    code, out = gate(repo, base, brief="# Brief\n## What to build\n1. x\n")
    assert code == 1 and "no '## Do NOT edit' section" in out and out.strip().endswith("VERDICT FAIL"), out


def test_existing_test_edit_is_breach_unless_whitelisted():
    repo, base = repo_with_test()
    write(repo, "features/x/tests/test_x.gd", OLD.replace("f(), 1", "f(), 3"))
    commit(repo, "edit a test")
    code, out = gate(repo, base)
    assert code == 1 and "BREACH features/x/tests/test_x.gd" in out and out.strip().endswith("VERDICT BREACH"), out
    code, out = gate(repo, base, brief=MAY)
    assert code == 0 and out.strip().endswith("VERDICT PASS"), out


def test_new_test_file_is_allowed():
    repo, base = repo_with_test()
    write(repo, "features/x/logic/x.gd", "## x\nvar a: int = 1\n")
    write(repo, "features/x/tests/test_y.gd", "## y\nfunc test_y() -> void:\n\tcheck_true(true, \"y\")\n")
    commit(repo, "feat")
    code, out = gate(repo, base)
    assert code == 0 and out.strip().endswith("VERDICT PASS"), out


def test_assets_are_protected_including_import_files():
    repo, base = repo_with_test()
    write(repo, "assets/a.png.import", "[remap]\nv=2\n")
    commit(repo, "import churn")
    code, out = gate(repo, base)
    assert code == 1 and "BREACH assets/a.png.import" in out, out
    repo, base = repo_with_test()
    write(repo, "assets/new.png", "x")
    commit(repo, "new asset")
    code, out = gate(repo, base)
    assert code == 1 and "BREACH assets/new.png" in out, out


def test_import_files_elsewhere_stay_noise():
    repo, base = repo_with_test()
    write(repo, "features/x/logic/x.gd", "## x\nvar a: int = 1\n")
    write(repo, "elsewhere/b.png.import", "[remap]\n")
    commit(repo, "feat")
    code, out = gate(repo, base)
    assert code == 0 and "BREACH" not in out, out


def test_removed_assert_or_test_func_fails_even_when_whitelisted():
    repo, base = repo_with_test()
    write(repo, "features/x/tests/test_x.gd", OLD.replace("\tcheck_eq(f(), 2, \"b\")\n", ""))
    commit(repo, "drop a check")
    code, out = gate(repo, base, brief=MAY)
    assert code == 1 and "removed 1 check" in out and out.strip().endswith("VERDICT FAIL"), out
    repo, base = repo_with_test()
    write(repo, "features/x/tests/test_x.gd", "## t\nfunc test_a() -> void:\n\tcheck_eq(f(), 1, \"a\")\n\tcheck_eq(f(), 2, \"b\")\n")
    commit(repo, "drop test_b")
    code, out = gate(repo, base, brief=MAY)
    assert code == 1 and "removed test func test_b" in out, out


def test_changed_or_moved_check_is_not_removed():
    repo, base = repo_with_test()
    write(repo, "features/x/tests/test_x.gd", OLD.replace("f(), 2, \"b\"", "f(), 5, \"b\""))
    commit(repo, "retune a number")
    code, out = gate(repo, base, brief=MAY)
    assert code == 0 and "removed" not in out, out


def test_new_python_test_must_fail_on_base():
    repo, base = new_repo()
    write(repo, "feature.txt", "done")
    write(repo, "tools/test_new.py", "import os\nassert os.path.exists('feature.txt'), 'missing'\n")
    commit(repo, "feat + test")
    code, out = gate(repo, base, extra=["--run-new-tests", "py"])
    assert code == 0 and "new test fails on base: tools/test_new.py" in out, out
    repo, base = new_repo()
    write(repo, "feature.txt", "done")
    write(repo, "tools/test_new.py", "assert True\n")
    commit(repo, "feat + vacuous test")
    code, out = gate(repo, base, extra=["--run-new-tests", "py"])
    assert code == 1 and "passes on base" in out and out.strip().endswith("VERDICT FAIL"), out


def test_gd_new_test_command_uses_the_runner_and_a_slot():
    cmd = bg.newtest_command("features/x/tests/test_y.gd", "/t")
    assert "tests/runner.gd" in cmd[-1] and "test_y" in cmd[-1] and "acquire_check_slot" in cmd[-1], cmd


if __name__ == "__main__":
    tests = [v for k, v in sorted(globals().items()) if k.startswith("test_")]
    for t in tests:
        t()
    print(f"test_gate_d6: {len(tests)} tests passed")
