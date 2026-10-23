#!/usr/bin/env python3
"""Checklist parsing and verification for build_gate."""
import os
import re


def check_item(wt, line):
    m = re.match(r"^-\s*file:\s*(.+)$", line)
    if m:
        return os.path.exists(os.path.join(wt, *m.group(1).strip().split("/")))
    m = re.match(r"^-\s*has:\s*(.+?)\s*::\s*(.*)$", line)
    if m:
        p = os.path.join(wt, *m.group(1).strip().split("/"))
        return os.path.exists(p) and m.group(2) in open(p, encoding="utf-8", errors="replace").read()
    m = re.match(r"^-\s*test:\s*(.+?)\s*::\s*(\w+)\s*$", line)
    if m:
        p = os.path.join(wt, *m.group(1).strip().split("/"))
        if not os.path.exists(p):
            return False
        c = open(p, encoding="utf-8", errors="replace").read()
        fn = m.group(2).strip()
        return f"func {fn}(" in c or f"def {fn}(" in c
    m = re.match(r"^-\s*key:\s*(.+?)\s*::\s*(.+)\s*$", line)
    if m:
        p = os.path.join(wt, *m.group(1).strip().split("/"))
        if not os.path.exists(p):
            return False
        prefix = f"{m.group(2).strip()},"
        return any(ln.startswith(prefix) for ln in open(p, encoding="utf-8", errors="replace").read().splitlines())
    return None


def brief_checklist(wt, brief_text):
    m = re.search(r"^## Checklist\s*$(.*?)(?=^## |\Z)", brief_text, re.M | re.S)
    if not m:
        return [], ["WARN no checklist in the brief"]
    misses, warns = [], []
    for raw in m.group(1).splitlines():
        line = raw.strip()
        if not line:
            continue
        res = check_item(wt, line)
        if res is None:
            warns.append(f"WARN checklist item not understood: {line}")
        elif not res:
            misses.append(line)
    return misses, warns
