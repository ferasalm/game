#!/usr/bin/env python3
"""tools/next_chat.ps1 opens the next chat with a clean environment (11-04): a chat that inherits CLAUDE_CODE_CHILD_SESSION
runs with transcript saving off (no jsonl, so session_stats has nothing to measure). The inner command must clear it first."""
import os

TOOLS = os.path.dirname(os.path.abspath(__file__)).replace("\\", "/")


def inner_line():
    for line in open(TOOLS + "/next_chat.ps1", encoding="utf-8").read().split("\n"):
        if line.startswith("$inner ="):
            return line
    return ""


def test_the_new_chat_clears_the_child_session_marker_before_claude_starts():
    line = inner_line()
    assert "Remove-Item Env:CLAUDE_CODE_CHILD_SESSION" in line, line
    assert line.index("Remove-Item Env:CLAUDE_CODE_CHILD_SESSION") < line.index("claude --model"), line


def test_the_new_chat_still_reads_the_prompt_file_and_starts_opusplan_high():
    line = inner_line()
    assert "next_chat_prompt.txt" in line and "--model opusplan --effort high" in line, line


if __name__ == "__main__":
    from tool_tests import run_cases
    run_cases([v for k, v in sorted(globals().items()) if k.startswith("test_")], "test_next_chat")
