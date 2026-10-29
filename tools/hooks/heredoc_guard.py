#!/usr/bin/env python3
"""PreToolUse hook on Bash (LESSONS 4, broken again 10-29: 4 calls lost): blocks a `python - <<DELIM` heredoc whose
body holds a backslash, since it reaches Python altered (a backslash-n arrives as a real newline, backslash-b as a
backspace). Claude writes such a script with Write, then runs the file. Any other command, tool, bad JSON or error
exits 0. Test: tools/test_hook_heredoc.py.
"""
import json
import re
import sys

HEAD = re.compile(r"\bpython3?(?:\.exe)?\s+-\s*<<(-?)\s*(['\"]?)(\w+)\2")
MSG = ("BLOCKED (heredoc_guard, LESSONS 4): this python heredoc holds a backslash, which reaches Python altered "
       "(a backslash-n turns into a newline). Write the script to a file with Write (scratchpad, or tools/ with a "
       "test if worth rerunning), then run python <file>.")


def bodies(command):
    """The body of each python heredoc in the command (to its delimiter line, else to the end)."""
    lines = command.splitlines()
    for i, line in enumerate(lines):
        m = HEAD.search(line)
        if not m:
            continue
        body = []
        for nxt in lines[i + 1:]:
            if (nxt.lstrip("\t") if m.group(1) else nxt).rstrip() == m.group(3):
                break
            body.append(nxt)
        yield "\n".join(body)


def main():
    data = json.load(sys.stdin)
    if data.get("tool_name") != "Bash":
        return 0
    command = (data.get("tool_input") or {}).get("command") or ""
    if any("\\" in body for body in bodies(command)):
        print(MSG, file=sys.stderr)
        return 2
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except Exception:
        sys.exit(0)
