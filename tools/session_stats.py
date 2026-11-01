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
MODEL_NAMES = {
    "claude-sonnet-5-5": "Sonnet 5.5",
    "claude-opus-5-5": "Opus 5.5",
    "claude-haiku-5-5": "Haiku 5.5",
    "claude-fable-5-1": "Fable 5.1",
}


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


def usage_row(path: Path) -> str:
    first_ts = None
    models: collections.Counter = collections.Counter()
    calls = 0
    errors = 0
    cache_reads = 0
    peak = 0
    with path.open(encoding="utf-8", errors="replace") as f:
        for line in f:
            try:
                event = json.loads(line)
            except ValueError:
                continue
            if first_ts is None and event.get("timestamp"):
                first_ts = event["timestamp"]
            kind = event.get("type")
            msg = event.get("message") or {}
            if kind == "assistant":
                usage = msg.get("usage") or {}
                inp = usage.get("input_tokens", 0)
                cr = usage.get("cache_read_input_tokens", 0)
                cc = usage.get("cache_creation_input_tokens", 0)
                peak = max(peak, inp + cr + cc)
                cache_reads += cr
                if msg.get("model"):
                    models[msg["model"]] += 1
                content = msg.get("content")
                if isinstance(content, list):
                    calls += sum(1 for c in content if isinstance(c, dict) and c.get("type") == "tool_use")
            elif kind == "user":
                content = msg.get("content")
                if isinstance(content, list):
                    errors += sum(1 for c in content if isinstance(c, dict) and c.get("is_error"))
    date_str = str(first_ts)[:10] if first_ts else time.strftime("%Y-%m-%d", time.gmtime(path.stat().st_mtime))
    raw_model = models.most_common(1)[0][0] if models else "-"
    model_str = f"{MODEL_NAMES[raw_model]} (`{raw_model}`)" if raw_model in MODEL_NAMES else raw_model
    result = f"calls {calls} ({errors} failed), cache reads {cache_reads:,}, peak context {peak // 1000}k; result: TODO; Kaizen: TODO"
    return f"| {date_str} | {model_str} | TODO | TODO task | TODO | {result} |"


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--days", type=int, default=14)
    ap.add_argument("--dir", default=str(DEFAULT_DIRS))
    ap.add_argument("--row", default="", help="Session id for USAGE row")
    a = ap.parse_args()
    if a.row:
        session = a.row[:-6] if a.row.endswith(".jsonl") else a.row
        matches = list(Path(a.dir).glob(f"*/{session}.jsonl"))
        if not matches:
            matches = list(Path(a.dir).glob(f"**/{session}.jsonl"))
        if not matches:
            print(f"no transcript for {a.row}")
            return 1
        print(usage_row(matches[0]))
        return 0
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
