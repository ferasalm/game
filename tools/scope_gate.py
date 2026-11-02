#!/usr/bin/env python3
"""Scope gate: judges a test-writing run before the head reads it (row 26 S5, Feras 11-02).

SCOPED only when base...HEAD holds nothing but test files and generated docs, at least one new py or gd test file was
added, and every new one fails on the base (a test that passes there proves nothing). Reuses build_gate.py's helpers
instead of copying them. Prints a checklist; last line "VERDICT SCOPED" (exit 0) or "VERDICT REJECT" (exit 1).
Usage: scope_gate.py check --wt <worktree> --base <ref> --brief <file>
"""
import argparse
import fnmatch
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from build_gate import change_status, is_test, new_tests_on_base, runnable_new_tests  # noqa: E402

GENERATED = ("docs/MAP.md", "docs/DOCMAP.md", "*.uid")  # map.py, doc_graph.py and Godot write these: a test run may move them
KINDS = ("py", "gd")  # a test file the repo can run red


def generated(path):
    return any(fnmatch.fnmatch(path, pat) for pat in GENERATED)


def file_faults(status, brief_rel):
    """What a test-writing run may not do: touch product code, or modify/delete a test (only adding is allowed)."""
    out = []
    for path, st in status.items():
        if path == brief_rel:  # the brief is the run's input, not its work (a hand run keeps it in the checkout)
            continue
        if is_test(path):
            if st != "A":
                out.append(f"existing test changed: {path}")
        elif not generated(path):
            out.append(f"product code in a test run: {path}")
    return out


def asked(brief):
    """The lines of the brief's '## Tests' section: what the run was told to write."""
    try:
        text = open(brief, encoding="utf-8").read()
    except OSError:
        return []
    m = re.search(r"^## Tests\s*$(.*?)(?=^## |\Z)", text, re.M | re.S)
    return [ln.strip() for ln in m.group(1).splitlines() if ln.strip()] if m else []


def judge(wt, base, brief):
    """The checklist lines and the verdict word for one test-writing run."""
    status = change_status(wt, f"{base}...HEAD")
    faults = file_faults(status, os.path.relpath(brief, wt).replace("\\", "/"))
    new = runnable_new_tests(status, KINDS)
    passed = new_tests_on_base(wt, base, new) if new and not faults else []  # a rejected run needs no base run
    lines = [f"scope gate: {len(status)} changed file(s) in {wt} from {base}...HEAD"]
    lines += [f"asked  {ln}" for ln in asked(brief)]
    lines += [f"{st}      {path}" for path, st in sorted(status.items())]
    lines += [f"REJECT {fault}" for fault in faults]
    if not new:
        lines.append("REJECT no new test file")
    for path in new:
        lines.append(f"REJECT {path} passes on the base: it proves nothing" if path in passed
                     else f"ok     {path} fails on the base")
    return lines, "REJECT" if faults or not new or passed else "SCOPED"


def main(argv):
    p = argparse.ArgumentParser(description="Judge a test-writing run: only tests, at least one new, red on the base.")
    sub = p.add_subparsers(dest="cmd", required=True)
    c = sub.add_parser("check")
    for k in ("--wt", "--base", "--brief"):
        c.add_argument(k, required=True)
    a = p.parse_args(argv)
    lines, word = judge(a.wt, a.base, a.brief)
    print("\n".join(lines))
    print(f"VERDICT {word}")
    return 0 if word == "SCOPED" else 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
