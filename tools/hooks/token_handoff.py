#!/usr/bin/env python3
"""PostToolUse hook (D4): warns at 80k work tokens, then at 100k and every +10k after, so a chat hands off in time.

Never blocks: exit 0 on bad JSON, a missing transcript or any error. State is one JSON file per session in
TOKEN_HANDOFF_STATE_DIR (default tempfile.gettempdir()/claude_token_handoff); parsing is throttled by
TOKEN_HANDOFF_STEP_BYTES of transcript growth.
"""
import json
import os
import sys
import tempfile

STEP_DEFAULT = 40000
WINDOW = 512 * 1024
STATE_DIR = os.environ.get("TOKEN_HANDOFF_STATE_DIR") or os.path.join(tempfile.gettempdir(), "claude_token_handoff")
try:
    TOKEN_HANDOFF_STEP_BYTES = int(os.environ.get("TOKEN_HANDOFF_STEP_BYTES", STEP_DEFAULT))
except ValueError:
    TOKEN_HANDOFF_STEP_BYTES = STEP_DEFAULT


def total(line):
    u = (line.get("message") or {}).get("usage") or {}
    return (u.get("input_tokens", 0) + u.get("cache_read_input_tokens", 0)
            + u.get("cache_creation_input_tokens", 0))


def is_usage(line):
    return (line.get("type") == "assistant" and not line.get("isSidechain")
            and isinstance((line.get("message") or {}).get("usage"), dict))


def is_boundary(line):
    return line.get("type") == "system" and line.get("subtype") == "compact_boundary"


def parse_lines(text):
    entries = []
    for ln in text.splitlines():
        try:
            entries.append(json.loads(ln))
        except ValueError:
            continue
    return entries


def read_window(path, size):
    with open(path, "rb") as f:
        if size > WINDOW:
            f.seek(size - WINDOW)
            return f.read().decode("utf-8", "replace").splitlines()[1:]  # drop the partial first line
        return f.read().decode("utf-8", "replace").splitlines()


def state_path(session_id):
    return os.path.join(STATE_DIR, (session_id or "default") + ".json")


def load_state(path):
    try:
        with open(path, encoding="utf-8") as f:
            return json.load(f)
    except (OSError, ValueError):
        return None


def save_state(path, state):
    try:
        os.makedirs(STATE_DIR, exist_ok=True)
        with open(path, "w", encoding="utf-8") as f:
            json.dump(state, f)
    except OSError:
        pass


def fallback_work(path):
    try:
        with open(path, "rb") as f:
            raw = f.read()
    except OSError:
        return 0.0
    n = 0
    for ln in raw.splitlines():
        try:
            e = json.loads(ln.decode("utf-8", "replace"))
        except ValueError:
            continue
        if e.get("type") in ("user", "assistant"):
            n += len(ln) + 1
    return n / 5.7


def main():
    data = json.load(sys.stdin)
    path = data.get("transcript_path")
    sp = state_path(data.get("session_id"))
    state = load_state(sp)
    try:
        size = os.path.getsize(path)
    except (OSError, TypeError):
        return 0
    if state and size >= state.get("size", 0) and size - state["size"] < TOKEN_HANDOFF_STEP_BYTES:
        return 0

    if state is None:
        try:
            with open(path, encoding="utf-8", errors="replace") as f:
                entries = parse_lines(f.read())
        except (OSError, TypeError):
            return 0
    else:
        try:
            entries = parse_lines("\n".join(read_window(path, size)))
        except (OSError, TypeError):
            return 0

    baseline = state.get("baseline") if state else None
    warned = state.get("warned", 0) if state else 0
    boundary = None
    for i, e in enumerate(entries):
        if is_boundary(e):
            boundary = i
    if boundary is not None:
        baseline, warned = None, 0
        entries = entries[boundary + 1:]

    usages = [total(e) for e in entries if is_usage(e)]
    if usages:
        if baseline is None:
            baseline = usages[0]
        work = usages[-1] - baseline
    else:
        work = fallback_work(path)

    msg = None
    if work >= 100000:
        threshold = int(work // 10000) * 10000
        if threshold > warned:
            msg = f"Work tokens ~{int(work) // 1000}k (D4): stop at the end of this step and /handoff."
            warned = threshold
    elif work >= 80000 and warned == 0:
        msg = f"Work tokens ~{int(work) // 1000}k (D4): finish the unit, then /handoff."
        warned = 80000

    save_state(sp, {"size": size, "baseline": baseline, "warned": warned})
    if msg:
        print(json.dumps({"hookSpecificOutput": {"hookEventName": "PostToolUse", "additionalContext": msg}}))
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except Exception:
        sys.exit(0)
