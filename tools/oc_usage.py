#!/usr/bin/env python3
"""Read a run's token counts and cost from opencode's own session export (row 26 S2, Feras 11-02)."""
import argparse
import json
import os
import subprocess
import sys

DEFAULT_OC_BIN = "~/.local/opt/opencode-2.2.2/opencode.exe"
COUNTS = ("input", "output", "reasoning", "cache_read", "cache_write")
ZERO = {"sessions": 0, "input": 0, "output": 0, "reasoning": 0, "cache_read": 0, "cache_write": 0}


def as_int(value):
    return value if isinstance(value, int) and not isinstance(value, bool) else 0


def tokens_of(obj):
    """info.tokens with defaults: a real export carries many fields this meter never reads."""
    info = obj.get("info") if isinstance(obj, dict) else None
    tok = info.get("tokens") if isinstance(info, dict) else None
    if not isinstance(tok, dict):
        return None
    cache = tok.get("cache") if isinstance(tok.get("cache"), dict) else {}
    return dict(zip(COUNTS, map(as_int, (tok.get("input"), tok.get("output"), tok.get("reasoning"),
                                         cache.get("read"), cache.get("write")))))


def total_of(tokens):
    total = dict(ZERO)
    for tok in tokens:
        total["sessions"] += 1
        for name in COUNTS:
            total[name] += tok[name]
    return total


def sum_cmd(args):
    tokens = []
    for path in args.files:
        try:
            with open(path, encoding="utf-8", errors="replace") as f:
                tok = tokens_of(json.load(f))
        except (OSError, ValueError):
            continue  # a missing or unreadable export is skipped, never counted as a session
        if tok is not None:
            tokens.append(tok)
    print(json.dumps(total_of(tokens)))
    return 0


def usd_text(value):  # rounded to 4 decimals, trailing zeros dropped, two decimals kept
    whole, _, frac = f"{round(value, 4):.4f}".rstrip("0").partition(".")
    return f"{whole}.{(frac + '00')[:2] if len(frac) < 2 else frac}"


def fields_cmd(args):
    try:
        total = json.loads(sys.stdin.read() or "{}")
    except ValueError:
        total = None
    if not isinstance(total, dict) or as_int(total.get("sessions")) <= 0:
        print("?,?,?")
        return 0
    inp, out = as_int(total.get("input")), as_int(total.get("output")) + as_int(total.get("reasoning"))
    print(f"{inp},{out},{usd_text((inp * args.in_rate + out * args.out_rate) / 1e6)}")
    return 0


def oc_call(wt, oc_bin, data, *cmd):
    """One opencode call inside the worktree; its paths travel as positional parameters, never in the script text."""
    script = f'cd "$1" || exit 1; export XDG_DATA_HOME="$HOME/.local/share/{data}"; shift; "$@"'
    try:
        return subprocess.run(["bash", "-c", script, "bash", wt, oc_bin, *cmd], cwd=wt, capture_output=True,
                              text=True, timeout=60, encoding="utf-8", errors="replace")
    except (OSError, subprocess.SubprocessError):
        return None


def collect_cmd(args):
    major = (os.environ.get("OC_MAJOR") or "2").strip()
    data, standalone = ("oc-cli", ()) if major == "1" else ("oc-v2", ("--standalone",))
    oc_bin = os.path.expanduser(os.environ.get("OC_BIN") or DEFAULT_OC_BIN)
    listing = oc_call(args.wt, oc_bin, data, "session", "list", *standalone)
    ids = [line.split("\t")[0] for line in (listing.stdout if listing and listing.returncode == 0 else "").splitlines()
           if line.startswith("ses_")]
    tokens = []
    for sid in ids:
        res = oc_call(args.wt, oc_bin, data, "session", "export", *standalone, sid)
        try:
            tok = tokens_of(json.loads(res.stdout)) if res is not None and res.returncode == 0 else None
        except ValueError:
            tok = None
        if tok is None:  # a broken meter prints zero sessions and never fails the run
            print(json.dumps(ZERO))
            return 0
        tokens.append(tok)
    print(json.dumps(total_of(tokens)))
    return 0


def main(argv=None):
    ap = argparse.ArgumentParser(description="Token counts and cost from opencode session exports")
    sub = ap.add_subparsers(dest="cmd", required=True)
    specs = {"sum": (sum_cmd, [("files", {"nargs": "*"})]),
             "fields": (fields_cmd, [("--in-rate", {"dest": "in_rate", "type": float, "required": True}),
                                     ("--out-rate", {"dest": "out_rate", "type": float, "required": True})]),
             "collect": (collect_cmd, [("--wt", {"required": True})])}
    for name, (func, flags) in specs.items():
        parser = sub.add_parser(name)
        for flag, kwargs in flags:
            parser.add_argument(flag, **kwargs)
        parser.set_defaults(func=func)
    args = ap.parse_args(argv)
    return args.func(args)


if __name__ == "__main__":
    raise SystemExit(main())
