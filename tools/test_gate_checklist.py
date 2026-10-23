#!/usr/bin/env python3
"""Tests for brief checklist verification in build_gate."""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))


def test_checklist_forms_pass():
    import test_build_gate as tbg
    repo, base = tbg.new_repo()
    tbg.write(repo, "features/x/logic/x.gd", "## x\nfunc foo() -> void:\n\tpass\n")
    tbg.write(repo, "features/x/tests/test_x.gd", "## t\nfunc test_bar() -> void:\n\tpass\n")
    tbg.write(repo, "localization/x.csv", "keys,en\nKEY_ONE,Hello\n")
    tbg.commit(repo, "feat")
    brief = (
        "# Brief: t\n## What to build\n1. x\n## Checklist\n"
        "- file: features/x/logic/x.gd\n"
        "- has: features/x/logic/x.gd :: func foo\n"
        "- test: features/x/tests/test_x.gd :: test_bar\n"
        "- key: localization/x.csv :: KEY_ONE\n"
        "## Proof\n"
    )
    code, out = tbg.verdict_of(lambda: tbg.gate(repo, base, brief=brief))
    assert code == 0 and out.strip().endswith("VERDICT PASS"), out
    assert "CHECKLIST missing" not in out, out


def test_checklist_forms_miss():
    import test_build_gate as tbg
    brief_tmpl = "# Brief: t\n## What to build\n1. x\n## Checklist\n{item}\n## Proof\n"
    miss_items = [
        "- file: features/x/logic/missing.gd",
        "- has: features/x/logic/x.gd :: missing_text",
        "- test: features/x/tests/test_x.gd :: test_missing",
        "- key: localization/x.csv :: KEY_MISSING",
    ]
    for item in miss_items:
        repo, base = tbg.new_repo()
        tbg.write(repo, "features/x/logic/x.gd", "## x\nfunc foo() -> void:\n\tpass\n")
        tbg.write(repo, "features/x/tests/test_x.gd", "## t\nfunc test_bar() -> void:\n\tpass\n")
        tbg.write(repo, "localization/x.csv", "keys,en\nKEY_ONE,Hello\n")
        tbg.commit(repo, "feat")
        brief = brief_tmpl.format(item=item)
        code, out = tbg.verdict_of(lambda: tbg.gate(repo, base, brief=brief))
        assert code == 1 and out.strip().endswith("VERDICT FAIL"), f"Expected FAIL for {item}, got:\n{out}"
        assert f"CHECKLIST missing: {item}" in out, f"Expected miss notice for {item}, got:\n{out}"


def test_nowork_wins_over_checklist_miss():
    import test_build_gate as tbg
    repo, base = tbg.new_repo()
    tbg.write(repo, "test.uid", "uid://abc\n")
    tbg.commit(repo, "WIP: build leftovers (build_pipeline)")
    brief = "# Brief: t\n## What to build\n1. x\n## Checklist\n- file: nonexistent.gd\n## Proof\n"
    code, out = tbg.verdict_of(lambda: tbg.gate(repo, base, brief=brief))
    assert code == 1 and out.strip().endswith("VERDICT NOWORK"), out
    assert "CHECKLIST missing: - file: nonexistent.gd" in out, out


def test_no_checklist_warn():
    import test_build_gate as tbg
    repo, base = tbg.new_repo()
    tbg.write(repo, "features/x/tests/test_x.gd", "## t\nvar n: int = 1\n")
    tbg.commit(repo, "feat")
    brief = "# Brief: t\n## What to build\n1. x\n## Proof\n"
    code, out = tbg.verdict_of(lambda: tbg.gate(repo, base, brief=brief))
    assert code == 0 and out.strip().endswith("VERDICT PASS"), out
    assert "WARN no checklist in the brief" in out, out


def test_unknown_checklist_warn():
    import test_build_gate as tbg
    repo, base = tbg.new_repo()
    tbg.write(repo, "features/x/tests/test_x.gd", "## t\nvar n: int = 1\n")
    tbg.commit(repo, "feat")
    brief = "# Brief: t\n## What to build\n1. x\n## Checklist\n- unknown: foo bar\n## Proof\n"
    code, out = tbg.verdict_of(lambda: tbg.gate(repo, base, brief=brief))
    assert code == 0 and out.strip().endswith("VERDICT PASS"), out
    assert "WARN checklist item not understood: - unknown: foo bar" in out, out


if __name__ == "__main__":
    tests = [v for k, v in sorted(globals().items()) if k.startswith("test_")]
    for t in tests:
        t()
    print(f"test_gate_checklist: {len(tests)} tests passed")
