#!/usr/bin/env python
"""cf_probe stream: a broken `data:` line is skipped and counted, never a crash; both good events survive."""
import contextlib
import io
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import cf_probe  # noqa: E402


def sse(obj: dict) -> bytes:
    return ("data: " + json.dumps(obj) + "\n").encode()


def fake_clock(step: float = 1.0):
    now = [0.0]

    def tick() -> float:
        now[0] += step
        return now[0]
    return tick


def test_a_broken_line_is_skipped_and_counted():
    lines = [sse({"choices": [{"delta": {"content": "ab"}}]}), b"data: {broken\n",
             sse({"choices": [{"delta": {"content": "cd"}, "finish_reason": "stop"}]})]
    r = cf_probe.read_stream(lines, fake_clock())
    assert r["text"] == "abcd", r
    assert r["bad_lines"] == 1, r
    buf = io.StringIO()
    with contextlib.redirect_stdout(buf):
        print(json.dumps(cf_probe.summary("m", "", r)))
    assert '"bad_lines": 1' in buf.getvalue(), buf.getvalue()


if __name__ == "__main__":
    tests = [v for k, v in sorted(globals().items()) if k.startswith("test_")]
    for t in tests:
        t()
    print(f"test_cf_probe_stream: {len(tests)} tests passed")
