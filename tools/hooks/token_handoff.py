#!/usr/bin/env python3
"""PostToolUse hook: tells a chat its cumulative cache reads (cost = calls x context, row 16 10-29) at 25M tokens, then
every +10M (Feras 10-30: information, not a wrap-up order), and once when its context passes the soft 300k line (Feras
11-05, after row 26 peaked at 619k with 307M cache reads: finish the current step, then /handoff; re-armed when the
context drops below the line, e.g. after a compaction). Reads incrementally
from a byte offset, one API call counted once (its content blocks share a message id). Never blocks: exit 0 on bad JSON,
a missing transcript or any error. State is one JSON file per session in TOKEN_HANDOFF_STATE_DIR (default
tempfile.gettempdir()/claude_token_handoff); parsing is throttled by TOKEN_HANDOFF_STEP_BYTES of growth.
"""
import json
import os
import sys
import tempfile
import time

STEP_DEFAULT = 40000
READS = 25_000_000
READS_REPEAT = 10_000_000
CONTEXT_SOFT = 300_000
STATE_DIR = os.environ.get("TOKEN_HANDOFF_STATE_DIR") or os.path.join(tempfile.gettempdir(), "claude_token_handoff")
try:
    TOKEN_HANDOFF_STEP_BYTES = int(os.environ.get("TOKEN_HANDOFF_STEP_BYTES", STEP_DEFAULT))
except ValueError:
    TOKEN_HANDOFF_STEP_BYTES = STEP_DEFAULT


def is_usage(line):
    msg = line.get("message")
    return (line.get("type") == "assistant" and not line.get("isSidechain")
            and isinstance(msg, dict) and isinstance(msg.get("usage"), dict))


def parse_lines(text):
    entries = []
    for ln in text.splitlines():
        try:
            e = json.loads(ln)
        except ValueError:
            continue
        if isinstance(e, dict):
            entries.append(e)
    return entries


def state_path(session_id):
    return os.path.join(STATE_DIR, (session_id or "default") + ".json")


def load_state(path):
    try:
        with open(path, encoding="utf-8") as f:
            state = json.load(f)
    except (OSError, ValueError):
        return {}
    if not isinstance(state, dict):
        return {}
    # a hand-edited or half-written field must not silence the hook (a None offset raised TypeError, exit 0, no note)
    clean = {}
    for k, v in state.items():
        if k == "last_id":
            clean[k] = v
        elif k == "ctx_warned":
            if isinstance(v, bool):
                clean[k] = v
        elif isinstance(v, int) and not isinstance(v, bool):
            clean[k] = v
    return clean


def save_state(path, state):
    try:
        os.makedirs(STATE_DIR, exist_ok=True)
        with open(path, "w", encoding="utf-8") as f:
            json.dump(state, f)
    except OSError:
        pass


def new_reads(path, size, state):
    """(the running cache-read sum, the byte offset read to, the last message id, the latest call's context or None)
    after the whole lines added since the last call; a shrunk file starts over."""
    off, total, last, ctx = state.get("read_off", 0), state.get("reads", 0), state.get("last_id"), None
    if not (isinstance(off, int) and 0 <= off <= size):
        off, total, last = 0, 0, None
    with open(path, "rb") as f:
        f.seek(off)
        raw = f.read(size - off)
    end = raw.rfind(b"\n") + 1
    for e in parse_lines(raw[:end].decode("utf-8", "replace")):
        if not is_usage(e):
            continue
        mid = e["message"].get("id")
        if mid is not None and mid == last:
            continue  # one API call is written as one line per content block, each with the same usage
        last = mid
        u = e["message"]["usage"]
        r = u.get("cache_read_input_tokens")
        total += r if isinstance(r, int) else 0
        parts = (u.get("input_tokens"), r, u.get("cache_creation_input_tokens"))
        ctx = sum(p for p in parts if isinstance(p, int))  # what this call sent: the chat's context size
    return total, off + end, last, ctx


def reads_message(total, warned):
    """(text or None, the warned level to keep): at 25M cumulative cache reads, then every +10M."""
    if total < READS:
        return None, warned
    level = READS + int((total - READS) // READS_REPEAT) * READS_REPEAT
    if level <= warned:
        return None, warned
    return (f"Cache reads ~{total / 1e6:.1f}M tokens in this chat (cost = calls x context; information, not a stop): "
            "keep finishing the task at hand at full quality; batch independent calls; a new multi-step task opens "
            "a fresh chat.", level)


def context_message(ctx, warned):
    """(text or None, warned flag to keep): once past CONTEXT_SOFT; re-armed below it."""
    if ctx < CONTEXT_SOFT:
        return None, False
    if warned:
        return None, True
    return (f"Context ~{ctx // 1000}k tokens: past the soft 300k line (Feras 11-05). Finish the current step at full "
            "quality, then /handoff with a paste-ready prompt for the rest; a follow-up of ~10 tool calls or fewer "
            "may stay.", True)


def usage_note(cwd):
    """' 5-hour window N% used.' from .check/usage.json (written by tools/statusline.py) when under an hour old, else ''."""
    try:
        with open(os.path.join(cwd, ".check", "usage.json"), encoding="utf-8") as f:
            u = json.load(f)
        pct = u.get("five_hour_pct")
        if isinstance(pct, (int, float)) and time.time() - u.get("updated", 0) < 3600:
            return f" 5-hour window {pct:.0f}% used."
    except (OSError, ValueError, TypeError, AttributeError):
        pass
    return ""


def main():
    data = json.load(sys.stdin)
    path = data.get("transcript_path")
    sp = state_path(data.get("session_id"))
    state = load_state(sp)
    try:
        size = os.path.getsize(path)
    except (OSError, TypeError):
        return 0
    if state and 0 <= size - state.get("size", 0) < TOKEN_HANDOFF_STEP_BYTES:
        return 0
    total, read_off, last_id, ctx = new_reads(path, size, state)
    same_file = state.get("read_off", 0) <= size
    rmsg, rwarned = reads_message(total, state.get("reads_warned", 0) if same_file else 0)
    if ctx is None:
        ctx = state.get("ctx", 0) if same_file else 0
    cmsg, cwarned = context_message(ctx, bool(state.get("ctx_warned")) and same_file)
    save_state(sp, {"size": size, "read_off": read_off, "reads": total, "last_id": last_id, "reads_warned": rwarned,
                    "ctx": ctx, "ctx_warned": cwarned})
    msg = " ".join(m for m in (cmsg, rmsg) if m)
    if msg:
        msg += usage_note(data.get("cwd"))
        print(json.dumps({"hookSpecificOutput": {"hookEventName": "PostToolUse", "additionalContext": msg}}))
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except Exception:
        sys.exit(0)
