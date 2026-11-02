#!/usr/bin/env python3
"""One word for `gh run list --workflow check.yml --json status,conclusion` on stdin (row 26 S4, Feras 11-02).

handoff.sh's ci step polls it instead of reading "the first run", which is another workflow's as soon as one exists
(the Android export, D17). One commit can have two runs (push and pull_request): every run is waited for and one
failure fails. Empty list -> nothing (empty line, no run yet); any run not completed -> in_progress; every run
success -> success; anything else (failure, cancelled, timed_out) -> failure.
"""
import json
import sys


def word(runs):
    if not runs:
        return ""
    if any(r.get("status") != "completed" for r in runs):
        return "in_progress"
    return "success" if all(r.get("conclusion") == "success" for r in runs) else "failure"


def main():
    try:
        runs = json.load(sys.stdin)
    except ValueError:  # unreadable JSON is not a pass: handoff.sh fails its ci step on the word
        print("failure")
        return 0
    print(word(runs))
    return 0


if __name__ == "__main__":
    sys.exit(main())
