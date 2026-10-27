#!/usr/bin/env python3
"""Build gate: judges a builder run before Claude reads it (NOWORK, BREACH, FAIL or PASS plus a WARN checklist).

Also says when a merge may reuse the pipeline's check (a fast-forward onto the checked commit). DECISIONS 2026-10-23.
D6 (2026-10-27): the brief needs a "## Do NOT edit" section; existing tests (M/D) and anything under assets/ (incl.
*.import) are protected unless "## May edit" lists them; removed asserts or test funcs FAIL; --run-new-tests py,gd runs
each NEW test file against the base (a test that passes there proves nothing; .gd costs a Godot run in a check slot).
Usage: build_gate.py gate --wt <worktree> --base <ref> --brief <file> --check <check.txt> [--fix-from <sha>]
       [--inbox <dir>] [--run-new-tests py,gd]  -> prints the checklist, last line "VERDICT <word>"; exit 0 only for PASS.
       build_gate.py can-skip --repo <dir> --checked <sha> --tip <branch>  -> prints SKIP or CHECK.
"""
import argparse
import fnmatch
import os
import re
import shutil
import subprocess
import sys
import tempfile

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from gate_checklist import brief_checklist

NOISE = ("*.uid", "*.import", "docs/MAP.md")  # Godot's import and map.py write these during any check
OK_NUMBERS = {"0", "1", "2", "0.0", "1.0", "0.5", "-1"}
NUMBER = re.compile(r"(?<![\w.])-?\d+\.?\d*(?![\w.])")
READER_RANGE = re.compile(r"\.(number|integer|int_list|float_list)\(")  # a Def's allowed range, not a gameplay number


def git(repo, *args):
    import time
    for i in range(3):
        try:
            return subprocess.run(["git", "-C", repo, *args], capture_output=True, text=True, check=True).stdout
        except subprocess.CalledProcessError as e:
            if i == 2 or (e.returncode and e.returncode in (1, 2)):
                raise
            time.sleep(0.05)


def fail_lines(check_text):
    return [ln for ln in check_text.splitlines() if ln.startswith("FAIL")]


CHECK_LINE = re.compile(r"^\s*(assert\b|assert_\w+\(|check_\w+\()")
TEST_FUNC = re.compile(r"^\s*(?:func|def) (test_\w+)")


def real_files(files):  # a *.import under assets/ is an asset edit, not noise
    return [f for f in files if f.startswith("assets/") or not any(fnmatch.fnmatch(f, n) for n in NOISE)]


def section_paths(brief_text, heading):
    m = re.search(rf"^## {heading}\s*$(.*?)(?=^## |\Z)", brief_text, re.M | re.S)
    return re.findall(r"`([^`\s]+)`", m.group(1)) if m else []


def protected_hits(status, may):
    """D6 defaults: existing tests (modified/deleted) and every change under assets/, minus the brief's May edit list."""
    hits = []
    for f, st in status.items():
        if breaches([f], may):
            continue
        if f.startswith("assets/") or (is_test(f) and st != "A"):
            hits.append(f)
    return hits


def lost_checks(added, removed):
    """Messages for asserts / test funcs removed from test files and not re-added anywhere (a move or retune is fine)."""
    msgs = []
    rem_names = {m.group(1) for f, ls in removed.items() if is_test(f) for ln in ls if (m := TEST_FUNC.match(ln))}
    add_names = {m.group(1) for f, ls in added.items() if is_test(f) for ln in ls if (m := TEST_FUNC.match(ln))}
    for name in sorted(rem_names - add_names):
        msgs.append(f"removed test func {name}")
    n_rem = sum(1 for f, ls in removed.items() if is_test(f) for ln in ls if CHECK_LINE.match(ln))
    n_add = sum(1 for f, ls in added.items() if is_test(f) for ln in ls if CHECK_LINE.match(ln))
    if n_rem > n_add:
        msgs.append(f"removed {n_rem - n_add} check(s) from tests (asserts removed {n_rem}, added {n_add})")
    return msgs


def newtest_command(path, base_wt):
    """Argv that runs one new test file inside a checkout of the base."""
    if path.endswith(".py"):
        return [sys.executable, os.path.join(base_wt, path)]
    name = os.path.splitext(os.path.basename(path))[0]
    tools = os.path.dirname(os.path.abspath(__file__)).replace("\\", "/")
    return ["bash", "-c", f". '{tools}/check_slot.sh'; acquire_check_slot; trap release_check_slot EXIT; "
            f"bash tools/run_godot.sh --import > /dev/null 2>&1; bash tools/run_godot.sh -s res://tests/runner.gd -- {name}"]


