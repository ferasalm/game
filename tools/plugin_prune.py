#!/usr/bin/env python3
"""Removes plugin registry entries whose project folder is gone (row 26 S7, Feras 11-02: `claude plugin list` showed
kaizen eight times, two for removed worktrees; a local install is keyed by project path and nothing cleaned it up).
Dead = an entry with a projectPath whose folder is missing; no projectPath (user scope) is never dead. Dry run by default;
--apply backs up to <file>.<UTC yyyymmddThhmmss>.bak, writes indent-2 JSON in key order, drops empty plugins, and exits 2
on a missing or unparseable file, naming it. Tests: tools/test_plugin_prune.py."""
import argparse
import json
import os
import shutil
import sys
import time


def load(path: str):
    """The parsed registry, or None after printing why it cannot be read (missing, unparseable or shapeless)."""
    try:
        with open(path, encoding="utf-8") as f:
            data = json.load(f)
        if not isinstance(data, dict) or not isinstance(data.get("plugins"), dict):
            raise ValueError("no plugins object")
    except (OSError, ValueError) as exc:
        print("plugin_prune: cannot read %s: %s" % (path, exc), file=sys.stderr)
        return None
    return data


def is_dead(entry) -> bool:
    """A project-scoped entry is dead when its folder is gone; an entry without a projectPath is never dead."""
    path = entry.get("projectPath") if isinstance(entry, dict) else None
    return bool(path) and not os.path.isdir(str(path))


def prune(data: dict) -> list:
    """Drops dead entries in place; returns [(plugin, scope, projectPath)] and drops a plugin left with no entries."""
    removed = []
    plugins = data["plugins"]
    for name in list(plugins):
        entries = plugins[name] if isinstance(plugins[name], list) else []
        kept, dead = [], 0
        for entry in entries:
            if is_dead(entry):
                dead += 1
                removed.append((name, entry.get("scope", "?"), entry["projectPath"]))
            else:
                kept.append(entry)
        if dead:
            plugins[name] = kept
            if not kept:
                del plugins[name]
    return removed


def write(path: str, data: dict) -> str:
    """Backs the registry up to <file>.<UTC yyyymmddThhmmss>.bak, then writes indent-2 JSON with LF newlines."""
    dest = "%s.%s.bak" % (path, time.strftime("%Y%m%dT%H%M%S", time.gmtime()))
    shutil.copy2(path, dest)
    with open(path, "w", encoding="utf-8", newline="\n") as f:
        json.dump(data, f, indent=2)
    return dest


def main(argv=None) -> int:
    ap = argparse.ArgumentParser(description="Remove plugin registry entries whose project folder is gone.")
    ap.add_argument("--file", default="~/.claude/plugins/installed_plugins.json", help="registry path (default: %(default)s)")
    ap.add_argument("--apply", action="store_true", help="write the pruned registry after backing it up")
    args = ap.parse_args(argv)
    path = os.path.expanduser(args.file)
    data = load(path)
    if data is None:
        return 2
    removed = prune(data)
    if not args.apply:
        print("dry run:")
        for name, scope, project in removed:
            print("  %s  %s  %s" % (name, scope, project))
        print("nothing changed")
        return 0
    if not removed:
        print("nothing changed")
        return 0
    saved = write(path, data)
    for name, scope, project in removed:
        print("removed %s  %s  %s" % (name, scope, project))
    print("backup: %s" % saved)
    return 0


if __name__ == "__main__":
    sys.exit(main())
