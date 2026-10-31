#!/usr/bin/env python3
"""Self-test for tools/hooks/stop_notify.py: a Stop makes one balloon command, a repeat Stop stays quiet, bad input never blocks."""
import json
import os
import subprocess
import sys

HOOK = os.path.join(os.path.dirname(os.path.abspath(__file__)), "hooks", "stop_notify.py")
ENV = dict(os.environ, STOP_NOTIFY_DRY="1")


def run(payload):
    return subprocess.run([sys.executable, HOOK], input=payload, capture_output=True, text=True, env=ENV)


def test_stop_builds_the_balloon():
    r = run(json.dumps({"hook_event_name": "Stop"}))
    assert r.returncode == 0 and "ShowBalloonTip" in r.stdout and "powershell" in r.stdout, (r.returncode, r.stdout)


def test_repeat_stop_is_quiet():
    r = run(json.dumps({"hook_event_name": "Stop", "stop_hook_active": True}))
    assert r.returncode == 0 and r.stdout == "", (r.returncode, r.stdout)


def test_bad_input_never_blocks():
    r = run("not json")
    assert r.returncode == 0 and r.stdout == "", (r.returncode, r.stdout, r.stderr)


if __name__ == "__main__":
    test_stop_builds_the_balloon()
    test_repeat_stop_is_quiet()
    test_bad_input_never_blocks()
    print("test_hook_stop_notify: 3 tests passed")
