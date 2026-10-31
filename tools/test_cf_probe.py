#!/usr/bin/env python
"""cf_probe: the stream folds into the right timings and tokens; effort, extras and an image reach the body."""
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


def test_stream_times_thought_and_text_apart():
    lines = [b": keepalive\n", sse({"choices": [{"delta": {"reasoning_content": "hmm"}}]}),
             sse({"choices": [{"delta": {"content": "ab"}}]}), sse({"choices": [{"delta": {"content": "c"}, "finish_reason": "stop"}]}),
             sse({"choices": [], "usage": {"prompt_tokens": 5, "completion_tokens": 9}}), b"data: [DONE]\n"]
    r = cf_probe.read_stream(lines, fake_clock())
    assert (r["first_thought_s"], r["first_text_s"]) == (1.0, 2.0), r
    assert (r["text"], r["thought_chars"], r["finish"]) == ("abc", 3, "stop"), r
    s = cf_probe.summary("m", "", r)
    assert (s["effort"], s["in"], s["out"], s["text_chars"]) == ("default", 5, 9, 3), s


def test_a_stream_with_no_text_reports_none_not_a_crash():
    r = cf_probe.read_stream([b"data: [DONE]\n"], fake_clock())
    assert r["first_text_s"] is None and cf_probe.summary("m", "max", r)["tok_s"] == 0, r


def test_body_carries_effort_extras_and_image():
    b = cf_probe.build_body("m", "p", "s", "none", {"temperature": 1}, b"png")
    assert b["reasoning_effort"] == "none" and b["temperature"] == 1 and b["messages"][0]["role"] == "system", b
    assert b["messages"][1]["content"][1]["image_url"]["url"].startswith("data:image/png;base64,"), b
    assert "reasoning_effort" not in cf_probe.build_body("m", "p", "", "", {}), "no effort = the model's default"


if __name__ == "__main__":
    tests = [v for k, v in sorted(globals().items()) if k.startswith("test_")]
    for t in tests:
        t()
    print(f"test_cf_probe: {len(tests)} tests passed")
