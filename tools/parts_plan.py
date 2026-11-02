#!/usr/bin/env python3
"""Two checks for running several parts of one row at the same time (Feras 11-02): the briefs before launch and the
finished branches before merge. Briefs: reads each brief's May edit, Do NOT edit and Tests sections and refuses an
overlap (same path, a folder and a path inside it, a glob and the path it matches), a May edit that hits what another
part locks or tests, and a test file two parts share; the generated union files may be shared on purpose. Branches:
dry-runs git merge-tree --write-tree --name-only for every pair, so a conflict is reported without touching a checkout.
Usage: parts_plan.py BRIEF...                     -> OK <n> parts / order: <stems> (exit 0) or one line per problem (1)
       parts_plan.py --branches B1 B2 ...        -> no conflicts, <n> branches (0) or conflict: B1 B2 <file> (1)
Tests: tools/test_parts_plan.py.
"""
import fnmatch
import os
import re
import subprocess
import sys

SHARED = {"docs/MAP.md", "docs/DOCMAP.md", "docs/runs.csv", "docs/doc_graph_allow.txt"}  # generated or union, shared on purpose
MAGIC = re.compile(r"[*?\[]")
TEST_PATH = re.compile(r"[^\s`]+\.(?:py|gd|sh)(?![\w.])")


def section(text, heading):
    """The body of the brief's heading, or "" when the brief has no such section."""
    m = re.search(rf"^## {heading}\s*$(.*?)(?=^## |\Z)", text, re.M | re.S)
    return m.group(1) if m else ""


def backticks(body):
    """The backticked tokens of a section; the word none has no backticks, so it reads as no paths."""
    return re.findall(r"`([^`\s]+)`", body)


def test_paths(body):
    """Every test path named before a :: on a line of the Tests section."""
    return [p for line in body.splitlines() for p in TEST_PATH.findall(line.split("::")[0])]


def load(path):
    """One part: its file stem plus the paths its May edit, Do NOT edit and Tests sections name."""
    with open(path, encoding="utf-8") as f:
        text = f.read()
    return {"name": os.path.splitext(os.path.basename(path))[0],
            "may": backticks(section(text, "May edit")),
            "dont": backticks(section(text, "Do NOT edit")),
            "tests": test_paths(section(text, "Tests"))}


def covers(entry, path):
    """True when a May edit entry is path, holds it (a folder ending in /) or matches it as a glob."""
    if entry.rstrip("/") == path.rstrip("/"):
        return True
    if entry.endswith("/") and path.startswith(entry):
        return True
    return bool(MAGIC.search(entry)) and fnmatch.fnmatchcase(path, entry)


def clash(a, b):
    """True when two May edit entries reach the same file."""
    return covers(a, b) or covers(b, a)


def edit_problems(parts):
    """One message per overlap, lock hit or shared test between two parts."""
    msgs = []
    for i, a in enumerate(parts):
        for b in parts[i + 1:]:
            for p in a["may"]:
                for q in b["may"]:
                    if p == q and p in SHARED:
                        continue
                    if clash(p, q):
                        msgs.append(f"{a['name']} and {b['name']} both edit {p}" if p == q
                                    else f"{a['name']} edits {p}, {b['name']} edits {q}: overlapping paths")
            for p in a["may"]:
                for q in b["dont"] + b["tests"]:
                    if clash(p, q):
                        msgs.append(f"{a['name']} edits {p}, which {b['name']} locks or tests ({q})")
            for q in b["may"]:
                for p in a["dont"] + a["tests"]:
                    if clash(q, p):
                        msgs.append(f"{b['name']} edits {q}, which {a['name']} locks or tests ({p})")
            for t in a["tests"]:
                if t in b["tests"]:
                    msgs.append(f"{a['name']} and {b['name']} both test {t}")
    return list(dict.fromkeys(msgs))


def merge_files(b1, b2):
    """The conflicting file names of a dry-run merge, or [] when the pair merges clean."""
    r = subprocess.run(["git", "merge-tree", "--write-tree", "--name-only", b1, b2],
                       capture_output=True, text=True)
    if r.returncode == 0:
        return []
    files = []
    for line in r.stdout.splitlines()[1:]:  # the first line is the tree id
        if not line.strip():
            break
        files.append(line.strip())
    return files or [f"merge-tree exit {r.returncode}"]


def branches(refs):
    """Checks every pair of refs; prints one conflict line per file, exit 0 only when every pair is clean."""
    bad = 0
    for i, b1 in enumerate(refs):
        for b2 in refs[i + 1:]:
            for f in merge_files(b1, b2):
                print(f"conflict: {b1} {b2} {f}")
                bad = 1
    if not bad:
        print(f"no conflicts, {len(refs)} branches")
    return bad


def main(argv):
    if argv[:1] == ["--branches"]:
        refs = argv[1:]
        if len(refs) < 2:
            print("usage: parts_plan.py --branches B1 B2 ...")
            return 2
        return branches(refs)
    if not argv:
        print("usage: parts_plan.py BRIEF... | --branches B1 B2 ...")
        return 2
    try:
        parts = [load(p) for p in argv]
    except OSError as e:
        print(f"cannot read a brief: {e}")
        return 2
    problems = edit_problems(parts)
    if problems:
        print("\n".join(problems))
        return 1
    print(f"OK {len(parts)} parts")
    print("order: " + " ".join(p["name"] for p in parts))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
