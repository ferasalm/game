#!/usr/bin/env python3
"""Self-test for tools/hooks/token_handoff.py: cache-read information at 25M, then every +10M; one note when the context
passes the soft 300k line (Feras 11-05; it replaced 10-31's "context size never warns"), re-armed below the line.

Black box: the hook runs as a subprocess with the hook JSON on stdin. Env: TOKEN_HANDOFF_STATE_DIR (state files),
TOKEN_HANDOFF_STEP_BYTES (throttle; 0 = parse every call).
"""
import json
import os
import subprocess
import sys
import tempfile

HOOK = os.path.join(os.path.dirname(os.path.abspath(__file__)), "hooks", "token_handoff.py")


def usage_line(total, sidechain=False):
    u = {"input_tokens": 10, "cache_read_input_tokens": total - 110, "cache_creation_input_tokens": 100,
         "output_tokens": 50}
    return {"type": "assistant", "isSidechain": sidechain, "message": {"role": "assistant", "usage": u,
                                                                       "content": [{"type": "text", "text": "x"}]}}


def user_line(text="go"):
    return {"type": "user", "isSidechain": False, "message": {"role": "user", "content": text}}


def write(path, entries, mode="w"):
    with open(path, mode, encoding="utf-8", newline="\n") as f:
        for e in entries:
            f.write(json.dumps(e) + "\n")


class Session:
    def __init__(self, step_bytes="0"):
        self.dir = tempfile.mkdtemp()
        self.path = os.path.join(self.dir, "t.jsonl")
        self.state = os.path.join(self.dir, "state")
        self.env = dict(os.environ, TOKEN_HANDOFF_STATE_DIR=self.state, TOKEN_HANDOFF_STEP_BYTES=step_bytes)
        self.sid = "s-" + os.path.basename(self.dir)

    def call(self):
        payload = {"session_id": self.sid, "transcript_path": self.path, "hook_event_name": "PostToolUse",
                   "tool_name": "Bash"}
        r = subprocess.run([sys.executable, HOOK], input=json.dumps(payload), capture_output=True, text=True,
                           env=self.env)
        assert r.returncode == 0, (r.returncode, r.stderr)
        if not r.stdout.strip():
            return ""
        out = json.loads(r.stdout)["hookSpecificOutput"]
        assert out["hookEventName"] == "PostToolUse", out
        return out["additionalContext"]


def test_context_note_once_past_the_soft_300k_line():  # Feras 11-05: finish the step, then /handoff
    s = Session()
    write(s.path, [user_line(), usage_line(90_000)])
    assert s.call() == ""
    for size in (205_000, 299_000):  # 200k and 250k stay quiet: the old band is not back
        write(s.path, [usage_line(size)], "a")
        assert s.call() == "", size
    write(s.path, [usage_line(301_000)], "a")
    note = s.call()
    assert "301k" in note and "300k" in note and "/handoff" in note and "current step" in note, note
    write(s.path, [usage_line(420_000)], "a")
    assert s.call() == ""  # once, not every call


def test_context_note_rearms_after_the_context_drops():  # a compaction shrinks the context: the next crossing tells again
    s = Session()
    write(s.path, [user_line(), usage_line(310_000)])
    assert "/handoff" in s.call()
    write(s.path, [usage_line(120_000)], "a")
    assert s.call() == ""
    write(s.path, [usage_line(305_000)], "a")
    assert "305k" in s.call()


def test_context_note_after_a_shrunk_transcript_and_bad_state():  # a new file starts over; a broken state never silences it
    s = Session()
    write(s.path, [user_line()] * 50 + [usage_line(310_000)])
    assert "/handoff" in s.call()
    write(s.path, [usage_line(320_000)])  # rewritten smaller: offsets and the warned flag start over
    assert "320k" in s.call()
    os.makedirs(s.state, exist_ok=True)
    with open(os.path.join(s.state, s.sid + ".json"), "w", encoding="utf-8") as f:
        json.dump({"read_off": None, "size": None, "ctx_warned": "x"}, f)
    write(s.path, [usage_line(330_000)], "a")
    assert "330k" in s.call()


def test_odd_lines_never_crash():  # calibration 10-28: null usage fields, a string message, a non-dict line
    s = Session()
    odd = usage_line(260_000)
    odd["message"]["usage"]["cache_read_input_tokens"] = None
    write(s.path, [7, "x", {"type": "assistant", "message": "text"}, user_line(), odd])
    assert s.call() == ""


def reads_line(read, mid=None):
    e = usage_line(read + 110)  # cache_read_input_tokens = read
    if mid is not None:
        e["message"]["id"] = mid
    return e


def test_cache_reads_warn_at_25m_then_every_10m():  # row 16 (10-29): cost = calls x context; 25M/10M Feras 10-30
    s = Session()
    write(s.path, [user_line()] + [reads_line(180_000)] * 138)  # 24.8M
    assert s.call() == ""
    write(s.path, [reads_line(180_000)] * 2, "a")  # 25.2M
    msg = s.call()
    assert "Cache reads ~25.2M" in msg and "fresh chat" in msg and "hand-off" not in msg, msg
    assert "not a stop" in msg and "finish the unit" not in msg, ("information, never an early wrap-up", msg)
    write(s.path, [reads_line(180_000)] * 5, "a")  # 26.1M; a re-read from byte 0 would count 51M and warn
    assert s.call() == "", "the offset resumes: lines already counted are not counted again"
    write(s.path, [reads_line(180_000)] * 50, "a")  # 35.1M
    assert "Cache reads ~35.1M" in s.call()


def test_one_api_call_counts_once():  # an API call is one transcript line per content block, same id and usage
    s = Session()
    lines = []
    for i in range(70):
        lines += [reads_line(180_000, f"msg_{i}"), reads_line(180_000, f"msg_{i}")]
    write(s.path, [user_line()] + lines)  # 12.6M counted once; 25.2M (a warning) if every line counted
    assert s.call() == ""


def test_sidechain_reads_are_ignored():
    s = Session()
    write(s.path, [user_line(), usage_line(30_000_000, sidechain=True)])
    assert s.call() == "", "a subagent's reads are not this chat's"


def test_throttle_skips_small_growth():
    s = Session(step_bytes="40000")
    write(s.path, [user_line(), reads_line(180_000)])
    assert s.call() == ""
    write(s.path, [reads_line(180_000)] * 150, "a")  # 27.2M in about 30 KB
    assert s.call() == "", "under 40 KB of growth since the last parse: not parsed yet"
    write(s.path, [user_line("p" * 41_000)], "a")
    assert "Cache reads" in s.call(), "after 40 KB the hook parses and tells"


def test_bad_input_never_blocks():
    for payload in ("not json", json.dumps({"session_id": "x", "transcript_path": "C:/no/such/file.jsonl"})):
        r = subprocess.run([sys.executable, HOOK], input=payload, capture_output=True, text=True,
                           env=dict(os.environ, TOKEN_HANDOFF_STATE_DIR=tempfile.mkdtemp()))
        assert r.returncode == 0, (payload, r.returncode, r.stderr)


if __name__ == "__main__":
    tests = [v for k, v in sorted(globals().items()) if k.startswith("test_")]
    for t in tests:
        t()
    print(f"test_token_handoff: {len(tests)} tests passed")
