#!/usr/bin/env python3
"""One short report per part: the .result, the runs.csv cost and the cross-review flags in <= 15 lines (row 26 S10)."""
import argparse
import csv
import os
import re
import subprocess

MAX_LINES, MAX_CHARS = 15, 160
HEADER = ("builder", "model", "kind", "checked", "idle_min")
DETAILS = ("WARN", "BREACH", "FAIL", "ERROR", "REJECT", "CHECKLIST", "gate error:", "why:")
NEXT = {"PASS": "read risky hunks, then bash tools/merge_run.sh {task}",
        "SCOPED": "read EVERY test in full, then bash tools/lock_tests.sh {task} <task>-base",
        "REJECT": "read the REJECT lines; rerun the scope run or fix the tests by hand",
        "FAIL": "read the FAIL lines in {task}.check.txt",
        "BREACH": "read the breach, fix by hand or rerun",
        "NOWORK": "read the why line, fix the launch", "ERROR": "read the why line, fix the launch"}


def cut(text):
    """One line, at most MAX_CHARS characters: a longer line loses its tail to ..."""
    text = " ".join(text.split())
    return text if len(text) <= MAX_CHARS else text[:MAX_CHARS - 3].rstrip() + "..."


def read_text(path):
    """A file's text, or None when it is missing: a part without it prints ? and never a traceback."""
    try:
        with open(path, encoding="utf-8", errors="replace") as f:
            return f.read()
    except OSError:
        return None


def head_lines(lines, task):
    """WORD task builder= model= kind=, the checked sha with its counts, then idle_min and the quiet:/idle: note."""
    parts = {}
    for key, _, value in (line.partition(" ") for line in lines):
        if key in HEADER and key not in parts:
            parts[key] = value.strip() or "?"
    word = lines[0].partition(" ")[0] if lines else "?"
    out = [f"{word} {task} builder={parts.get('builder', '?')} model={parts.get('model', '?')} "
           f"kind={parts.get('kind', '?')}"]
    start = lines.index("--- commits") + 1 if "--- commits" in lines else 0
    end = next((i for i in range(start, len(lines)) if lines[i].startswith("--- ")), len(lines))
    commits = len([line for line in lines[start:end] if line.strip()]) if start else "?"
    files = "?"
    for line in lines[lines.index("--- diffstat") + 1:] if "--- diffstat" in lines else []:
        found = re.search(r"(\d+) files? changed", line)
        files = found.group(1) if found else files
    out.append(f"checked {(parts.get('checked') or '?')[:7]} {commits} commits, {files} files")
    out.append("idle_min " + (parts.get("idle_min") or "?"))
    return out + [cut(line) for line in lines if line.startswith(("quiet:", "idle:"))][:1]


def cost_line(path, task):
    """The LAST runs.csv row for the task: tokens in/out, usd_est and the cost source; no row prints cost ?"""
    try:
        with open(path, encoding="utf-8", newline="") as f:
            rows = [r for r in csv.DictReader(f) if (r.get("task") or "").strip() == task]
    except (OSError, csv.Error, ValueError):
        rows = []
    if not rows:
        return "cost ?"
    cells = [(rows[-1].get(name) or "").strip() or "?" for name in
             ("tokens_in", "tokens_out", "usd_est", "cost_source")]
    return f"cost {cells[0]}/{cells[1]} tokens, ${cells[2]} ({cells[3]})"


def flags_line(path):
    """How many findings the cross-review file holds between BEGIN and END FINDINGS, plus the first one's text."""
    text = read_text(path)
    if text is None:
        return "flags ?"
    block = re.search(r"BEGIN FINDINGS\n(.*?)\nEND FINDINGS", text, re.S)
    found = [line.strip() for line in block.group(1).splitlines() if line.strip()] if block else []
    return cut(f"flags {len(found)} flag(s) ({found[0]})") if found else "flags 0 flag(s)"


def build(args):
    """The report's lines in the brief's order: header, checked, idle, up to 5 details, cost, flags, next."""
    text = read_text(os.path.join(args.wt_dir, args.task + ".result"))
    if text is None:
        return ["NO RESULT " + args.task]
    lines = [line.rstrip() for line in text.splitlines() if line.strip()]
    out = head_lines(lines, args.task)
    out += [cut(line) for line in lines[1:] if line.startswith(DETAILS)][:5]
    out.append(cost_line(args.runs_csv, args.task))
    out.append(flags_line(os.path.join(args.reviews_dir, args.task + "-cross.md")))
    word = lines[0].partition(" ")[0] if lines else "?"
    out.append("next: " + NEXT.get(word, "read the .result and decide by hand").format(task=args.task))
    return [cut(line) for line in out][:MAX_LINES]


def wt_default():
    """Where builder worktrees live, as tools/lib.sh wt_dir gives it: <main checkout's parent>/game-wt."""
    try:
        common = subprocess.run(["git", "rev-parse", "--path-format=absolute", "--git-common-dir"],
                                capture_output=True, text=True, check=True).stdout.strip()
        return os.path.join(os.path.dirname(os.path.dirname(common)), "game-wt")
    except (OSError, subprocess.SubprocessError):
        return os.path.join("..", "game-wt")


def main(argv=None):
    """Print the report and exit 0 always: a missing piece prints ?, it never fails the head's read."""
    ap = argparse.ArgumentParser(description="One short report per builder part")
    ap.add_argument("task")
    ap.add_argument("--wt-dir", dest="wt_dir", default=wt_default())
    ap.add_argument("--runs-csv", dest="runs_csv", default="docs/runs.csv")
    ap.add_argument("--reviews-dir", dest="reviews_dir", default=".check/reviews")
    args = ap.parse_args(argv)
    try:
        print("\n".join(build(args)))
    except Exception as exc:  # an unexpected shape in an old run still leaves the head one readable line
        print(cut(f"ERROR part_report: {exc}"))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
