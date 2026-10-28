#!/usr/bin/env python3
"""The 10 personas are tailored to Neon Glitch (Feras 10-28: "not generic") and their copies never drift (row 1 item 9)."""
import os
import re
import subprocess
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import sync_personas as sp  # noqa: E402

FOREIGN = re.compile(r"\b(Unity|Unreal|FMOD|Wwise|UE5|Blueprints?)\b|C#")
MAX_BYTES = 9000  # build_pipeline pastes a persona into every builder prompt


def source(name):
    return (sp.ROOT / ".agents/skills" / name / "SKILL.md").read_text(encoding="utf-8")


def test_each_persona_is_tailored_to_our_stack():
    bad = []
    for name in sp.PERSONAS:
        text = source(name)
        meta, body = sp.split(text)
        foreign = FOREIGN.search(body)
        for ok, why in ((meta.get("name") == name, "frontmatter name is the folder name"),
                        (bool(meta.get("description")), "has a description"),
                        (not foreign, f"names another engine or tool: {foreign.group() if foreign else ''}"),
                        ("Godot 4.7.2" in body and ".claude/rules/code.md" in body, "names Godot 4.7.2 and .claude/rules/code.md"),
                        (re.search(r"^Adapted from .*AGENCY-LICENSE", body, re.M) is not None, "an 'Adapted from ... AGENCY-LICENSE' line"),
                        ("\n## Output template\n" in body and "\n## Reviewer\n" in body, "Output template and Reviewer sections"),
                        (len(text.encode()) <= MAX_BYTES, f"{len(text.encode())} bytes (max {MAX_BYTES})")):
            if not ok:
                bad.append(f"{name}: {why}")
    assert not bad, "\n".join(bad)


def test_licence_is_kept():
    assert (sp.ROOT / ".agents/skills/AGENCY-LICENSE").exists()


def test_copies_match_the_source():
    r = subprocess.run([sys.executable, os.path.join(sp.ROOT, "tools", "sync_personas.py"), "--check"], capture_output=True, text=True)
    assert r.returncode == 0, r.stdout + r.stderr


def test_drift_is_caught():  # probe the check with one bad case (LESSONS: a check that only prints never fails)
    path = sp.ROOT / ".claude/agents/game-designer.md"
    old = path.read_text(encoding="utf-8") if path.exists() else None
    try:
        path.write_text((old or "") + "\nedited by hand\n", encoding="utf-8", newline="\n")
        assert sp.main(check=True) == 1
    finally:
        if old is None:
            path.unlink()
        else:
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
