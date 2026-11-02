#!/usr/bin/env python3
"""One Kaizen line per batch: docs/runs.csv in, at most 20 lines of cut-or-tune advice out (row 26 P2).
An unknown cell (? or a missing column) is never 0; an old 9-column file reads every new column as unknown."""
import argparse
import csv

MAX_LINES, MAX_GROUPS = 20, 12


def number(value):
    """A cell as a float, or None when it is missing, empty or a ? (an unknown is never a zero)."""
    text = "" if value is None else str(value).strip()
    try:
        return float(text) if text and text != "?" else None
    except ValueError:
        return None


def fmt(value, digits=0):
    """A number as the report writes it: ? when unknown, a whole number bare, else with the given digits."""
    return "?" if value is None else (f"{value:.{digits}f}" if digits else f"{value:g}")


def read_rows(path, since):
    """The csv rows as dicts; a missing or empty file gives no rows, and --since drops the older dates."""
    try:
        with open(path, encoding="utf-8", newline="") as f:
            return [r for r in csv.DictReader(f) if since is None or (r.get("date") or "").strip() >= since]
    except (OSError, csv.Error, ValueError):
        return []


def total(rows, name):
    """The sum of one numeric column, or None when no row carries a number (an unknown stays unknown)."""
    values = [v for v in (number(row.get(name)) for row in rows) if v is not None]
    return sum(values) if values else None


def summary(name, rows):
    """One group's line and numbers: <group>  runs N  pass P%  min avg A  fix avg F  idle I min  tok X/Y  usd U."""
    minutes = [v for v in (number(row.get("minutes")) for row in rows) if v is not None]
    fixes = [v for v in (number(row.get("fix_passes")) for row in rows) if v is not None]
    passed = sum(1 for row in rows if (row.get("gate") or "").strip().upper() == "PASS")
    got = {"name": name, "n": len(rows), "pct": round(100 * passed / len(rows)) if rows else 0,
           "min_avg": sum(minutes) / len(minutes) if minutes else None,
           "fix_avg": sum(fixes) / len(fixes) if fixes else None,
           "idle": total(rows, "idle_min"), "minutes": total(rows, "minutes"),
           "unknown": sum(1 for row in rows if number(row.get("tokens_in")) is None)}
    got["line"] = (f"{name}  runs {got['n']}  pass {got['pct']}%  min avg {fmt(got['min_avg'], 1)}  "
                   f"fix avg {fmt(got['fix_avg'], 1)}  idle {fmt(got['idle'])} min  "
                   f"tok {fmt(total(rows, 'tokens_in'))}/{fmt(total(rows, 'tokens_out'))}  "
                   f"usd {fmt(total(rows, 'usd_est'), 2)} ({got['unknown']} unknown)")
    return got


def tune_lines(sums, rows):
    """The tune: lines in the brief's order: idle, low pass, fix passes, then the rows without a cost reading."""
    idle, low, fix = [], [], []
    for row in sums:
        if row["idle"] is not None and row["minutes"] and row["idle"] >= 10 \
                and row["idle"] * 100 >= row["minutes"] * 15:
            idle.append(f"tune: {row['name']} lost {fmt(row['idle'])} of {fmt(row['minutes'])} min to idle: "
                        "lower QUIET_SEC or tighten the first-commit deadline")
        if row["n"] >= 3 and row["pct"] < 70:
            low.append(f"tune: {row['name']} passes only {row['pct']}% of {row['n']} runs: "
                       "tighten briefs or move up an effort")
        if row["n"] >= 3 and (row["fix_avg"] or 0) > 1.0:
            fix.append(f"tune: {row['name']} needs {fmt(row['fix_avg'], 1)} fix passes a run: write sharper tests")
    missing = sum(1 for row in rows if number(row.get("usd_est")) is None)
    cost = [f"tune: {missing} row(s) have no cost reading (older runs or non-opencode builders)"] if missing else []
    return idle + low + fix + cost


def build(args):
    """Every line: the header, at most 12 groups with the more-groups note, then the tune lines, capped at 20."""
    rows = read_rows(args.csv, args.since)
    if not rows:
        return ["KAIZEN 0 runs"]
    groups = {}
    for row in rows:
        key = f"{(row.get('worker') or '').strip() or '?'}/{(row.get('effort') or '').strip() or '?'}"
        groups.setdefault(key, []).append(row)
    ordered = sorted(groups.items(), key=lambda item: (-len(item[1]), item[0]))
    dates = sorted(d for d in ((row.get("date") or "").strip() for row in rows) if d)
    span = f"{dates[0]}..{dates[-1]}" if dates else "?..?"
    sums = [summary(name, items) for name, items in ordered]
    out = [f"KAIZEN {len(rows)} runs, {span}"] + [row["line"] for row in sums[:MAX_GROUPS]]
    if len(ordered) > MAX_GROUPS:
        out.append(f"... and {len(ordered) - MAX_GROUPS} more groups")
    return (out + tune_lines(sums, rows))[:MAX_LINES]


def main(argv=None):
    """Print the report and exit 0 always: a csv the reader cannot parse still leaves one readable line."""
    ap = argparse.ArgumentParser(description="One Kaizen line per batch from docs/runs.csv")
    ap.add_argument("--csv", default="docs/runs.csv")
    ap.add_argument("--since", default=None)
    args = ap.parse_args(argv)
    try:
        lines = build(args)
    except Exception as exc:  # an unexpected shape in an old run never fails the head's read
        lines = [f"KAIZEN ? runs ({exc})"]
    print("\n".join(lines))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
