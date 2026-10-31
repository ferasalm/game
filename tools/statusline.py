#!/usr/bin/env python3
"""Status line command (row 23 e, 2026-11-01): reads Claude Code's status JSON on stdin, prints one line
`model | ctx N% | 5h N% (resets HH:MM) | 7d N%`, and writes <project>/.check/usage.json (read by token_handoff and /handoff)
plus .check/statusline_raw.json (the last raw payload, to confirm field names). Field names: official statusline docs
(rate_limits.five_hour|seven_day.used_percentage 0-100 and resets_at epoch seconds, only for Pro/Max after the first reply).
Never raises: bad input prints a short line and exits 0.
Wiring (settings.json): "statusLine": {"type": "command", "command": "python \"$CLAUDE_PROJECT_DIR/tools/statusline.py\""}"""
import json
import os
import sys
import time


def num(obj, *path):
    for key in path:
        obj = obj.get(key) if isinstance(obj, dict) else None
    return obj if isinstance(obj, (int, float)) and not isinstance(obj, bool) else None


def write(root: str, name: str, data: dict) -> None:
    try:
        os.makedirs(os.path.join(root, ".check"), exist_ok=True)
        with open(os.path.join(root, ".check", name), "w", encoding="utf-8", newline="\n") as f:
            json.dump(data, f)
    except OSError:
        pass


def clock(epoch) -> str:
    try:
        return time.strftime("%H:%M", time.localtime(epoch))
    except (OverflowError, OSError, ValueError, TypeError):
        return "?"


def main() -> int:
    try:
        data = json.loads(sys.stdin.read())
    except ValueError:
        data = None
    if not isinstance(data, dict):
        print("statusline: no data")
        return 0
    ws = data.get("workspace") if isinstance(data.get("workspace"), dict) else {}
    root = ws.get("project_dir") or ws.get("current_dir") or data.get("cwd") or os.getcwd()
    five, seven = num(data, "rate_limits", "five_hour", "used_percentage"), num(data, "rate_limits", "seven_day", "used_percentage")
    ctx = num(data, "context_window", "used_percentage")
    usage = {"five_hour_pct": five, "five_hour_resets_at": num(data, "rate_limits", "five_hour", "resets_at"),
             "seven_day_pct": seven, "seven_day_resets_at": num(data, "rate_limits", "seven_day", "resets_at"),
             "context_pct": ctx, "session_id": data.get("session_id"), "updated": time.time()}
    write(root, "usage.json", usage)
    write(root, "statusline_raw.json", data)
    model = (data.get("model") or {}).get("display_name") if isinstance(data.get("model"), dict) else None
    parts = [model or "?"]
    if ctx is not None:
        parts.append(f"ctx {ctx:.0f}%")
    if five is not None:
        reset = usage["five_hour_resets_at"]
        parts.append(f"5h {five:.0f}%" + (f" (resets {clock(reset)})" if reset else ""))
    if seven is not None:
        parts.append(f"7d {seven:.0f}%")
    print(" | ".join(parts))
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except Exception:
        print("statusline: error")
        sys.exit(0)
