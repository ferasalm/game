#!/usr/bin/env python3
"""Self-test for pre_spend.py: a paid tool is blocked without Feras's OK in a user message; Hyper3D gets a reminder."""
import json
import os
import subprocess
import sys
import tempfile

HOOK = os.path.join(os.path.dirname(os.path.abspath(__file__)), "pre_spend.py")


def transcript(*entries):
    p = tempfile.mkdtemp() + "/t.jsonl"
    with open(p, "w", encoding="utf-8", newline="\n") as f:
        for e in entries:
            f.write(json.dumps(e) + "\n")
    return p


def user(text):
    return {"type": "user", "message": {"role": "user", "content": text}}


def run(tool, path=""):
    return subprocess.run([sys.executable, HOOK], input=json.dumps({"tool_name": tool, "transcript_path": path}),
                          capture_output=True, text=True)


def test_paid_tool_blocked_without_ok():
    r = run("mcp__openrouter__generate-image", transcript(user("make a picture")))
    assert r.returncode == 2 and "BLOCKED" in r.stderr, (r.returncode, r.stderr)
    assert run("mcp__runware__imageInference").returncode == 2


def test_ok_must_be_a_user_message():
    assert run("mcp__openrouter__generate-image", transcript(user("Spend OK for the logo"))).returncode == 0
    claude = {"type": "assistant", "message": {"role": "assistant", "content": [{"type": "text", "text": "spend ok"}]}}
    assert run("mcp__openrouter__generate-image", transcript(claude)).returncode == 2
    result = {"type": "user", "message": {"role": "user", "content": [{"type": "tool_result", "content": "spend ok"}]}}
    assert run("mcp__openrouter__generate-image", transcript(result)).returncode == 2


def test_old_ok_expires():
    p = transcript(user("spend ok"), *[user(f"msg {i}") for i in range(9)])
    assert run("mcp__openrouter__generate-speech", p).returncode == 2


def test_hyper3d_reminds_and_other_tools_pass():
    r = run("mcp__hyper3d__rodin_generate", transcript(user("x")))
    assert r.returncode == 0 and "credit cost" in r.stdout, r.stdout
    r = run("Read")
    assert r.returncode == 0 and r.stdout == "" and r.stderr == ""


def test_connector_paid_tools_blocked():  # 2026-10-27: these paid MCP tools slipped past the first regex
    for tool in ("mcp__e90b7708-6075-49b9-9f7a-3728423bc323__creative_generate_image",
                 "mcp__5102e12a-bcea-4184-bf9f-903d6e0ac4ac__vidiq_generate_video",
                 "mcp__b4f13e4a-fbfa-405c-b7d5-efd7ae151a47__run"):
        assert run(tool, transcript(user("make it"))).returncode == 2, tool
    assert run("mcp__b4f13e4a-fbfa-405c-b7d5-efd7ae151a47__list_models").returncode == 0


if __name__ == "__main__":
    tests = [v for k, v in sorted(globals().items()) if k.startswith("test_")]
    for t in tests:
        t()
    print(f"test_pre_spend: {len(tests)} tests passed")
