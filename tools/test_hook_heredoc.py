#!/usr/bin/env python3
"""Self-test for tools/hooks/heredoc_guard.py (LESSONS 4): a python heredoc holding a backslash is blocked (exit 2);
clean python heredocs, other heredocs, other tools and bad input pass (exit 0)."""
import json
import os
import subprocess
import sys

HOOK = os.path.join(os.path.dirname(os.path.abspath(__file__)), "hooks", "heredoc_guard.py")


def run(command, tool="Bash", raw=None):
    payload = raw if raw is not None else json.dumps({"tool_name": tool, "tool_input": {"command": command}})
    return subprocess.run([sys.executable, HOOK], input=payload, capture_output=True, text=True)


def test_blocks_python_heredoc_with_backslash():
    for cmd in ("python - <<'EOF' < /dev/null\nprint('a\\nb')\nEOF",
                "cd x; python3 - <<EOF\nimport re\nre.compile(r'\\bword')\nEOF\necho done",
                "python - <<-\"PY\"\n\tprint('tab\\t')\n\tPY"):
        r = run(cmd)
        assert r.returncode == 2 and "Write" in r.stderr, (cmd, r.returncode, r.stderr)


def test_passes_clean_and_other_heredocs():
    for cmd in ("python - <<'EOF'\nprint('clean')\nEOF",
                "cat <<'EOF' > notes.txt\nline one\\nstill text\nEOF",
                "python - <<'EOF'\nprint(1)\nEOF\nprintf 'a\\nb'",  # the backslash is after the heredoc ends
                "python tools/map.py", "git status"):
        r = run(cmd)
        assert r.returncode == 0, (cmd, r.returncode, r.stderr)


def test_other_tools_and_bad_input_never_block():
    assert run("python - <<EOF\nprint('\\n')\nEOF", tool="PowerShell").returncode == 0
    for raw in ("not json", "{}", json.dumps({"tool_name": "Bash", "tool_input": None})):
        r = run("", raw=raw)
        assert r.returncode == 0, (raw, r.returncode, r.stderr)


if __name__ == "__main__":
    test_blocks_python_heredoc_with_backslash()
    test_passes_clean_and_other_heredocs()
    test_other_tools_and_bad_input_never_block()
    print("test_hook_heredoc: 3 tests passed")
