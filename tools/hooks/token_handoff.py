#!/usr/bin/env python3
"""PostToolUse hook: tells a chat its cumulative cache reads (cost = calls x context, row 16 10-29) at 25M tokens, then
every +10M (Feras 10-30: information, not a wrap-up order). Context size never warns: the 200k/250k hand-off band is
retired (Feras 10-31, "hitting 200k is not an excuse to stop working"), a chat finishes its task. Reads incrementally
from a byte offset, one API call counted once (its content blocks share a message id). Never blocks: exit 0 on bad JSON,
a missing transcript or any error. State is one JSON file per session in TOKEN_HANDOFF_STATE_DIR (default
tempfile.gettempdir()/claude_token_handoff); parsing is throttled by TOKEN_HANDOFF_STEP_BYTES of growth.
"""
import json
import os
import sys
import tempfile

STEP_DEFAULT = 40000
READS = 25_000_000
READS_REPEAT = 10_000_000
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
        return state if isinstance(state, dict) else {}
    except (OSError, ValueError):
        return {}


def save_state(path, state):
    try:
        os.makedirs(STATE_DIR, exist_ok=True)
        with open(path, "w", encoding="utf-8") as f:
            json.dump(state, f)
    except OSError:
        pass


def new_reads(path, size, state):
    """(the running cache-read sum, the byte offset read to, the last message id) after the whole lines added since
    the last call; a shrunk file starts over."""
    off, total, last = state.get("read_off", 0), state.get("reads", 0), state.get("last_id")
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
        r = e["message"]["usage"].get("cache_read_input_tokens")
        total += r if isinstance(r, int) else 0
    return total, off + end, last


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
    total, read_off, last_id = new_reads(path, size, state)
    rmsg, rwarned = reads_message(total, state.get("reads_warned", 0) if state.get("read_off", 0) <= size else 0)
    save_state(sp, {"size": size, "read_off": read_off, "reads": total, "last_id": last_id, "reads_warned": rwarned})
    if rmsg:
        print(json.dumps({"hookSpecificOutput": {"hookEventName": "PostToolUse", "additionalContext": rmsg}}))
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except Exception:
        sys.exit(0)
