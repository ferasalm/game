#!/usr/bin/env python3
"""content/art/refs.json: one approved reference per character (row 1 item 3, 10-28). Every Rodin model has an entry,
each entry cites a live CANON line, and the art skills take references from refs.json, never a hard-coded inbox path."""
import json
import os
import re

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SKILLS = (".claude/skills/3d-model/SKILL.md", ".claude/skills/flow-media/SKILL.md")


def load(rel):
    with open(os.path.join(ROOT, rel), encoding="utf-8") as f:
        return f.read()


def refs():
    return {r["id"]: r for r in json.loads(load("content/art/refs.json"))["items"]}


def test_every_rodin_model_has_a_reference():
    have = refs()
    for m in json.loads(load("content/art/models.json"))["items"]:
        if "rodin" in m.get("scene", "").lower():
            assert m["id"] in have, f"{m['id']} has a Rodin scene but no content/art/refs.json entry"


def test_entries_are_complete_and_cite_canon():
    canon = load("docs/CANON.md")
    for rid, r in refs().items():
        assert re.fullmatch(r"inbox/[^\\]+\.(jpg|jpeg|png|webp)", r["ref"]), (rid, r["ref"])
        assert "/retired/" not in r["ref"] and "/retired/" not in r.get("concept", ""), (rid, "inbox/retired is never a source")
        assert re.fullmatch(r"\d{4}-\d{2}-\d{2}", r["approved"]), (rid, r["approved"])
        assert r["canon"] and r["canon"] in canon, f"{rid}: its CANON line is gone or reworded: {r['canon']!r}"


def test_art_skills_read_refs_json():
    for rel in SKILLS:
        text = load(rel)
        assert "content/art/refs.json" in text, f"{rel} must take references from content/art/refs.json"
        hard = re.findall(r"inbox/flow/\w+_style_v\d\w*\.(?:jpg|png)", text)
        assert not hard, f"{rel} hard-codes a reference ({hard[0]}): name the character, the path lives in refs.json"


if __name__ == "__main__":
    tests = [v for k, v in sorted(globals().items()) if k.startswith("test_")]
    for t in tests:
        t()
    print(f"test_art_refs: {len(tests)} tests passed")
