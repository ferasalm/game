#!/usr/bin/env python3
"""PreToolUse hook (D21): blocks paid generation tools (exit 2) unless a recent USER message says "spend ok"; reminds before Hyper3D.

Reads the hook JSON on stdin (tool_name, transcript_path). Only real user text counts as Feras's OK: Claude's own
messages and tool results never do. Wiring into settings.json is P3.9.
"""
import json
import re
import sys

PAID = re.compile(r"runware|__generate-(image|speech)$", re.I)
HYPER = re.compile(r"hyper3d__rodin_generate", re.I)
OK = re.compile(r"spend\s+ok", re.I)
RECENT = 8  # the OK must sit in one of the last user messages: it is per job, not for the rest of the session


def user_texts(path):
    out = []
    try:
        lines = open(path, encoding="utf-8").read().splitlines()
    except (OSError, TypeError):
        return out
    for ln in lines:
        try:
            e = json.loads(ln)
        except ValueError:
            continue
        if e.get("type") != "user" or e.get("isSidechain"):
            continue
        c = (e.get("message") or {}).get("content")
        if isinstance(c, str):
            out.append(c)
        elif isinstance(c, list):  # tool_result blocks are skipped: only text blocks are the user's words
            out.append(" ".join(b.get("text", "") for b in c if isinstance(b, dict) and b.get("type") == "text"))
    return out


def main():
    data = json.load(sys.stdin)
    tool = data.get("tool_name", "")
    if PAID.search(tool):
        if any(OK.search(t) for t in user_texts(data.get("transcript_path"))[-RECENT:]):
            return 0
        print(f"BLOCKED {tool}: a paid generation tool. Free routes first (docs/WORKFLOW.md routes table). Name the job and "
              "its cost, then ask Feras; he answers 'spend ok' in chat.", file=sys.stderr)
        return 2
    if HYPER.search(tool):
        msg = "Hyper3D job: name the credit cost to Feras before this call, and use the cheapest settings that do the job."
        print(json.dumps({"hookSpecificOutput": {"hookEventName": "PreToolUse", "additionalContext": msg}}))
    return 0


if __name__ == "__main__":
    sys.exit(main())
