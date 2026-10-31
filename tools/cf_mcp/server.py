#!/usr/bin/env python3
"""Stdio MCP server: triage_trace (DeepSeek V4.1 Flash), generate_patch (DeepSeek V4.1 Flash), optional .agents persona."""
# Feras's two-tier debug workflow (2026-10-24): Claude passes repo paths, the server reads the files, so code and logs
# never enter Claude's context. Needs CLOUDFLARE_ACCOUNT_ID and CLOUDFLARE_API_TOKEN (Workers AI permission) in the
# environment or the Windows user environment; Feras sets them, Claude never reads them. Standard library only.
# Spend: one row per call in ../game-wt/cf_spend.csv (date, tool, prompt tokens, completion tokens, model).
# CF_MCP_DRY=1 returns the request instead of calling Cloudflare (tests: tools/cf_mcp/test_server.py).
import json
import os
import sys
import urllib.error
import urllib.request
from datetime import date
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
MAIN = ROOT.parents[2] if ROOT.parent.name == "worktrees" else ROOT  # a chat worktree sits in <main>/.claude/worktrees
SPEND_LOG = MAIN.parent / "game-wt" / "cf_spend.csv"
API = "https://api.cloudflare.com/client/v4/accounts/{acct}/ai/v1/chat/completions"
MAX_FILE_CHARS = 60000
MODELS = {
    "triage_trace": "@cf/deepseek-ai/deepseek-v4.1-flash-1017",
    "generate_patch": "@cf/deepseek-ai/deepseek-v4.1-flash-1017",
}
EFFORT = {"generate_patch": "none"}  # a patch from a written diagnosis needs no reasoning (Feras 10-31, routing OK)
SYSTEM = {
    "triage_trace": (
        "You triage bugs in a Godot 4.7 typed-GDScript game. Given an error trace or a bug report and code, find the "
        "root cause. Answer in at most 15 lines: ROOT CAUSE (one sentence, file:line), WHY (the broken invariant), "
        "FIX SPEC (the smallest change, numbered), TEST (one test that fails before and passes after). No code blocks."
    ),
    "generate_patch": (
        "You write patches for a Godot 4.7 typed-GDScript game. Rules: static typing everywhere, no node lookups by "
        "path, no gameplay numbers in code (they live in content JSON), player text as localization keys, logic/ "
        "folders pure, files <= 200 lines, functions <= 40 lines, tabs for indentation. Reply with ONE unified diff "
        "(diff -u, paths a/<repo path> b/<repo path>) that applies with `git apply`, including the test, then at most "
        "5 lines explaining why it satisfies the broken invariant. Nothing else."
    ),
}
TOOLS = [
    {
        "name": "triage_trace",
        "description": "Tier 1 (DeepSeek V4.1 Flash): root-cause an error trace or bug report. Pass repo paths in `files` "
                       "(the server reads them) instead of pasting code.",
        "inputSchema": {"type": "object", "required": ["trace"], "properties": {
            "trace": {"type": "string", "description": "Error trace, failing test output or bug report."},
            "files": {"type": "array", "items": {"type": "string"}, "description": "Repo-relative paths to include."},
            "context": {"type": "string", "description": "Extra notes (design rules, what was already ruled out)."},
            "agent": {"type": "string", "description": "Optional persona: a .agents/skills/<name> (e.g. "
                      "godot-gameplay-scripter, minimal-change-engineer); its SKILL.md leads the system prompt."},
        }},
    },
    {
        "name": "generate_patch",
        "description": "Tier 2 (DeepSeek V4.1 Flash): unified diff from a triage diagnosis. Pass repo paths in `files`.",
        "inputSchema": {"type": "object", "required": ["diagnosis", "files"], "properties": {
            "diagnosis": {"type": "string", "description": "The triage result to implement."},
            "files": {"type": "array", "items": {"type": "string"}, "description": "Repo-relative paths to patch."},
            "tests": {"type": "string", "description": "Failing tests or the test to add."},
            "agent": {"type": "string", "description": "Optional persona: a .agents/skills/<name> (e.g. "
                      "godot-gameplay-scripter, minimal-change-engineer); its SKILL.md leads the system prompt."},
        }},
    },
]


def _env(name: str) -> str:
    value = os.environ.get(name, "")
    if value or os.name != "nt":
        return value
    import winreg
    try:
        with winreg.OpenKey(winreg.HKEY_CURRENT_USER, "Environment") as key:
            return str(winreg.QueryValueEx(key, name)[0])
    except OSError:
        return ""


