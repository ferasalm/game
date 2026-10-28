#!/usr/bin/env python3
"""PreToolUse hook (D5, D21): blocks a game render sent to Feras unless review-player and review-feras stamped it.

Only SendUserFile and Artifact are inspected; any other tool, bad JSON or error exits 0. A stamp is
<REVIEW_STAMP_DIR>/<sha256>.json, written by review_stamp.py.
"""
import hashlib
import json
import os
import re
import subprocess
import sys

RENDER_NAME = re.compile(r"f\d{8}\.png$")
EXEMPT = ("inbox/flow/", "inbox/neon glitch concept art/")
MEDIA = (".png", ".jpg", ".jpeg", ".webp", ".gif", ".mp4", ".webm")  # a document in inbox/ is no render (review 10-28)


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


def is_render(path):
    p = path.replace("\\", "/").lower()
    segments = p.split("/")
    base = segments[-1]
    if not base.endswith(MEDIA):
        return False
    if "inbox" in segments:
        if any(x in p for x in EXEMPT) or base.startswith("concept_"):
            return False
        return True
    if ".bake" in segments:
        return True
    return base in ("contact.png", "clip.mp4") or bool(RENDER_NAME.search(base))


def paths_for(tool, tool_input):
    out = []
    if tool == "SendUserFile":
        for p in tool_input.get("files") or []:
            if isinstance(p, str):
                out.append(p)
        return out
    if isinstance(tool_input.get("file_path"), str):
        out.append(tool_input["file_path"])
    for p in tool_input.get("file_paths") or []:
        if isinstance(p, str):
            out.append(p)
    files = tool_input.get("files")
    if isinstance(files, dict):
        for v in files.values():
            if isinstance(v, str):
                out.append(v)
            elif isinstance(v, dict) and isinstance(v.get("from"), str):
                out.append(v["from"])
    elif isinstance(files, list):
        for v in files:
            if isinstance(v, str):
                out.append(v)
            elif isinstance(v, dict) and isinstance(v.get("path"), str):
                out.append(v["path"])
    return out


def stamped(path):
    with open(path, "rb") as f:
        digest = hashlib.sha256(f.read()).hexdigest()
    return os.path.isfile(os.path.join(stamp_dir(), digest + ".json"))


def main():
    data = json.load(sys.stdin)
    tool = data.get("tool_name")
    if tool not in ("SendUserFile", "Artifact"):
        return 0
    cwd = data.get("cwd") or os.getcwd()
    blocked = []
    for raw in paths_for(tool, data.get("tool_input") or {}):
        path = raw if os.path.isabs(raw) else os.path.join(cwd, raw)
        if not os.path.isfile(path) or not is_render(path):
            continue
        if not stamped(path):
            blocked.append(path)
    if blocked:
        for path in blocked:
            print(f"BLOCKED {path}: a game render needs review-player + review-feras first, then python "
                  f"tools/hooks/review_stamp.py {path} --player '<verdict>' --feras '<verdict>'", file=sys.stderr)
        return 2
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except Exception:
        sys.exit(0)
