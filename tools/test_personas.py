#!/usr/bin/env python3
"""The persona copies are stock agency-agents text plus ONE shared overlay (row 28 part g, Feras 11-04; this reverses the
10-28 'tailored personas' rule). Project text lives in .agents/project-overlay.md only; the copies never drift."""
import contextlib
import io
import os
import re
import subprocess
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import sync_personas as sp  # noqa: E402

PROJECT = re.compile(r"Neon|Sana'a|Feras|Godot 4\.7|CANON")
NOTE = ("> Builder note: .agents/project-overlay.md and the brief win where this differs. "
        "Source: agency-agents (MIT), .agents/skills/AGENCY-LICENSE.")
IMPORTED = ("code-reviewer", "cultural-intelligence-strategist", "image-prompt-engineer", "minimal-change-engineer")
OVERLAY = sp.ROOT / ".agents" / "project-overlay.md"
MAX_OVERLAY_LINES = 40


def source(name):
    return (sp.ROOT / ".agents/skills" / name / "SKILL.md").read_text(encoding="utf-8")


def problems(name, text):
    """The reasons one persona text breaks the rules (empty list = fine)."""
    meta, body = sp.split(text)
    out = []
    if meta.get("name") != name:
        out.append("frontmatter name is not the folder name")
    if not meta.get("description"):
        out.append("no description")
    if PROJECT.search(text):
        out.append("holds project text: " + PROJECT.search(text).group())
    if NOTE not in body:
        out.append("no overlay note")
    if body.count("Builder note:") != 1:
        out.append("not exactly one builder note")
    return out


def test_every_persona_is_stock_text_with_the_overlay_note():
    bad = []
    for name in sp.PERSONAS + IMPORTED:
        bad += [f"{name}: {why}" for why in problems(name, source(name))]
    assert not bad, "\n".join(bad)


def test_the_rules_catch_bad_copies():  # probe each rule with one bad case (LESSONS: a check that only prints never fails)
    good = "---\nname: x\ndescription: d\n---\n\n" + NOTE + "\n\n# X\n"
    assert problems("x", good) == []
    assert "frontmatter name is not the folder name" in problems("y", good)
    assert any("project text" in p for p in problems("x", good + "Neon Glitch\n"))
    assert "no overlay note" in problems("x", good.replace(NOTE, "note"))
    assert "not exactly one builder note" in problems("x", good + "> Builder note: again\n")
    assert "no description" in problems("x", good.replace("description: d", "description:"))


def test_overlay_is_short_and_pointed():
    lines = OVERLAY.read_text(encoding="utf-8").splitlines()
    assert len(lines) <= MAX_OVERLAY_LINES, f"{len(lines)} lines (max {MAX_OVERLAY_LINES})"
    text = "\n".join(lines)
    for ref in ("docs/CANON.md", "docs/VISION.md", ".claude/rules/code.md", "the brief wins"):
        assert ref in text or ref.replace("the brief wins", "brief wins") in text, f"overlay lacks {ref}"


def test_licence_is_kept():
    assert (sp.ROOT / ".agents/skills/AGENCY-LICENSE").exists()


def test_copies_match_the_source():
    r = subprocess.run([sys.executable, os.path.join(sp.ROOT, "tools", "sync_personas.py"), "--check"], capture_output=True, text=True)
    assert r.returncode == 0, r.stdout + r.stderr


def test_drift_is_caught():
    path = sp.ROOT / ".claude/skills/game-designer/SKILL.md"
    old = path.read_text(encoding="utf-8")
    try:
        path.write_text(old + "\nedited by hand\n", encoding="utf-8", newline="\n")
        with contextlib.redirect_stdout(io.StringIO()):  # the planted drift's FAIL line is expected: hide it
            assert sp.main(check=True) == 1
    finally:
        path.write_text(old, encoding="utf-8", newline="\n")


if __name__ == "__main__":
    tests = [v for k, v in sorted(globals().items()) if k.startswith("test_")]
    failed = []
    for t in tests:
        try:
            t()
        except AssertionError as e:
            failed.append(f"{t.__name__}: {e}")
    print("\n".join(failed) if failed else f"test_personas: {len(tests)} tests passed")
    sys.exit(1 if failed else 0)
