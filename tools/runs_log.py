#!/usr/bin/env python3
"""Append run scoreboard entries to docs/runs.csv."""
import argparse
import csv
import datetime
import os

HEADER = ["date", "task", "worker", "effort", "gate", "fix_passes", "minutes", "cost", "real_findings"]


def append_cmd(args) -> int:
    path = args.file
    parent = os.path.dirname(os.path.abspath(path))
    if parent:
        os.makedirs(parent, exist_ok=True)
    write_header = not os.path.exists(path) or os.path.getsize(path) == 0
    date_val = args.date or datetime.date.today().isoformat()
    with open(path, "a", encoding="utf-8", newline="") as f:
        writer = csv.writer(f, lineterminator="\n")
        if write_header:
            writer.writerow(HEADER)
        writer.writerow([
            date_val,
            args.task,
            args.worker,
            args.effort,
            args.gate,
            str(args.fix_passes),
            str(args.minutes),
            str(args.cost),
            str(args.findings),
        ])
    return 0


def main() -> int:
    ap = argparse.ArgumentParser(description="Log pipeline runs to csv")
    sub = ap.add_subparsers(dest="cmd", required=True)
    p_app = sub.add_parser("append")
    p_app.add_argument("--task", required=True)
    p_app.add_argument("--worker", required=True)
    p_app.add_argument("--effort", required=True)
    p_app.add_argument("--gate", required=True)
    p_app.add_argument("--fix-passes", dest="fix_passes", required=True)
    p_app.add_argument("--minutes", required=True)
    p_app.add_argument("--cost", required=True)
    p_app.add_argument("--findings", required=True)
    p_app.add_argument("--file", default="docs/runs.csv")
    p_app.add_argument("--date", default=None)
    p_app.set_defaults(func=append_cmd)

    args = ap.parse_args()
    return args.func(args)


if __name__ == "__main__":
    raise SystemExit(main())
