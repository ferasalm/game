#!/usr/bin/env python3
"""PreToolUse hook on Bash (LESSONS 4, broken again 10-29: 4 calls lost): the Bash tool collapses every doubled
backslash to one, anywhere in a command, even in single quotes or a quoted heredoc (probed 10-31; \\n, \\" and \\$ stay
intact). Blocks any command holding a doubled backslash, and any python heredoc holding a backslash at all, since its
source then mixes that with Python's own escapes. Claude writes such a script with Write, then runs the file. Any other
command, tool, bad JSON or error exits 0. Test: tools/test_hook_heredoc.py.
"""
import json
import re
import sys

DELIM = r"<<(-?)\s*(['\"]?)([\w.-]+)\2"
EXE = r"\bpython3?(?:\.exe)?[\"']?"
HEADS = (re.compile(EXE + r"(?:\s+-X\s*\S+|\s+-\w+)*(?:\s+-(?:\s+[^\s<]+)*)?\s*" + DELIM),
         re.compile(r"(?<!<)" + DELIM + r"[^|\n]*\|\s*(?:\S*/)?" + EXE[2:] + r"(?:\s+-\w*)*\s*$"))
MSG = ("BLOCKED (heredoc_guard, LESSONS 4): the Bash tool turns a doubled backslash into one, anywhere in a command, "
       "and a python heredoc holding a backslash mixes that with Python's own escapes. Write the script or text to a "
       "file with Write (scratchpad, or tools/ with a test if worth rerunning), then run or read that file.")


def bodies(command):
    """The body of each python heredoc in the command (to its delimiter line, else to the end)."""
    lines = command.splitlines()
    for i, line in enumerate(lines):
        m = HEADS[0].search(line) or HEADS[1].search(line)
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
    if "\\\\" in command or any("\\" in body for body in bodies(command)):
        print(MSG, file=sys.stderr)
        return 2
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except Exception:
        sys.exit(0)
