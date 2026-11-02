#!/usr/bin/env python3
"""Read a run's token counts and cost from opencode's own session export (row 26 S2, Feras 11-02).

The builder log holds no token counts, so the meter asks `opencode session export`; unknown reads `?`, never 0.
"""
import argparse
import json
import os
import subprocess
import sys

DEFAULT_OC_BIN = "~/.local/opt/opencode-2.2.2/opencode.exe"
ZERO = {"sessions": 0, "input": 0, "output": 0, "reasoning": 0, "cache_read": 0, "cache_write": 0}
COUNTS = ("input", "output", "reasoning", "cache_read", "cache_write")
TIMEOUT = 60


def as_int(value):
    return value if isinstance(value, int) and not isinstance(value, bool) else 0


def tokens_of(obj):
    """info.tokens with defaults: a real export carries many fields this meter never reads."""
    info = obj.get("info") if isinstance(obj, dict) else None
    tok = info.get("tokens") if isinstance(info, dict) else None
    if not isinstance(tok, dict):
        return None
    cache = tok.get("cache") if isinstance(tok.get("cache"), dict) else {}
    return {"input": as_int(tok.get("input")), "output": as_int(tok.get("output")),
            "reasoning": as_int(tok.get("reasoning")), "cache_read": as_int(cache.get("read")),
            "cache_write": as_int(cache.get("write"))}


def add(total, tok):
    total["sessions"] += 1
    for name in COUNTS:
        total[name] += tok[name]


def parse_file(path):
    try:
        with open(path, encoding="utf-8", errors="replace") as f:
            return json.load(f)
    except (OSError, ValueError):
        return None


def emit(total):
    print(json.dumps({name: total[name] for name in ("sessions",) + COUNTS}))


def sum_cmd(args):
    total = dict(ZERO)
    for path in args.files:
        tok = tokens_of(parse_file(path))
        if tok is not None:  # a missing or unreadable export is skipped, never counted as a session
            add(total, tok)
    emit(total)
    return 0


def usd_text(value):
    """4 decimals rounded, trailing zeros dropped, at least two decimals kept (0.66, 0.0123, 0.00)."""
    text = f"{round(value, 4):.4f}".rstrip("0")
    whole, _, frac = text.partition(".")
    return f"{whole}.{(frac + '00')[:2] if len(frac) < 2 else frac}"


def fields_cmd(args):
    try:
        total = json.loads(sys.stdin.read() or "{}")
        sessions = as_int(total.get("sessions"))
    except (ValueError, AttributeError):
        sessions = 0
    if sessions <= 0:
        print("?,?,?")
        return 0
    inp = as_int(total.get("input"))
    out = as_int(total.get("output")) + as_int(total.get("reasoning"))
    usd = (inp * args.in_rate + out * args.out_rate) / 1e6
    print(f"{inp},{out},{usd_text(usd)}")
    return 0


def bash_call(script, *params, cwd=None):
    """Run a bash -c script with DIR and OC_BIN as positional parameters (never interpolated)."""
    argv = ["bash", "-c", script, "bash", *params]
    try:
        return subprocess.run(argv, cwd=cwd, capture_output=True, text=True, timeout=TIMEOUT,
                              encoding="utf-8", errors="replace")
    except (OSError, subprocess.SubprocessError):
        return None


def oc_settings():
    major = (os.environ.get("OC_MAJOR") or "2").strip()
    data = "oc-cli" if major == "1" else "oc-v2"
    flag = "" if major == "1" else " --standalone"
    return os.path.expanduser(os.environ.get("OC_BIN") or DEFAULT_OC_BIN), data, flag


def list_sessions(oc_bin, data, flag, wt):
    script = f'cd "$1" || exit 1; export XDG_DATA_HOME="$HOME/.local/share/{data}"; "$2" session list{flag}'
    res = bash_call(script, wt, oc_bin, cwd=wt)
    if res is None or res.returncode != 0:
        return []
    return [line.split("\t")[0] for line in res.stdout.splitlines() if line.startswith("ses_")]


def export_session(oc_bin, data, flag, wt, sid):
    script = f'export XDG_DATA_HOME="$HOME/.local/share/{data}"; "$1" session export{flag} "$2"'
    res = bash_call(script, oc_bin, sid, cwd=wt)
    if res is None or res.returncode != 0:
        return None
    try:
        return json.loads(res.stdout)
    except ValueError:
        return None


def collect_cmd(args):
    total = dict(ZERO)
    oc_bin, data, flag = oc_settings()
    ids = list_sessions(oc_bin, data, flag, args.wt) if os.path.isdir(args.wt) else []
    for sid in ids:
        tok = tokens_of(export_session(oc_bin, data, flag, args.wt, sid))
        if tok is None:  # a broken meter prints zero sessions and never fails the run
            emit(ZERO)
            return 0
        add(total, tok)
    emit(total)
    return 0


def main(argv=None):
    ap = argparse.ArgumentParser(description="Token counts and cost from opencode session exports")
    sub = ap.add_subparsers(dest="cmd", required=True)
    p_sum = sub.add_parser("sum")
    p_sum.add_argument("files", nargs="*")
    p_sum.set_defaults(func=sum_cmd)
    p_fields = sub.add_parser("fields")
    p_fields.add_argument("--in-rate", dest="in_rate", type=float, required=True)
    p_fields.add_argument("--out-rate", dest="out_rate", type=float, required=True)
    p_fields.set_defaults(func=fields_cmd)
    p_col = sub.add_parser("collect")
    p_col.add_argument("--wt", required=True)
    p_col.set_defaults(func=collect_cmd)
    args = ap.parse_args(argv)
    return args.func(args)


if __name__ == "__main__":
    raise SystemExit(main())
