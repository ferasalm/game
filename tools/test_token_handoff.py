#!/usr/bin/env python3
"""Self-test for tools/hooks/token_handoff.py (hand-off rule, Feras 10-28): warns at 200k and 250k of context.

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


COMPACT = {"type": "system", "subtype": "compact_boundary", "isSidechain": False, "content": "Conversation compacted"}


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


def test_quiet_below_200k():
    s = Session()
    write(s.path, [user_line(), usage_line(90_000), usage_line(199_000)])
    assert s.call() == ""


def test_finish_the_unit_at_200k_once():
    s = Session()
    write(s.path, [user_line(), usage_line(90_000), usage_line(205_000)])
    msg = s.call()
    assert "finish the unit" in msg and "~205k" in msg and "get_usage" in msg, msg
    assert "/handoff comes at 250k" in msg, "200k is not a stop: a chat read 'then /handoff' as hand off now (10-28)"
    write(s.path, [usage_line(240_000)], "a")
    assert s.call() == "", "the 200k warning fires once"


def test_handoff_at_250k_then_every_25k():
    s = Session()
    write(s.path, [user_line(), usage_line(90_000), usage_line(252_000)])
    assert "/handoff at the next unit boundary" in s.call()
    write(s.path, [usage_line(270_000)], "a")
    assert s.call() == "", "no repeat before +25k"
    write(s.path, [usage_line(276_000)], "a")
    assert "/handoff" in s.call(), "again at 275k"


def test_advisor_turn_counts_the_main_call_only():  # 10-28: the advisor's own call made a 137k chat read as 271k
    s = Session()
    line = usage_line(271_000)
    line["message"]["usage"]["iterations"] = [
        {"type": "message", "input_tokens": 2, "cache_read_input_tokens": 126_980, "cache_creation_input_tokens": 8_035},
        {"type": "advisor_message", "input_tokens": 131_796, "cache_read_input_tokens": 0},
        {"type": "message", "input_tokens": 4, "cache_read_input_tokens": 127_000, "cache_creation_input_tokens": 9_755}]
    write(s.path, [user_line(), usage_line(90_000), line])
    assert s.call() == "", "136,759 tokens of context: quiet"


def test_sidechain_usage_is_ignored():
    s = Session()
    write(s.path, [user_line(), usage_line(90_000), usage_line(160_000), usage_line(400_000, sidechain=True)])
    assert s.call() == "", "a subagent's usage line is not this chat's context"


def test_compaction_starts_the_warnings_over():
    s = Session()
    write(s.path, [user_line(), usage_line(90_000), usage_line(260_000)])
    assert "/handoff" in s.call()
    write(s.path, [dict(COMPACT, uuid="c1"), user_line("summary"), usage_line(110_000)], "a")
    assert s.call() == "", "the compaction shrank the context"
    write(s.path, [usage_line(150_000)], "a")
    assert s.call() == "", "the same compaction is still in the window: quiet, not a repeat"
    write(s.path, [usage_line(206_000)], "a")
    assert "finish the unit" in s.call(), "a new climb past 200k warns again"


def test_compaction_without_usage_after_it_is_quiet():  # the pre-compaction usage must not count
    s = Session()
    write(s.path, [user_line("a" * 600_000), usage_line(300_000), dict(COMPACT, uuid="c1"), user_line("go")])
    assert s.call() == "", "no usage since the compaction and a few bytes: quiet"


def test_throttle_skips_small_growth():
    s = Session(step_bytes="40000")
    write(s.path, [user_line(), usage_line(90_000), usage_line(100_000)])
    assert s.call() == ""
    write(s.path, [usage_line(255_000)], "a")
    assert s.call() == "", "under 40 KB of growth since the last parse: not parsed yet"
    write(s.path, [user_line("p" * 41_000), usage_line(256_000)], "a")
    assert "/handoff" in s.call(), "after 40 KB the hook parses and warns"


def test_fallback_without_usage_counts_bytes():
    s = Session()
    write(s.path, [user_line("a" * 700_000), {"type": "assistant", "isSidechain": False,
                                             "message": {"role": "assistant", "content": "b" * 700_000}}])
    assert "finish the unit" in s.call(), "~1.4 MB / 5.7 = ~245k tokens: warn even with no usage lines"


def test_odd_lines_never_crash():  # calibration 10-28: null usage fields, a string message, a non-dict line
    s = Session()
    odd = usage_line(260_000)
    odd["message"]["usage"]["cache_creation_input_tokens"] = None
    write(s.path, [7, "x", {"type": "assistant", "message": "text"}, user_line(), odd])
    assert "/handoff" in s.call()


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
