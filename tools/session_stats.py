#!/usr/bin/env python
"""Per-day quality signals from Claude Code transcripts (ops-review, kaizen coach): tool calls, failed calls, calls per
user turn, largest context, model. Prints a table only; reads no secrets into the output.
Usage: python tools/session_stats.py [--days 14] [--dir <project transcript dir>]"""
import argparse
import collections
import json
import re
import time
from pathlib import Path

DEFAULT_DIRS = Path.home() / ".claude" / "projects"  # the main checkout's chats and one folder per worktree
PREFIX = "C--dev-game"
GUARD = re.compile(r"refus|denied|rejected|blocked|isolated in the worktree|user doesn't want|hook", re.I)  # a guard, not a slip


def blank() -> dict:
    return {"chats": 0, "calls": 0, "errors": 0, "guards": 0, "turns": 0, "peak": 0, "over200k": 0,
            "models": collections.Counter()}


def is_user_turn(event: dict) -> bool:
    content = (event.get("message") or {}).get("content")
    if isinstance(content, str):
        return not content.startswith("<")
    return isinstance(content, list) and any(c.get("type") == "text" for c in content if isinstance(c, dict))


def fold(lines, day: dict) -> None:
    """Adds one transcript's events to its day's totals."""
    peak = 0
    for line in lines:
        try:
            event = json.loads(line)
        except ValueError:
            continue
        message = event.get("message") or {}
        kind = event.get("type")
        if kind == "assistant":
            usage = message.get("usage") or {}
            peak = max(peak, usage.get("input_tokens", 0) + usage.get("cache_read_input_tokens", 0)
                       + usage.get("cache_creation_input_tokens", 0))
            if message.get("model"):
                day["models"][message["model"]] += 1
            content = message.get("content")
            day["calls"] += sum(1 for c in content if c.get("type") == "tool_use") if isinstance(content, list) else 0
        elif kind == "user":
            content = message.get("content")
            for c in content if isinstance(content, list) else []:
                if isinstance(c, dict) and c.get("is_error"):
                    day["errors"] += 1
                    day["guards"] += 1 if GUARD.search(str(c.get("content"))[:600]) else 0
            day["turns"] += 1 if is_user_turn(event) else 0
    day["chats"] += 1
    day["peak"] = max(day["peak"], peak)
    day["over200k"] += 1 if peak > 200000 else 0


def rows(days: dict) -> list:
    out = []
    for date in sorted(days):
        d = days[date]
        slips = d["errors"] - d["guards"]
        rate = 100 * slips / d["calls"] if d["calls"] else 0
        per_turn = d["calls"] / d["turns"] if d["turns"] else 0
        model = d["models"].most_common(1)[0][0] if d["models"] else "-"
        out.append(f"{date} chats {d['chats']:3} calls {d['calls']:5} slips {slips:4} ({rate:4.1f}%) guards {d['guards']:3} "
                   f"calls/turn {per_turn:5.1f} peak {d['peak'] // 1000:4}k over200k {d['over200k']:2} {model}")
    return out


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--days", type=int, default=14)
    ap.add_argument("--dir", default=str(DEFAULT_DIRS))
    a = ap.parse_args()
    cutoff = time.time() - a.days * 86400
    days: dict = collections.defaultdict(blank)
    for path in Path(a.dir).glob(PREFIX + "*/*.jsonl"):
        mtime = path.stat().st_mtime
        if mtime < cutoff:
            continue
        with path.open(encoding="utf-8", errors="replace") as f:
            fold(f, days[time.strftime("%Y-%m-%d", time.localtime(mtime))])
    print("\n".join(rows(days)) or "no transcripts")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
