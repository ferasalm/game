#!/usr/bin/env python3
"""check_slot.sh: a full set of slots makes the next run wait; a released or stale slot lets it in."""
import os
import subprocess
import tempfile
import time

HERE = os.path.dirname(os.path.abspath(__file__))


def run(env, code, timeout):
    try:
        return subprocess.run(["bash", "-c", f". '{HERE}/check_slot.sh'; {code}"], env=env, timeout=timeout,
                              capture_output=True, text=True).returncode
    except subprocess.TimeoutExpired:
        return None


def main():
    d = tempfile.mkdtemp()
    env = dict(os.environ, CHECK_SLOT_DIR=d, CHECK_SLOTS="1")
    assert run(env, "acquire_check_slot", 10) == 0 and os.path.isdir(os.path.join(d, "slot1")), "first run gets slot1"
    assert run(env, "acquire_check_slot", 4) is None, "second run waits while the only slot is busy"
    os.rmdir(os.path.join(d, "slot1")) if not os.listdir(os.path.join(d, "slot1")) else None
    subprocess.run(["rm", "-rf", os.path.join(d, "slot1")])
    assert run(env, "acquire_check_slot; release_check_slot", 10) == 0, "a freed slot is taken"
    assert not os.path.exists(os.path.join(d, "slot1")), "release removes the slot"
    os.makedirs(os.path.join(d, "slot1"))
    old = time.time() - 30 * 60
    os.utime(os.path.join(d, "slot1"), (old, old))
    assert run(env, "acquire_check_slot", 10) == 0, "a stale slot is reclaimed"
    print("test_check_slot: 4 tests passed")


main()
