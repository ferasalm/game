#!/usr/bin/env python3
"""Append run scoreboard entries to docs/runs.csv."""
import argparse
import csv
import datetime
import os

HEADER = ["date", "task", "worker", "effort", "gate", "fix_passes", "minutes", "cost", "real_findings",
          "tokens_in", "tokens_out", "usd_est", "cost_source", "idle_min"]
OLD_HEADER = HEADER[:9]
UNKNOWN = ["?", "?", "?", "unknown", "?"]


def migrate(path):
    """Rewrite a 9-column file once (new header, old rows as unknown); a migrated file never matches again."""
    with open(path, encoding="utf-8", newline="") as f:
        if f.readline().rstrip("\r\n") != ",".join(OLD_HEADER):
            return
        rows = list(csv.reader(f))
    with open(path, "w", encoding="utf-8", newline="") as f:
        writer = csv.writer(f, lineterminator="\n")
        writer.writerow(HEADER)
        for row in rows:
            writer.writerow(row + UNKNOWN if len(row) == len(OLD_HEADER) else row)


def append_cmd(args) -> int:
    path = args.file
    parent = os.path.dirname(os.path.abspath(path))
    if parent:
        os.makedirs(parent, exist_ok=True)
    exists = os.path.exists(path) and os.path.getsize(path) > 0
    if exists:
        migrate(path)
    date_val = args.date or datetime.date.today().isoformat()
    with open(path, "a", encoding="utf-8", newline="") as f:
        writer = csv.writer(f, lineterminator="\n")
        if not exists:
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
            str(args.tokens_in),
            str(args.tokens_out),
            str(args.usd),
            str(args.source),
            str(args.idle_min),
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
    p_app.add_argument("--tokens-in", dest="tokens_in", default="?")
    p_app.add_argument("--tokens-out", dest="tokens_out", default="?")
    p_app.add_argument("--usd", default="?")
    p_app.add_argument("--source", default="unknown")
    p_app.add_argument("--idle-min", dest="idle_min", default="?")
    p_app.add_argument("--file", default="docs/runs.csv")
    p_app.add_argument("--date", default=None)
    p_app.set_defaults(func=append_cmd)

    args = ap.parse_args()
    return args.func(args)


if __name__ == "__main__":
    raise SystemExit(main())
