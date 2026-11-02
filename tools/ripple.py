#!/usr/bin/env python3
"""List the existing tests a brief's May edit forces to change, before launch (row 26 S13, Feras 11-02).

Usage: python tools/ripple.py BRIEF [--root DIR]. Prints "RIPPLE <n> test file(s) ..." and one line per test
file that names an edited file; exits 0 always (information for the head, not a gate)."""
import argparse, os, re, sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from build_gate import section_paths  # the one backticked-path parser the gate already uses

MAX_LINES = 20
MAX_BYTES = 1_000_000
SKIP_DIRS = {".git", ".godot", ".check"}
SKIP_PATHS = (".claude/worktrees", "docs/archive")
TOPS = (("tools", (".py",)), ("tests", (".py", ".gd")), ("features", (".gd",)))


def section(text, heading):
    """A brief section's body: the same regex as build_gate.section_paths."""
    m = re.search(rf"^## {heading}\s*$(.*?)(?=^## |\Z)", text, re.M | re.S)
    return m.group(1) if m else ""


def locked_tests(text):
    """The test paths the Tests section locks: the first token of each line, before any ::."""
    out = set()
    for line in section(text, "Tests").splitlines():
        head = line.split("::")[0].strip().strip("`").strip()
        head = head[1:].strip() if head.startswith("-") else head
        token = head.split()[0] if head else ""
        if token.endswith((".py", ".gd")) and "/" in token:
            out.add(token.replace("\\", "/"))
    return out


def whole(needle):
    """A regex for needle as a whole token: no letter, digit, _, - or . touches either side."""
    return re.compile(r"(?<![\w.-])" + re.escape(needle) + r"(?![\w.-])")


def walk_tests(root):
    """Every test_*.py under tools/ and tests/ and every test_*.gd under tests/ and features/, root-relative."""
    found = []
    for top, exts in TOPS:
        for cur, dirs, files in os.walk(os.path.join(root, top)):
            dirs[:] = sorted(d for d in dirs if d not in SKIP_DIRS)
            for name in sorted(files):
                rel = os.path.relpath(os.path.join(cur, name), root).replace(os.sep, "/")
                if name.startswith("test_") and name.endswith(exts) and not rel.startswith(SKIP_PATHS):
                    found.append(rel)
    return sorted(found)


def read_text(path):
    """A test file's text with bad bytes replaced; None over MAX_BYTES or when it cannot be read."""
    try:
        if os.path.getsize(path) > MAX_BYTES:
            return None
        with open(path, encoding="utf-8", errors="replace") as f:
            return f.read()
    except OSError:
        return None


def report(root, text):
    """The report lines: the header, then one line per test file naming an edited file, capped at MAX_LINES."""
    edited = [p.replace("\\", "/") for p in section_paths(text, "May edit")]
    skip = locked_tests(text) | set(edited)
    hits = []
    for rel in walk_tests(root):
        body = None if rel in skip else read_text(os.path.join(root, rel))
        if body is not None:
            found = [p for p in edited if whole(p).search(body) or whole(os.path.basename(p)).search(body)]
            if found:
                hits.append((rel, ", ".join(sorted({os.path.basename(p) for p in found}))))
    if not hits:
        return ["RIPPLE 0"]
    out = [f"RIPPLE {len(hits)} test file(s) name the files this brief edits:"]
    out += [f"  {rel}  (names {names})" for rel, names in hits[:MAX_LINES]]
    if len(hits) > MAX_LINES:
        out.append(f"  ... and {len(hits) - MAX_LINES} more")
    return out


def main(argv=None):
    """Print the report and exit 0 always: a missing piece is reported, it never fails the head's read."""
    ap = argparse.ArgumentParser(description="Existing tests a brief's May edit forces to change")
    ap.add_argument("brief")
    ap.add_argument("--root", default=os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    args = ap.parse_args(argv)
    try:
        with open(args.brief, encoding="utf-8", errors="replace") as f:
            print("\n".join(report(args.root, f.read())))
    except Exception as exc:  # an unreadable brief still leaves the head one readable line
        print(f"ERROR ripple: {exc}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
