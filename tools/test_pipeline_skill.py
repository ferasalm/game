#!/usr/bin/env python3
"""Row 26 S6 (Feras 11-02): the whole workflow lives in ONE skill folder, .claude/skills/low-cost-pipeline/, so it can be
edited, upgraded and diversified without stale lines elsewhere polluting a model's context. This test is the guard: the
entry file stays short, every file in the folder is reachable from it, every tool it names exists, every changelog line is
dated, and the builders skill no longer repeats the workflow."""
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
SKILL_DIR = os.path.join(ROOT, ".claude", "skills", "low-cost-pipeline")
TOOL = re.compile(r"(?<![\w/.-])tools/[A-Za-z0-9_./-]*[A-Za-z0-9_]\.(?:py|sh|conf|json)")


def read(path):
    with open(path, encoding="utf-8") as f:
        return f.read()


def skill_files():
    out = []
    for base, _, names in os.walk(SKILL_DIR):
        out += [os.path.join(base, n) for n in names if n.endswith(".md")]
    return sorted(out)


def test_the_entry_file_is_short_and_named_right():
    text = read(os.path.join(SKILL_DIR, "SKILL.md"))
    assert text.startswith("---\nname: low-cost-pipeline\n"), "front matter name"
    assert len(text.splitlines()) <= 60, f"SKILL.md has {len(text.splitlines())} lines (max 60): move detail to a reference file"
    assert "## Resume" in text and "## Plan a batch" in text and "## Hard rules" in text, "Resume, Plan a batch, Hard rules"


def test_every_file_in_the_folder_is_linked_from_skill_md():
    entry = read(os.path.join(SKILL_DIR, "SKILL.md"))
    for path in skill_files():
        rel = os.path.relpath(path, SKILL_DIR).replace("\\", "/")
        if rel == "SKILL.md":
            continue
        key = rel.split("/")[0] + "/" if rel.startswith("templates/") else rel
        assert key in entry, f"{rel} is not linked from SKILL.md (an orphan file is a stale file)"


def test_every_tool_the_skill_names_exists():
    missing = []
    for path in skill_files():
        for tool in sorted(set(TOOL.findall(read(path)))):
            if "<" in tool or "*" in tool:
                continue
            if not os.path.exists(os.path.join(ROOT, tool)):
                missing.append(f"{os.path.relpath(path, ROOT)}: {tool}")
    assert not missing, "the skill names tools that do not exist:\n" + "\n".join(missing)


def test_the_changelog_is_dated_one_line_per_upgrade():
    lines = [ln for ln in read(os.path.join(SKILL_DIR, "changelog.md")).splitlines() if ln.startswith("- ")]
    assert lines, "changelog.md has no entries"
    for ln in lines:
        assert re.match(r"- 20\d\d-\d\d-\d\d ", ln), f"undated changelog line: {ln[:60]}"


def test_the_builders_skill_no_longer_repeats_the_workflow():
    text = read(os.path.join(ROOT, ".claude", "skills", "builders", "SKILL.md"))
    for stale in ("## The loop", "## Who does what", "## Roster and caps"):
        assert stale not in text, f"builders/SKILL.md still has '{stale}': it lives in low-cost-pipeline"
    assert "low-cost-pipeline" in text, "the builders skill must point to the pipeline skill"


def test_every_template_is_a_brief_with_the_gate_headings():
    heads = ("## Do NOT edit", "## May edit", "## Tests", "## Checklist")
    for name in ("brief-scope.md", "brief-hand.md", "brief-mechanical.md"):
        text = read(os.path.join(SKILL_DIR, "templates", name))
        for h in heads:
            assert h in text, f"templates/{name} lacks '{h}' (build_gate reads it)"


if __name__ == "__main__":
    from tool_tests import run_cases
    run_cases([v for k, v in sorted(globals().items()) if k.startswith("test_")], "test_pipeline_skill")
