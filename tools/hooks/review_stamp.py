#!/usr/bin/env python3
"""Record a player and a Feras review for a game render (D5, D21), keyed by the file's sha256.

review_gate.py passes a render only when <stamp dir>/<sha256>.json exists. Stamp dir is REVIEW_STAMP_DIR,
else <git common dir>/reviews.
"""
import argparse
import datetime
import hashlib
import json
import os
import subprocess
import sys


def stamp_dir():
    env = os.environ.get("REVIEW_STAMP_DIR")
    if env:
        return env
    here = os.path.dirname(os.path.abspath(__file__))
    out = subprocess.run(["git", "rev-parse", "--git-common-dir"], cwd=here, capture_output=True, text=True)
    common = out.stdout.strip()
    if not os.path.isabs(common):
        common = os.path.join(here, common)
    return os.path.join(os.path.abspath(common), "reviews")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("files", nargs="+")
    ap.add_argument("--player", required=True)
    ap.add_argument("--feras", required=True)
    args = ap.parse_args()
    if not args.player.strip() or not args.feras.strip():
        print("review_stamp: --player and --feras both need a verdict", file=sys.stderr)
        return 2
    target = stamp_dir()
    os.makedirs(target, exist_ok=True)
    date = datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%d")
    for path in args.files:
        try:
            with open(path, "rb") as f:
                digest = hashlib.sha256(f.read()).hexdigest()
        except OSError as exc:
            print(f"review_stamp: cannot read {path}: {exc}", file=sys.stderr)
            return 2
        with open(os.path.join(target, digest + ".json"), "w", encoding="utf-8") as f:
            json.dump({"path": os.path.abspath(path), "player": args.player, "feras": args.feras, "date": date}, f)
        print(f"stamped {path}")
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except Exception as exc:
        print(f"review_stamp: {exc}", file=sys.stderr)
        sys.exit(2)
