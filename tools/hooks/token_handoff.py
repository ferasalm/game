#!/usr/bin/env python3
"""PostToolUse hook (hand-off rule, Feras 10-28): warns when this chat's context passes 200k ("finish the unit"),
then at 250k and every +25k after ("hand off at the next unit boundary"), so a chat hands off in time. It also warns
when the chat's cumulative cache reads (cost = calls x context, row 16 10-29) pass 25M tokens, then every +10M (Feras 10-30: information, not a wrap-up order): read
incrementally from a byte offset, one API call counted once (its content blocks share a message id).

Context = the main model's last call (input + cache read + cache write). An advisor turn's top-level usage also sums
the advisor's own call (271k for a 137k chat, 10-28): its last "message" iteration is read instead. A compaction
shrinks the context, so the warnings start over. get_usage wins when it disagrees (CLAUDE.md). Never blocks: exit 0
on bad JSON, a missing transcript or any error. State is one JSON file per session in TOKEN_HANDOFF_STATE_DIR
(default tempfile.gettempdir()/claude_token_handoff); parsing is throttled by TOKEN_HANDOFF_STEP_BYTES of growth.
"""
import json
import os
import sys
import tempfile

STEP_DEFAULT = 40000
WINDOW = 512 * 1024
FINISH = 200000
HANDOFF = 250000
REPEAT = 25000
READS = 25_000_000
READS_REPEAT = 10_000_000
TAIL = " If get_usage shows another context size, trust get_usage and log the mismatch."
STATE_DIR = os.environ.get("TOKEN_HANDOFF_STATE_DIR") or os.path.join(tempfile.gettempdir(), "claude_token_handoff")
try:
    TOKEN_HANDOFF_STEP_BYTES = int(os.environ.get("TOKEN_HANDOFF_STEP_BYTES", STEP_DEFAULT))
except ValueError:
    TOKEN_HANDOFF_STEP_BYTES = STEP_DEFAULT


def call_size(u):
    return sum(u.get(k) if isinstance(u.get(k), int) else 0
               for k in ("input_tokens", "cache_read_input_tokens", "cache_creation_input_tokens"))


def context(line):
    """The main model's context on this line's last call (an advisor turn sums every iteration at the top level)."""
    u = line["message"]["usage"]
    its = [i for i in u.get("iterations") or [] if isinstance(i, dict) and i.get("type") == "message"]
    return call_size(its[-1]) if its else call_size(u)


def is_usage(line):
    msg = line.get("message")
    return (line.get("type") == "assistant" and not line.get("isSidechain")
            and isinstance(msg, dict) and isinstance(msg.get("usage"), dict))


def is_boundary(line):
    return line.get("type") == "system" and line.get("subtype") == "compact_boundary"


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


def fallback_tokens(path):
    """No usage line since the last compaction: estimate from the text written since it."""
    try:
        with open(path, "rb") as f:
            raw = f.read()
    except OSError:
        return 0.0
    n = 0
    for ln in raw.splitlines():
        e = parse_lines(ln.decode("utf-8", "replace"))
        if not e:
            continue
        if is_boundary(e[0]):
            n = 0  # only the text since the last compaction is in the window
        elif e[0].get("type") in ("user", "assistant"):
            n += len(ln) + 1
    return n / 5.7


def measure(entries, path):
    """Context tokens now: the last main-thread usage after the last compaction, else the fallback estimate."""
    last = None
    for e in entries:
        if is_boundary(e):
            last = None
        elif is_usage(e):
            last = e
    return context(last) if last is not None else fallback_tokens(path)


def message(ctx, warned):
    """(text or None, the warned level to keep). Below FINISH (also after a compaction) the levels start over."""
    if ctx < FINISH:
        return None, 0
    k = int(ctx) // 1000
    if ctx < HANDOFF:
        if warned:
            return None, warned
        return f"Context ~{k}k (hand-off rule): finish the unit you are in, then keep working; /handoff comes at 250k.{TAIL}", FINISH
    level = HANDOFF + int((ctx - HANDOFF) // REPEAT) * REPEAT
    if level <= warned:
        return None, warned
    return (f"Context ~{k}k (hand-off band 200-300k, Feras 10-29): /handoff at the next unit boundary; finishing the "
            f"unit you are in up to ~300k is fine, never stop mid-unit.{TAIL}", level)


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
            "a fresh chat. The context band (200k/250k) decides the hand-off.", level)


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
    try:
        if state:
            entries = parse_lines("\n".join(read_window(path, size)))
        else:
            with open(path, encoding="utf-8", errors="replace") as f:
                entries = parse_lines(f.read())
    except (OSError, TypeError):
        return 0
    msg, warned = message(measure(entries, path), state.get("warned", 0))
    total, read_off, last_id = new_reads(path, size, state)
    rmsg, rwarned = reads_message(total, state.get("reads_warned", 0) if state.get("read_off", 0) <= size else 0)
    save_state(sp, {"size": size, "warned": warned, "read_off": read_off, "reads": total, "last_id": last_id,
                    "reads_warned": rwarned})
    text = " ".join(m for m in (msg, rmsg) if m)
    if text:
        print(json.dumps({"hookSpecificOutput": {"hookEventName": "PostToolUse", "additionalContext": text}}))
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except Exception:
        sys.exit(0)
