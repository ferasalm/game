#!/usr/bin/env python3
"""Self-test for tools/hooks/run.sh: hooks run the session's own copy, a missing script never blocks a tool."""
import json
import os
import subprocess
import tempfile

RUN = os.path.join(os.path.dirname(os.path.abspath(__file__)), "hooks", "run.sh")


def run(name, payload, env=None):
    return subprocess.run(["bash", RUN, name], input=json.dumps(payload), capture_output=True, text=True,
                          env=dict(os.environ, **(env or {})))


def test_missing_script_passes():
    r = run("no_such_hook", {"tool_name": "SendUserFile", "cwd": tempfile.mkdtemp()})
    assert r.returncode == 0 and r.stdout == "", (r.returncode, r.stdout, r.stderr)


def test_session_copy_wins_and_exit_code_carries():
    repo = tempfile.mkdtemp()
    subprocess.run(["git", "init", "-q", repo], check=True)
    os.makedirs(os.path.join(repo, "tools", "hooks"))
    with open(os.path.join(repo, "tools", "hooks", "review_gate.py"), "w", encoding="utf-8", newline="\n") as f:
        f.write("import sys, json\nd = json.load(sys.stdin)\nprint('own ' + d['tool_name'])\nsys.exit(2)\n")
    r = run("review_gate", {"tool_name": "SendUserFile", "cwd": repo.replace("/", "\\")})
    assert r.returncode == 2 and r.stdout.strip() == "own SendUserFile", (r.returncode, r.stdout, r.stderr)


def test_falls_back_to_this_checkout():
    box = tempfile.mkdtemp()  # not a git repo: run.sh uses its own folder's review_gate.py
    shot = os.path.join(box, "contact.png")
    with open(shot, "wb") as f:
        f.write(b"png")
    r = run("review_gate", {"tool_name": "SendUserFile", "tool_input": {"files": [shot]}, "cwd": box},
            {"REVIEW_STAMP_DIR": os.path.join(box, "stamps")})
    assert r.returncode == 2 and "BLOCKED" in r.stderr, (r.returncode, r.stderr)


if __name__ == "__main__":
    tests = [v for k, v in sorted(globals().items()) if k.startswith("test_")]
    for t in tests:
        t()
    print(f"test_hook_run: {len(tests)} tests passed")
