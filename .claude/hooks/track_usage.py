"""PostToolUse hook for the kaizen coach: appends Bash/Edit/Write/Agent/Skill calls to ~/.claude/coach-usage-log.jsonl.

Python port of the coach's track-usage.sh (that one needs jq, which is not installed here). Local only, never fails a tool call.
"""
import json
import sys
import time
from pathlib import Path

LOG = Path.home() / ".claude" / "coach-usage-log.jsonl"
MAX_LINES = 8000
KEEP_LINES = 6000


def main() -> None:
    data = json.load(sys.stdin)
    tool = data.get("tool_name", "unknown")
    if tool not in ("Bash", "Edit", "Write", "Agent", "Skill"):
        return
    inp = data.get("tool_input") or {}
    detail = {"Bash": inp.get("command"), "Skill": inp.get("skill"), "Agent": inp.get("description"),
              "Edit": inp.get("file_path"), "Write": inp.get("file_path")}.get(tool) or ""
    row = {
        "ts": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
        "tool": tool,
        "detail": detail.replace("\n", " ")[:100],
        "project": data.get("cwd", ""),
        "session": data.get("session_id", "unknown"),
    }
    with LOG.open("a", encoding="utf-8", newline="\n") as f:
        f.write(json.dumps(row) + "\n")
    lines = LOG.read_text(encoding="utf-8").splitlines()
    if len(lines) > MAX_LINES:
        LOG.write_text("\n".join(lines[-KEEP_LINES:]) + "\n", encoding="utf-8", newline="\n")


try:
    main()
except Exception:
    pass