def new_tests_on_base(wt, base, new_tests, kinds):
    """Files among new_tests that PASS on a checkout of the base (they would prove nothing). Only the given kinds run."""
    todo = [f for f in new_tests if f.rsplit(".", 1)[-1] in kinds]
    if not todo:
        return []
    tmp = os.path.join(tempfile.mkdtemp(), "base")
    git(wt, "worktree", "add", "-q", "--detach", tmp, base)
    try:
        passed = []
        for f in todo:
            os.makedirs(os.path.dirname(os.path.join(tmp, f)), exist_ok=True)
            shutil.copy(os.path.join(wt, f), os.path.join(tmp, f))
            r = subprocess.run(newtest_command(f, tmp), cwd=tmp, capture_output=True, text=True,
                               stdin=subprocess.DEVNULL, timeout=900)
            if r.returncode == 0:
                passed.append(f)
        return passed
    finally:
        git(wt, "worktree", "remove", "--force", tmp)


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
        hits = [ln for ln in lines if not ln.lstrip().startswith(("const", "#", "##")) and not READER_RANGE.search(ln)
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


def verdict(check_text, files, hits, misses=(), extra=()):
    if not real_files(files):
        return "NOWORK"
    if hits:
        return "BREACH"
    if fail_lines(check_text) or "all checks passed" not in check_text or misses or extra:
        return "FAIL"
    return "PASS"


def diff_lines(repo, base):
    """({file: added lines}, {file: removed lines}) of base...HEAD."""
    added, removed, cur, old = {}, {}, None, None
    for ln in git(repo, "diff", "-U0", "--no-renames", f"{base}...HEAD").splitlines():
        if ln.startswith("--- "):
            old = ln[6:] if ln.startswith("--- a/") else None
        elif ln.startswith("+++ "):
            cur = ln[6:] if ln.startswith("+++ b/") else old  # a deleted file shows +++ /dev/null: use the old name
        elif cur and ln.startswith("+"):
            added.setdefault(cur, []).append(ln[1:])
        elif cur and ln.startswith("-"):
            removed.setdefault(cur, []).append(ln[1:])
    return added, removed


def added_lines(repo, base):
    return diff_lines(repo, base)[0]


def change_status(repo, rng):
    """{path: A|M|D} (renames count as D + A)."""
    out = {}
    for ln in git(repo, "diff", "--name-status", "--no-renames", rng).splitlines():
        st, _, path = ln.partition("\t")
        if path:
            out[path] = st[0]
    return out


def changed(repo, rng):
    return [f for f in git(repo, "diff", "--name-only", rng).splitlines() if f]


def run_gate(a):
    status = change_status(a.wt, f"{a.base}...HEAD")  # from the fork point: a moving base is not the run's work
    files = list(status)
    brief = open(a.brief, encoding="utf-8").read()
    check_text = open(a.check, encoding="utf-8", errors="replace").read() if os.path.isfile(a.check) else ""
    hits = breaches(real_files(files), forbidden_paths(brief))
    hits += [f for f in protected_hits({f: status[f] for f in real_files(files)}, section_paths(brief, "May edit"))
             if f not in hits]
    added, removed = diff_lines(a.wt, a.base)
    extra = []
    if not re.search(r"^## Do NOT edit\s*$", brief, re.M):
        extra.append("brief has no '## Do NOT edit' section (D6: add one, even if it only lists the protected defaults)")
    extra += lost_checks(added, removed)
    new_tests = [f for f, st in status.items() if st == "A" and is_test(f)]
    kinds = [k for k in a.run_new_tests.split(",") if k]
    for f in new_tests_on_base(a.wt, a.base, new_tests, kinds):
        extra.append(f"new test passes on base (proves nothing): {f}")
    for f in new_tests:
        if f.rsplit(".", 1)[-1] in kinds and not any(f in e for e in extra):
            print(f"ok   new test fails on base: {f}")
    fix_tests = [f for f in changed(a.wt, f"{a.fix_from}...HEAD") if is_test(f)] if a.fix_from else []
    misses, warns = brief_checklist(a.wt, brief)
    word = verdict(check_text, files, hits, misses, extra)
    for e in extra:
        print(f"GATE FAIL: {e}")
    for ln in fail_lines(check_text):
        print(ln)
    for f in hits:
        print(f"BREACH {f} (the brief's Do NOT edit list or a D6 protected default)")
    for miss in misses:
        print(f"CHECKLIST missing: {miss}")
    for w in warns:
        print(w)
    for status, item, detail in checklist(real_files(files), added, brief, a.inbox, fix_tests):
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
    g.add_argument("--run-new-tests", default="", help="comma list of kinds to run on the base: py,gd")
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
