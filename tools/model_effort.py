#!/usr/bin/env python3
"""Print the reasoning effort a model key runs at: opencode.json says it, the model's name does not (row 26 S2)."""
import json
import os
import re
import sys

WORDS = ("none", "low", "medium", "high", "max")
PREFIX = "cloudflare-workers-ai/"


def configured(model):
    """The model key's options.reasoning_effort under provider cloudflare-workers-ai, or None."""
    key = model[len(PREFIX):] if model.startswith(PREFIX) else model
    path = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "opencode.json")
    try:
        with open(path, encoding="utf-8") as f:
            models = json.load(f)["provider"]["cloudflare-workers-ai"]["models"]
        effort = models[key]["options"]["reasoning_effort"]
    except (OSError, ValueError, KeyError, TypeError):
        return None
    return effort if effort in WORDS else None


def from_name(model):
    """The last effort word in the name; -fast is none; nothing found is '-'."""
    parts = [p for p in re.split(r"[^a-z0-9]+", model.lower()) if p]
    found = [i for i, part in enumerate(parts) if part in WORDS or part == "fast"]
    if not found:
        return "-"
    word = parts[found[-1]]
    return "none" if word == "fast" else word


def main(argv):
    model = argv[1] if len(argv) > 1 else ""
    effort = configured(model) if model else None
    print(effort or from_name(model))
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
