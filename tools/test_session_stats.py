#!/usr/bin/env python
"""session_stats counts calls, failed calls, real user turns (not tool results or injected tags) and peak context."""
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import session_stats as ss  # noqa: E402

CHAT = [
    {"type": "user", "message": {"content": "do the thing"}},
    {"type": "user", "message": {"content": "<system-reminder>not a turn</system-reminder>"}},
    {"type": "assistant", "message": {"model": "m1", "usage": {"input_tokens": 10, "cache_read_input_tokens": 250000},
                                      "content": [{"type": "tool_use"}, {"type": "text"}, {"type": "tool_use"}]}},
    {"type": "user", "message": {"content": [{"type": "tool_result", "is_error": True}, {"type": "tool_result"}]}},
]


def test_fold_counts_and_ignores_a_broken_line():
    day = ss.blank()
    ss.fold([json.dumps(e) for e in CHAT] + ["{broken"], day)
    assert (day["calls"], day["errors"], day["turns"], day["chats"]) == (2, 1, 1, 1), day
    assert day["peak"] == 250010 and day["over200k"] == 1 and day["models"]["m1"] == 1, day


def test_rows_prints_rate_and_survives_an_empty_day():
    day = ss.blank()
    ss.fold([json.dumps(e) for e in CHAT], day)
    line = ss.rows({"2026-10-31": day, "2026-10-30": ss.blank()})
    assert "50.0%" in line[1] and "m1" in line[1] and line[0].startswith("2026-10-30"), line


def test_a_guard_refusal_is_not_a_slip():
    day = ss.blank()
    guarded = {"type": "user", "message": {"content": [{"is_error": True, "content": "This session is isolated in the worktree"}]}}
    ss.fold([json.dumps(guarded)], day)
    assert (day["errors"], day["guards"]) == (1, 1), day


if __name__ == "__main__":
    tests = [v for k, v in sorted(globals().items()) if k.startswith("test_")]
    for t in tests:
        t()
    print(f"test_session_stats: {len(tests)} tests passed")