def _read_files(paths: list) -> str:
    parts = []
    for rel in paths:
        path = (ROOT / rel).resolve()
        if ROOT not in path.parents or not path.is_file():
            parts.append(f"=== {rel}: not a file inside the repo ===")
            continue
        text = path.read_text(encoding="utf-8", errors="replace")[:MAX_FILE_CHARS]
        numbered = "\n".join(f"{i + 1}\t{line}" for i, line in enumerate(text.split("\n")))
        parts.append(f"=== {rel} ===\n{numbered}")
    return "\n\n".join(parts)


def _system(tool: str, agent: str) -> str:
    """The persona (an .agents/skills SKILL.md without its frontmatter) first; the tool's rules last, so they win."""
    path = ROOT / ".agents" / "skills" / agent / "SKILL.md"
    if not agent or not agent.replace("-", "").isalnum() or not path.is_file():
        return SYSTEM[tool]
    body = path.read_text(encoding="utf-8").split("\n---\n", 1)[-1].strip()[:MAX_FILE_CHARS]
    return f"{body}\n\n## Rules for this answer (they win over the persona above)\n{SYSTEM[tool]}"


def _user_message(tool: str, args: dict) -> str:
    files = _read_files(args.get("files", []))
    if tool == "triage_trace":
        return f"TRACE / BUG:\n{args.get('trace', '')}\n\nCONTEXT:\n{args.get('context', '')}\n\nCODE:\n{files}"
    return f"DIAGNOSIS:\n{args.get('diagnosis', '')}\n\nTESTS:\n{args.get('tests', '')}\n\nCODE:\n{files}"


def _log_spend(tool: str, usage: dict) -> None:
    try:
        with SPEND_LOG.open("a", encoding="utf-8", newline="\n") as f:
            f.write(f"{date.today()},{tool},{usage.get('prompt_tokens', '')},"
                    f"{usage.get('completion_tokens', '')},{MODELS[tool]}\n")
    except OSError:
        pass


def call_model(tool: str, args: dict) -> str:
    body = {"model": MODELS[tool], "messages": [
        {"role": "system", "content": _system(tool, str(args.get("agent", "")))},
        {"role": "user", "content": _user_message(tool, args)},
    ]}
    if tool in EFFORT:
        body["reasoning_effort"] = EFFORT[tool]
    if os.environ.get("CF_MCP_DRY") == "1":
        return json.dumps(body)
    acct, token = _env("CLOUDFLARE_ACCOUNT_ID"), _env("CLOUDFLARE_API_TOKEN")
    if not acct or not token:
        return "ERROR: set CLOUDFLARE_ACCOUNT_ID and CLOUDFLARE_API_TOKEN (Workers AI permission), then restart."
    req = urllib.request.Request(API.format(acct=acct), data=json.dumps(body).encode(), method="POST",
                                 headers={"Authorization": f"Bearer {token}", "Content-Type": "application/json"})
    try:
        with urllib.request.urlopen(req, timeout=600) as resp:
            data = json.loads(resp.read())
    except urllib.error.HTTPError as e:
        return f"ERROR: Cloudflare HTTP {e.code}: {e.read()[:400].decode(errors='replace')}"
    except (urllib.error.URLError, TimeoutError) as e:
        return f"ERROR: {e}"
    _log_spend(tool, data.get("usage", {}))
    return data["choices"][0]["message"]["content"]


def handle(msg: dict):
    method, mid = msg.get("method"), msg.get("id")
    if method == "initialize":
        result = {"protocolVersion": msg.get("params", {}).get("protocolVersion", "2025-06-18"),
                  "capabilities": {"tools": {}}, "serverInfo": {"name": "cf-agents", "version": "1.0"}}
    elif method == "tools/list":
        result = {"tools": TOOLS}
    elif method == "tools/call":
        name = msg["params"]["name"]
        if name not in MODELS:
            return {"jsonrpc": "2.0", "id": mid, "error": {"code": -32602, "message": f"unknown tool {name}"}}
        text = call_model(name, msg["params"].get("arguments", {}))
        result = {"content": [{"type": "text", "text": text}], "isError": text.startswith("ERROR:")}
    elif method == "ping":
        result = {}
    elif mid is None:
        return None  # a notification (e.g. notifications/initialized)
    else:
        return {"jsonrpc": "2.0", "id": mid, "error": {"code": -32601, "message": f"no method {method}"}}
    return {"jsonrpc": "2.0", "id": mid, "result": result}


def main() -> None:
    for line in sys.stdin:
        if not line.strip():
            continue
        reply = handle(json.loads(line))
        if reply is not None:
            sys.stdout.write(json.dumps(reply) + "\n")
            sys.stdout.flush()


if __name__ == "__main__":
    main()
