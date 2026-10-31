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


def test_one_finish_chunk_is_a_cut_stream_two_are_whole():  # the raw tails of both replies, Cloudflare 10-31
    text = sse({"choices": [{"delta": {"content": "alpha"}, "finish_reason": None}]})
    stop = sse({"choices": [{"delta": {}, "finish_reason": "stop"}], "usage": {"completion_tokens": 1}})
    cut = cf_probe.read_stream([text, stop, b"data: [DONE]\n"], fake_clock())
    whole = cf_probe.read_stream([text, stop, stop, b"data: [DONE]\n"], fake_clock())
    assert cf_probe.summary("m", "", cut)["cut"] is True, cut
    assert cf_probe.summary("m", "", whole)["cut"] is False, whole


def test_a_length_stop_is_not_called_cut():  # one finish chunk with finish "length" says itself what happened
    r = cf_probe.read_stream([sse({"choices": [{"delta": {}, "finish_reason": "length"}]})], fake_clock())
    assert cf_probe.was_cut(r) is False, r


if __name__ == "__main__":
    tests = [v for k, v in sorted(globals().items()) if k.startswith("test_")]
    for t in tests:
        t()
    print(f"test_cf_probe_stream: {len(tests)} tests passed")
