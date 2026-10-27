#!/usr/bin/env python3
"""Tests for tools/cf_mcp/server.py over its real stdio protocol, in dry mode (no Cloudflare call, no credentials)."""
import json
import os
import subprocess
import sys
from pathlib import Path

SERVER = Path(__file__).with_name("server.py")


def _run(messages: list) -> list:
    env = dict(os.environ, CF_MCP_DRY="1")
    lines = "".join(json.dumps(m) + "\n" for m in messages)
    out = subprocess.run([sys.executable, str(SERVER)], input=lines, capture_output=True, text=True, env=env,
                         timeout=30)
    assert out.returncode == 0, out.stderr
    return [json.loads(line) for line in out.stdout.splitlines() if line.strip()]


def main() -> int:
    replies = _run([
        {"jsonrpc": "2.0", "id": 1, "method": "initialize", "params": {"protocolVersion": "2025-06-18"}},
        {"jsonrpc": "2.0", "method": "notifications/initialized"},
        {"jsonrpc": "2.0", "id": 2, "method": "tools/list"},
        {"jsonrpc": "2.0", "id": 3, "method": "tools/call", "params": {"name": "triage_trace", "arguments": {
            "trace": "player frozen after crossing", "files": ["features/ui/view/ui_stack.gd"]}}},
        {"jsonrpc": "2.0", "id": 4, "method": "tools/call", "params": {"name": "generate_patch", "arguments": {
            "diagnosis": "x", "files": ["../outside.txt"], "agent": "minimal-change-engineer"}}},
        {"jsonrpc": "2.0", "id": 5, "method": "tools/call", "params": {"name": "nope", "arguments": {}}},
        {"jsonrpc": "2.0", "id": 6, "method": "tools/call", "params": {"name": "triage_trace", "arguments": {
            "trace": "x", "agent": "../../CLAUDE"}}},
    ])
    fails = []
    if [r["id"] for r in replies] != [1, 2, 3, 4, 5, 6]:
        fails.append("a notification got a reply or a request got none")
    names = [t["name"] for t in replies[1]["result"]["tools"]]
    if names != ["triage_trace", "generate_patch"]:
        fails.append(f"tools/list names {names}")
    triage = json.loads(replies[2]["result"]["content"][0]["text"])
    if triage["model"] != "@cf/deepseek-ai/deepseek-v4.1-flash-1017" or "func has_screen" not in triage["messages"][1]["content"]:
        fails.append("triage_trace: wrong model or the file was not read into the prompt")
    patch = json.loads(replies[3]["result"]["content"][0]["text"])
    if patch["model"] != "@cf/deepseek-ai/deepseek-v4.1-flash-1017" or "not a file inside the repo" not in patch["messages"][1]["content"]:
        fails.append("generate_patch: wrong model or a path outside the repo was read")
    system = patch["messages"][0]["content"]
    if "# Minimal Change Engineer" not in system[:600] or not system.rstrip().endswith("Nothing else."):
        fails.append("generate_patch: the agent persona did not lead, or the tool rules did not come last")
    if json.loads(replies[5]["result"]["content"][0]["text"])["messages"][0]["content"] != json.loads(
            replies[2]["result"]["content"][0]["text"])["messages"][0]["content"]:
        fails.append("triage_trace: a path-like agent name changed the system prompt")
    if "error" not in replies[4]:
        fails.append("unknown tool did not return an error")
    for f in fails:
        print("FAIL", f)
    print("cf_mcp: ok" if not fails else f"cf_mcp: {len(fails)} failed")
    return 1 if fails else 0


if __name__ == "__main__":
    sys.exit(main())
