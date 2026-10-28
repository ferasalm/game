#!/usr/bin/env python3
"""TEMPLATE.md stays readable by the gate (P3.8, 2026-10-27): its headings, an empty forbidden list, parseable checklist."""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import build_gate as bg  # noqa: E402
import gate_checklist as gc  # noqa: E402
from test_build_gate import commit, new_repo, write  # noqa: E402
from test_gate_d6 import OLD, gate  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TEMPLATE = open(os.path.join(ROOT, "docs", "briefs", "TEMPLATE.md"), encoding="utf-8").read()


def section(heading):
    return TEMPLATE.split(f"\n## {heading}\n", 1)[1].split("\n## ", 1)[0]


def test_template_has_the_sections_the_gate_and_reviewers_read():
    for heading in ("Why", "Do NOT edit", "May edit", "Ripple", "Pre-mortem", "Tests", "Checklist", "Proof"):
        assert f"\n## {heading}\n" in TEMPLATE, heading


def test_template_names_pillar_timebox_first_commit_and_player_visible_tests():
    for phrase in ("Pillar served (docs/VISION.md)", "Timebox:", "First commit within 15 min", "player-visible test",
                   "Routing table", "our rules outrank"):
        assert phrase in TEMPLATE, phrase


def test_template_lists_no_forbidden_or_whitelisted_path():  # a backticked default would block new tests too
    assert bg.forbidden_paths(TEMPLATE) == []
    assert bg.section_paths(TEMPLATE, "May edit") == []


def test_template_checklist_lines_all_parse():
    lines = [ln.strip() for ln in section("Checklist").splitlines() if ln.strip()]
    assert lines and all(gc.check_item(ROOT, ln) is not None for ln in lines), lines


def test_template_brief_allows_new_tests_and_breaches_on_edited_ones():
    repo, _ = new_repo()
    write(repo, "features/x/tests/test_x.gd", OLD)
    base = commit(repo, "tests first")
    brief = "# Brief: x\n## What to build\n1. x\n## Do NOT edit\n" + section("Do NOT edit") + "\n## Tests\nt\n"
    write(repo, "features/x/tests/test_new.gd", "## t\nfunc test_c() -> void:\n\tcheck_true(true, \"c\")\n")
    commit(repo, "new test")
    code, out = gate(repo, base, brief=brief)
    assert "BREACH" not in out and "no '## Do NOT edit' section" not in out, out
    write(repo, "features/x/tests/test_x.gd", OLD + "func test_d() -> void:\n\tcheck_true(true, \"d\")\n")
    commit(repo, "edit old test")
    code, out = gate(repo, base, brief=brief)
    assert code == 1 and "BREACH features/x/tests/test_x.gd" in out, out


if __name__ == "__main__":
    tests = [v for k, v in sorted(globals().items()) if k.startswith("test_")]
    for t in tests:
        t()
    print(f"test_template: {len(tests)} tests passed")
