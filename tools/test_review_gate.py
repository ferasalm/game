#!/usr/bin/env python3
"""Self-test for tools/hooks/review_gate.py + review_stamp.py (D5, D21): no game render reaches Feras unreviewed.

Black box: both run as subprocesses; REVIEW_STAMP_DIR points them at a temp stamp folder.
"""
import glob
import json
import os
import re
import subprocess
import sys
import tempfile

TOOLS = os.path.dirname(os.path.abspath(__file__))
GATE = os.path.join(TOOLS, "hooks", "review_gate.py")
STAMP = os.path.join(TOOLS, "hooks", "review_stamp.py")


class Box:
    def __init__(self):
        self.root = tempfile.mkdtemp()
        self.env = dict(os.environ, REVIEW_STAMP_DIR=os.path.join(self.root, "stamps"))

    def file(self, rel, data=b"png bytes"):
        p = os.path.join(self.root, rel)
        os.makedirs(os.path.dirname(p), exist_ok=True)
        with open(p, "wb") as f:
            f.write(data)
        return p

    def gate(self, tool, tool_input):
        payload = {"tool_name": tool, "tool_input": tool_input, "cwd": self.root, "hook_event_name": "PreToolUse"}
        return subprocess.run([sys.executable, GATE], input=json.dumps(payload), capture_output=True, text=True,
                              env=self.env)

    def send(self, *paths):
        return self.gate("SendUserFile", {"files": list(paths), "status": "normal"})

    def stamp(self, *args):
        return subprocess.run([sys.executable, STAMP, *args], capture_output=True, text=True, env=self.env)


def test_unreviewed_render_is_blocked():
    b = Box()
    r = b.send(b.file("inbox/neon_game_roof.png"))
    assert r.returncode == 2 and "BLOCKED" in r.stderr and "neon_game_roof.png" in r.stderr, (r.returncode, r.stderr)
    assert "review_stamp" in r.stderr and "review-player" in r.stderr and "review-feras" in r.stderr, r.stderr


def test_stamped_render_passes_until_it_changes():
    b = Box()
    p = b.file("inbox/neon_game_roof.png")
    assert b.stamp(p, "--player", "legible, portrait in frame", "--feras", "no repeat notes").returncode == 0
    assert b.send(p).returncode == 0, "a stamped render passes"
    b.file("inbox/neon_game_roof.png", b"a new render")
    assert b.send(p).returncode == 2, "the stamp is the file's sha256: a new render needs a new review"


def test_stamp_needs_both_reviews():
    b = Box()
    p = b.file("inbox/menu_pause.png")
    assert b.stamp(p, "--player", "ok").returncode != 0, "review-feras missing"
    assert b.stamp(p, "--player", "ok", "--feras", "").returncode != 0, "an empty verdict is no review"
    assert b.send(p).returncode == 2


def test_relative_paths_resolve_against_cwd():
    b = Box()
    b.file("inbox/neon_battle.png")
    assert b.send("inbox/neon_battle.png").returncode == 2


def test_exempt_and_non_render_files_pass():
    b = Box()
    for rel in ("inbox/flow/roya_style_v3_2k.jpg", "inbox/Neon Glitch concept art/Bilqis.jpg",
                "inbox/concept_roof.png", "docs/report.md", "notes/summary.png"):
        r = b.send(b.file(rel))
        assert r.returncode == 0, (rel, r.stderr)


def test_eye_gate_and_bake_outputs_are_renders():
    b = Box()
    for rel in ("scratch/eye/contact.png", "scratch/eye/clip.mp4", "scratch/eye/f00000042.png",
                ".bake/roya/idle_s.png", "inbox/playtest/frame_3.png"):
        assert b.send(b.file(rel)).returncode == 2, rel


def test_artifact_inputs_are_all_checked():
    b = Box()
    png = b.file("inbox/neon_start_title.png")
    page = b.file("scratch/page.html", b"<html></html>")
    for tool_input in ({"file_path": png}, {"file_path": page, "files": {"shot.png": png}},
                       {"file_path": page, "files": {"shot.png": {"from": png}}},
                       {"file_path": page, "files": [{"path": png}]}, {"url": "x", "asset": True, "file_paths": [png]}):
        assert b.gate("Artifact", tool_input).returncode == 2, tool_input
    assert b.gate("Artifact", {"file_path": page}).returncode == 0


def test_other_tools_and_bad_input_pass():
    b = Box()
    assert b.gate("Bash", {"command": "ls inbox/x.png"}).returncode == 0
    r = subprocess.run([sys.executable, GATE], input="not json", capture_output=True, text=True, env=b.env)
    assert r.returncode == 0, "a hook crash never blocks a tool"
    assert b.send(os.path.join(b.root, "inbox/missing.png")).returncode == 0, "a missing file: the tool reports it"


def test_every_shot_tool_output_is_caught():
    """Each tools/shot_*.gd output folder or file (OUT_DIR, OUT_PATH, *_PNG) is a render to the gate."""
    b = Box()
    found = 0
    for gd in sorted(glob.glob(os.path.join(TOOLS, "shot_*.gd"))):
        text = open(gd, encoding="utf-8").read()
        for name, value in re.findall(r'const (OUT_\w+|\w+_PNG)\s*:\s*String\s*=\s*"([^"]+)"', text):
            rel = re.sub(r"^(C:/dev/game/|res://)", "", value)
            rel = rel if os.path.splitext(rel)[1] else rel + "/shot.png"
            found += 1
            assert b.send(b.file(rel)).returncode == 2, (os.path.basename(gd), name, value)
    assert found >= 6, f"only {found} shot outputs found: the pattern above missed some"


if __name__ == "__main__":
    tests = [v for k, v in sorted(globals().items()) if k.startswith("test_")]
    for t in tests:
        t()
    print(f"test_review_gate: {len(tests)} tests passed")
