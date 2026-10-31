#!/usr/bin/env python3
"""Table parsing and queue extraction helpers for pm CLI (row 23)."""
import os
import pathlib
import re
import shlex
import subprocess
import sys
from typing import List, Optional, Tuple

REPO_ROOT = pathlib.Path(__file__).resolve().parent.parent.parent


def parse_table(text: str, heading: str) -> List[List[str]]:
    """Return rows of first table under heading (header dropped, stripped cells)."""
    if heading not in text:
        return []
    part = text.split(heading, 1)[-1].split("\n## ", 1)[0]
    lines = [l for l in part.splitlines() if l.startswith("|") and not re.fullmatch(r"\|[-: |]+\|", l.strip())]
    rows = [[c.strip() for c in l.strip().split("|")[1:-1]] for l in lines]
    return rows[1:] if len(rows) > 1 else []


def parse_queue(text: str) -> Optional[Tuple[str, List[str], str]]:
    """Splits text around Queue table data rows into (prefix, data_lines, suffix)."""
    if "## Queue" not in text:
        return None
    q_part = text.split("## Queue", 1)[1]
    head_part = text[:len(text) - len(q_part)]
    lines = q_part.splitlines(keepends=True)
    sep_idx = -1
    for i, line in enumerate(lines):
        if re.fullmatch(r"\|[-: |]+\|\r?\n?", line.strip()):
            sep_idx = i
            break
    if sep_idx == -1:
        return None
    end_idx = sep_idx + 1
    while end_idx < len(lines) and lines[end_idx].startswith("|"):
        end_idx += 1
    prefix = head_part + "".join(lines[:sep_idx + 1])
    data_lines = [l.strip() for l in lines[sep_idx + 1:end_idx]]
    suffix = "".join(lines[end_idx:])
    return prefix, data_lines, suffix


def check_and_restore(handoff_path: pathlib.Path, original: bytes) -> None:
    """Runs doc_check and restores handoff file on non-zero exit."""
    default_cmd = f'"{sys.executable}" "{REPO_ROOT / "tools" / "doc_check.py"}"'
    raw_cmd = os.environ.get("PM_DOC_CHECK", default_cmd)
    try:
        cmd = shlex.split(raw_cmd)
    except ValueError:
        cmd = shlex.split(raw_cmd, posix=False)
    res = subprocess.run(cmd, capture_output=True, text=True)
    if res.returncode != 0:
        handoff_path.write_bytes(original)
        if res.stdout:
            sys.stdout.write(res.stdout)
        if res.stderr:
            sys.stderr.write(res.stderr)
        print("doc_check failed: restored HANDOFF.md", file=sys.stderr)
        sys.exit(1)
