#!/usr/bin/env python3
"""Build gate: judges a builder run before Claude reads it (NOWORK, BREACH, FAIL or PASS plus a WARN checklist).

Also says when a merge may reuse the pipeline's check (a fast-forward onto the checked commit). DECISIONS 2026-10-23.
Usage: build_gate.py gate --wt <worktree> --base <ref> --brief <file> --check <check.txt> [--fix-from <sha>]
       [--inbox <dir>]  -> prints the checklist, last line "VERDICT <word>"; exit 0 only for PASS.
       build_gate.py can-skip --repo <dir> --checked <sha> --tip <branch>  -> prints SKIP or CHECK.
"""
import argparse
import fnmatch
import os
import re
import subprocess
import sys

NOISE = ("*.uid", "*.import", "docs/MAP.md")  # Godot's import and map.py write these during any check
OK_NUMBERS = {"0", "1", "2", "0.0", "1.0", "0.5", "-1"}
NUMBER = re.compile(r"(?<![\w.])-?\d+\.?\d*(?![\w.])")


def git(repo, *args):
    return subprocess.run(["git", "-C", repo, *args], capture_output=True, text=True, check=True).stdout


def fail_lines(check_text):
    return [ln for ln in check_text.splitlines() if ln.startswith("FAIL")]


def real_files(files):
    return [f for f in files if not any(fnmatch.fnmatch(f, n) for n in NOISE)]


def forbidden_paths(brief_text):
    """Backticked paths in the brief's '## Do NOT edit' section (one per line, TEMPLATE.md)."""
    m = re.search(r"^## Do NOT edit\s*$(.*?)(?=^## |\Z)", brief_text, re.M | re.S)
    return re.findall(r"`([^`\s]+)`", m.group(1)) if m else []


def breaches(files, forbidden):
    hits = []
    for f in files:
        for tok in forbidden:
            t = tok.rstrip("/")
            if f == t or f.startswith(t + "/") or fnmatch.fnmatch(f, tok):
                hits.append(f)
                break
    return hits


def is_test(path):
    return "/tests/" in "/" + path or os.path.basename(path).startswith("test_")


def new_numbers(added):
    """{file: [lines]} of added .gd code lines (not tests, not const) that carry gameplay-looking numbers."""
    out = {}
    for f, lines in added.items():
        if not f.endswith(".gd") or is_test(f):
            continue
        hits = [ln for ln in lines if not ln.lstrip().startswith(("const", "#", "##"))
                and set(NUMBER.findall(ln.split("#")[0])) - OK_NUMBERS]
        if hits:
            out[f] = hits
    return out


def checklist(files, added, brief_text, inbox, fix_test_files):
    items = []
    code = [f for f in files if f.endswith(".gd") and not is_test(f)]
    tests = [f for f in files if f.endswith(".gd") and is_test(f)]
    if code and not tests:
        items.append(("WARN", "tests", "code changed but no test file changed"))
    else:
        items.append(("ok", "tests", f"{len(tests)} test file(s)"))
    nums = new_numbers(added)
    if nums:
        first = [f"{f}: {ls[0].strip()[:70]}" for f, ls in list(nums.items())[:3]]
        items.append(("WARN", "numbers in code", f"{sum(map(len, nums.values()))} line(s); " + " | ".join(first)))
    for name in sorted(set(re.findall(r"inbox/([\w-]+\.png)", brief_text))):
        if not os.path.isfile(os.path.join(inbox, name)):
            items.append(("WARN", "render", f"inbox/{name} missing"))
    if fix_test_files:
        items.append(("WARN", "fix pass edited tests", ", ".join(fix_test_files)))
    text = sum(len(v) for f, v in added.items() if f.startswith("localization/"))
    items.append(("ok", "player text", f"{text} new line(s)"))
    return items


def verdict(check_text, files, hits):
    if not real_files(files):
        return "NOWORK"
    if hits:
        return "BREACH"
    if fail_lines(check_text) or "all checks passed" not in check_text:
        return "FAIL"
    return "PASS"


def added_lines(repo, base):
    out, cur = {}, None
    for ln in git(repo, "diff", "-U0", f"{base}...HEAD").splitlines():
        if ln.startswith("+++ "):
            cur = ln[6:] if ln.startswith("+++ b/") else None
        elif cur and ln.startswith("+") and not ln.startswith("+++"):
            out.setdefault(cur, []).append(ln[1:])
    return out


def changed(repo, rng):
    return [f for f in git(repo, "diff", "--name-only", rng).splitlines() if f]


def run_gate(a):
    files = changed(a.wt, f"{a.base}...HEAD")  # from the fork point: a moving base is not the run's work
    brief = open(a.brief, encoding="utf-8").read()
    check_text = open(a.check, encoding="utf-8", errors="replace").read() if os.path.isfile(a.check) else ""
    hits = breaches(real_files(files), forbidden_paths(brief))
    fix_tests = [f for f in changed(a.wt, f"{a.fix_from}...HEAD") if is_test(f)] if a.fix_from else []
    word = verdict(check_text, files, hits)
    for ln in fail_lines(check_text):
        print(ln)
    for f in hits:
        print(f"BREACH {f} (the brief's Do NOT edit list)")
    for status, item, detail in checklist(real_files(files), added_lines(a.wt, a.base), brief, a.inbox, fix_tests):
        print(f"{status:4} {item}: {detail}")
    print(f"VERDICT {word}")
    return 0 if word == "PASS" else 1


def can_skip(repo, checked, tip):
    """SKIP only when the run's tip is the checked commit and HEAD fast-forwards onto it (identical tree)."""
    tip_sha = git(repo, "rev-parse", tip).strip()
    if not checked or tip_sha != git(repo, "rev-parse", checked).strip():
        return "CHECK"
    ok = subprocess.run(["git", "-C", repo, "merge-base", "--is-ancestor", "HEAD", tip_sha]).returncode == 0
    return "SKIP" if ok else "CHECK"


def main(argv):
    p = argparse.ArgumentParser()
    sub = p.add_subparsers(dest="cmd", required=True)
    g = sub.add_parser("gate")
    for k in ("--wt", "--base", "--brief", "--check"):
        g.add_argument(k, required=True)
    g.add_argument("--fix-from", default="")
    g.add_argument("--inbox", default="C:/dev/game/inbox")
    s = sub.add_parser("can-skip")
    for k in ("--repo", "--checked", "--tip"):
        s.add_argument(k, required=True)
    a = p.parse_args(argv)
    if a.cmd == "gate":
        return run_gate(a)
    print(can_skip(a.repo, a.checked, a.tip))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
