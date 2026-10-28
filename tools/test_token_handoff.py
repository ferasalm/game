#!/usr/bin/env python3
"""Self-test for tools/hooks/token_handoff.py (D4): a PostToolUse hook that warns at 80k and 100k work tokens.

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


def test_quiet_below_80k():
    s = Session()
    write(s.path, [user_line(), usage_line(90_000), usage_line(160_000)])
    assert s.call() == "", "70k work tokens: no warning"


def test_warns_at_80k_once():
    s = Session()
    write(s.path, [user_line(), usage_line(90_000), usage_line(171_000)])
    msg = s.call()
    assert "finish the unit" in msg and "81" in msg, msg
    write(s.path, [usage_line(175_000)], "a")
    assert s.call() == "", "the 80k warning fires once"


def test_warns_at_100k_then_every_10k():
    s = Session()
    write(s.path, [user_line(), usage_line(90_000), usage_line(191_000)])
    assert "/handoff" in s.call()
    write(s.path, [usage_line(195_000)], "a")
    assert s.call() == "", "no repeat before +10k"
    write(s.path, [usage_line(202_000)], "a")
    assert "/handoff" in s.call(), "again at +10k"


def test_sidechain_usage_is_ignored():
    s = Session()
    write(s.path, [user_line(), usage_line(90_000), usage_line(160_000), usage_line(400_000, sidechain=True)])
    assert s.call() == "", "a subagent's usage line is not this chat's context"


def test_baseline_restarts_after_compaction():
    s = Session()
    write(s.path, [user_line(), usage_line(20_000), usage_line(185_000), COMPACT, user_line("summary"),
                   usage_line(110_000), usage_line(140_000)])
    assert s.call() == "", "after a compact boundary the work counts from the first usage after it (30k)"


def test_compaction_seen_on_a_later_call():
    s = Session()
    write(s.path, [user_line(), usage_line(90_000), usage_line(150_000)])
    assert s.call() == ""
    write(s.path, [COMPACT, user_line("summary"), usage_line(110_000), usage_line(170_000)], "a")
    assert s.call() == "", "60k since the compaction: still quiet, not 80k from the old baseline"


def test_compaction_in_the_window_resets_once():  # review 10-28: each parse re-found it and warned again
    s = Session()
    write(s.path, [user_line(), usage_line(20_000), usage_line(185_000), dict(COMPACT, uuid="c1"), user_line("s"),
                   usage_line(110_000), usage_line(200_000)])
    assert "finish the unit" in s.call(), "90k since the compaction"
    write(s.path, [usage_line(201_000)], "a")
    assert s.call() == "", "the same compaction is still in the window: no second 80k warning"
    write(s.path, [usage_line(215_000)], "a")
    assert "/handoff" in s.call()
    write(s.path, [usage_line(216_000)], "a")
    assert s.call() == ""


def test_fallback_counts_only_after_compaction():  # review 10-28: the fallback read the whole file
    s = Session()
    write(s.path, [user_line("a" * 600_000), dict(COMPACT, uuid="c1"), user_line("go")])
    assert s.call() == "", "no usage since the compaction and a few bytes: quiet"


def test_throttle_skips_small_growth():
    s = Session(step_bytes="40000")
    write(s.path, [user_line(), usage_line(90_000), usage_line(100_000)])
    assert s.call() == ""
    write(s.path, [usage_line(195_000)], "a")
    assert s.call() == "", "under 40 KB of growth since the last parse: not parsed yet"
    write(s.path, [user_line("p" * 41_000), usage_line(196_000)], "a")
    assert "/handoff" in s.call(), "after 40 KB the hook parses and warns"


def test_fallback_without_usage_counts_bytes():
    s = Session()
    write(s.path, [user_line("a" * 300_000), {"type": "assistant", "isSidechain": False,
                                             "message": {"role": "assistant", "content": "b" * 300_000}}])
    assert "/handoff" in s.call(), "~600 KB / 5.7 = ~105k tokens: warn even with no usage lines"


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
