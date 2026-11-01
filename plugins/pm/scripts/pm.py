#!/usr/bin/env python3
"""Project management CLI for Neon Glitch (row 23, 2026-11-01).

Manages HANDOFF.md queue/open points and BRIEFING.md open items.
"""
import argparse
import datetime
import pathlib
import re
import sys
from typing import List, Optional

from pm_tables import REPO_ROOT, check_and_restore, parse_queue, parse_table


def cmd_board(handoff_path: pathlib.Path) -> None:
    text = handoff_path.read_text(encoding="utf-8")
    q_rows = [r for r in parse_table(text, "## Queue") if r and r[0].isdigit()]
    open_rows = parse_table(text, "## Open points")
    week_rows = parse_table(text, "## This week")

    print("== Queue")
    for r in q_rows[:5]:
        print(f"#{r[0]} | {r[2]} | {r[1]} | {r[4]} | {r[5]}")
    print("== Open points")
    for r in open_rows:
        print(f"{r[0]} | {r[1]} | {r[2]}")
    print("== This week")
    for r in week_rows:
        print(f"{r[0]}: {r[1]}")
    print("== Your moves")
    for r in q_rows:
        lane_parts = [p.strip() for p in r[3].split("+")]
        if "Feras" in lane_parts:
            print(f"#{r[0]} | {r[1]} | {r[5]}")
    for r in open_rows:
        if r[1].strip() == "Feras":
            print(f"{r[0]} | {r[1]} | {r[2]}")


def cmd_next(handoff_path: pathlib.Path) -> None:
    text = handoff_path.read_text(encoding="utf-8")
    q_rows = [r for r in parse_table(text, "## Queue") if r and r[0].isdigit()]
    if q_rows:
        r = q_rows[0]
        print(f"#{r[0]} | {r[2]} | {r[1]} | {r[4]} | {r[5]}")
    prompt_part = text.split("## Prompt for the next chat", 1)[-1]
    prompt_lines = [l.strip().strip("`") for l in prompt_part.splitlines() if l.strip().startswith("`")]
    if prompt_lines:
        print(prompt_lines[-1])


def cmd_week(handoff_path: pathlib.Path) -> None:
    text = handoff_path.read_text(encoding="utf-8")
    for r in parse_table(text, "## This week"):
        print(r[0])
        print("Your moves today:")
        for part in re.split(r";|\.(?:\s+|$)", r[1]):
            item = part.strip().rstrip(".")
            if item:
                print(f"- {item}")


def cmd_report(handoff_path: pathlib.Path, briefing_path: pathlib.Path, now_str: Optional[str]) -> None:
    h_text = handoff_path.read_text(encoding="utf-8")
    q_rows = [r for r in parse_table(h_text, "## Queue") if r and r[0].isdigit()]
    open_rows = parse_table(h_text, "## Open points")

    now = now_str or datetime.datetime.now().strftime("%a %m-%d %H:%M")
    lines = [
        "| # | Open item | Status | Checked | Your move? | When |",
        "|---|---|---|---|---|---|",
    ]
    idx = 1
    for r in q_rows:
        lane_parts = [p.strip() for p in r[3].split("+")]
        move = "yes" if "Feras" in lane_parts else "no"
        lines.append(f"| {idx} | {r[1][:60]} | {r[5]} | - | {move} | {r[5]} |")
        idx += 1
    for r in open_rows:
        move = "yes" if r[1].strip() == "Feras" else "no"
        when = r[2] if len(r) > 2 else "-"
        lines.append(f"| {idx} | {r[0][:60]} | open | - | {move} | {when} |")
        idx += 1

    b_text = briefing_path.read_text(encoding="utf-8")
    head, rest = b_text.split("## Open now", 1)
    next_idx = rest.find("\n## ")
    suffix = rest[next_idx:] if next_idx != -1 else ""
    table_content = "\n".join(lines)
    new_text = f"{head}## Open now ({now})\n{table_content}\n{suffix}"
    with open(briefing_path, "w", encoding="utf-8", newline="\n") as f:
        f.write(new_text)


def cmd_row(handoff_path: pathlib.Path, args: argparse.Namespace) -> None:
    original = handoff_path.read_bytes()
    text = original.decode("utf-8")
    parsed = parse_queue(text)
    if not parsed:
        sys.exit(1)
    prefix, rows, suffix = parsed
    data = [[c.strip() for c in r.split("|")[1:-1]] for r in rows if r.startswith("|")]

    if args.row_action == "add":
        max_id = max([int(r[0]) for r in data if r[0].isdigit()], default=0)
        new_row = [str(max_id + 1), args.task, args.dept, args.lane, args.who, args.status, args.blocked]
        if args.at is not None:
            data.insert(max(0, args.at - 1), new_row)
        else:
            data.append(new_row)
    elif args.row_action in ("set", "done"):
        idx = next((i for i, r in enumerate(data) if r[0] == args.row_id), None)
        if idx is None:
            sys.exit(1)
        if args.row_action == "done":
            data.pop(idx)
            for r in data:
                parts = [p.strip() for p in r[6].split(";") if p.strip() != args.row_id]
                r[6] = "; ".join(parts) if parts else "-"
        else:
            for field, col in [("task", 1), ("dept", 2), ("lane", 3), ("who", 4), ("status", 5), ("blocked", 6)]:
                val = getattr(args, field, None)
                if val is not None:
                    data[idx][col] = val

    new_rows = [f"| {' | '.join(r)} |" for r in data]
    new_text = prefix + "\n".join(new_rows) + "\n" + suffix
    with open(handoff_path, "w", encoding="utf-8", newline="\n") as f:
        f.write(new_text)
    check_and_restore(handoff_path, original)


def build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(prog="pm")
    p.add_argument("--handoff", default=str(REPO_ROOT / "HANDOFF.md"))
    p.add_argument("--briefing", default=str(REPO_ROOT / "feras" / "BRIEFING.md"))
    sub = p.add_subparsers(dest="cmd", required=True)

    sub.add_parser("board")
    sub.add_parser("next")

    p_row = sub.add_parser("row")
    rsub = p_row.add_subparsers(dest="row_action", required=True)
    p_add = rsub.add_parser("add")
    p_add.add_argument("--task", required=True)
    p_add.add_argument("--dept", required=True)
    p_add.add_argument("--lane", required=True)
    p_add.add_argument("--who", required=True)
    p_add.add_argument("--status", required=True)
    p_add.add_argument("--blocked", required=True)
    p_add.add_argument("--at", type=int, default=None)

    p_set = rsub.add_parser("set")
    p_set.add_argument("row_id")
    p_set.add_argument("--task")
    p_set.add_argument("--dept")
    p_set.add_argument("--lane")
    p_set.add_argument("--who")
    p_set.add_argument("--status")
    p_set.add_argument("--blocked")

    p_done = rsub.add_parser("done")
    p_done.add_argument("row_id")

    sub.add_parser("week")
    p_rep = sub.add_parser("report")
    p_rep.add_argument("--now", default=None)
    return p


def main(argv: Optional[List[str]] = None) -> int:
    args = build_parser().parse_args(argv)
    h_path = pathlib.Path(args.handoff)
    b_path = pathlib.Path(args.briefing)
    if args.cmd == "board":
        cmd_board(h_path)
    elif args.cmd == "next":
        cmd_next(h_path)
    elif args.cmd == "row":
        cmd_row(h_path, args)
    elif args.cmd == "week":
        cmd_week(h_path)
    elif args.cmd == "report":
        cmd_report(h_path, b_path, args.now)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
