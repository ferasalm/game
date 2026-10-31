#!/usr/bin/env python3
"""Self-test for tools/hooks/heredoc_guard.py (LESSONS 4): a python heredoc holding a backslash, in any form, and a
doubled backslash anywhere are blocked (exit 2); clean python heredocs, other heredocs, other tools and bad input pass
(exit 0)."""
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


def test_blocks_every_python_heredoc_form():
    # Each form ran past the old head regex on 10-31, or appears in the transcripts.
    for cmd in ("python <<'X'\nprint('a\\nb')\nX",
                "python -I - <<'X'\nprint('a\\nb')\nX",
                "python -u - \"$S/graph.json\" out.md <<'X'\nprint('a\\nb')\nX",
                "python -X utf8 - <<X\nprint('a\\nb')\nX",
                "\"C:/Program Files/Python/python.exe\" - <<'X'\nprint('a\\nb')\nX",
                "cat <<'X' | python -\nprint('a\\nb')\nX",
                "python - <<'END-OF'\nprint('a\\nb')\nEND-OF"):
        r = run(cmd)
        assert r.returncode == 2 and "Write" in r.stderr, (cmd, r.returncode, r.stderr)


def test_blocks_a_doubled_backslash_anywhere():
    # The Bash tool collapses these outside python heredocs too (probed 10-31): a file written this way is silently wrong.
    for cmd in ("cat <<'X' > note.txt\nregex \\\\b here\nX",
                "printf '%s' 'a\\\\b'",
                "sed -i 's/\\\\n/x/' f.txt",
                "python -c \"print('a\\\\nb')\""):
        r = run(cmd)
        assert r.returncode == 2 and "doubled backslash" in r.stderr, (cmd, r.returncode, r.stderr)


def test_passes_clean_and_other_heredocs():
    for cmd in ("python - <<'EOF'\nprint('clean')\nEOF",
                "cat <<'EOF' > notes.txt\nline one\\nstill text\nEOF",
                "python - <<'EOF'\nprint(1)\nEOF\nprintf 'a\\nb'",  # the backslash is after the heredoc ends
                "python tools/map.py", "git status",
                "python tools/filter.py <<'X'\nsingle \\n in data\nX",  # data for a script, not python source
                "python -c \"print(1 << 2)\"\necho 'a\\nb'",
                "echo $((1<<2))\necho 'a\\nb'"):
        r = run(cmd)
        assert r.returncode == 0, (cmd, r.returncode, r.stderr)


def test_other_tools_and_bad_input_never_block():
    assert run("python - <<EOF\nprint('\\n')\nEOF", tool="PowerShell").returncode == 0
    for raw in ("not json", "{}", json.dumps({"tool_name": "Bash", "tool_input": None})):
        r = run("", raw=raw)
        assert r.returncode == 0, (raw, r.returncode, r.stderr)


if __name__ == "__main__":
    test_blocks_python_heredoc_with_backslash()
    test_blocks_every_python_heredoc_form()
    test_blocks_a_doubled_backslash_anywhere()
    test_passes_clean_and_other_heredocs()
    test_other_tools_and_bad_input_never_block()
    print("test_hook_heredoc: 5 tests passed")
