#!/usr/bin/env python3
"""Row 26 S7 (Feras 11-02, asked and agreed): `claude plugin list` showed kaizen@kaizen eight times, two of them for
worktrees that no longer exist (a local-scope install is keyed by project path and merge_run removes the worktree
without telling the registry). tools/plugin_prune.py removes only entries whose projectPath is gone, backs the file up
first, and changes nothing unless told --apply."""
import json
import os
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
PRUNE = os.path.join(HERE, "plugin_prune.py")


def registry(live, gone):
    def entry(scope, path):
        e = {"scope": scope, "installPath": "C:/cache/kaizen/2.0.0", "version": "2.0.0"}
        if path:
            e["projectPath"] = path
        return e
    return {"version": 2, "plugins": {
        "kaizen@kaizen": [entry("project", live), entry("local", live), entry("local", gone)],
        "claude-md-management@claude-plugins-official": [entry("user", None)],
    }}


def run(reg_path, *args):
    return subprocess.run([sys.executable, PRUNE, "--file", reg_path, *args], capture_output=True, text=True, timeout=60)


def setup(d):
    live = os.path.join(d, "live-project")
    os.makedirs(live)
    gone = os.path.join(d, "deleted-worktree")  # never created
    p = os.path.join(d, "installed_plugins.json")
    with open(p, "w", encoding="utf-8", newline="\n") as f:
        json.dump(registry(live, gone), f, indent=2)
    return p, live, gone


def test_dry_run_names_the_dead_entry_and_changes_nothing():
    with tempfile.TemporaryDirectory() as d:
        p, live, gone = setup(d)
        before = open(p, encoding="utf-8").read()
        r = run(p)
        assert r.returncode == 0, r.stderr
        assert gone in r.stdout and live not in r.stdout, r.stdout
        assert "dry run" in r.stdout.lower(), r.stdout
        assert open(p, encoding="utf-8").read() == before
        assert not [f for f in os.listdir(d) if f.endswith(".bak")]


def test_apply_removes_only_dead_paths_and_keeps_a_backup():
    with tempfile.TemporaryDirectory() as d:
        p, live, gone = setup(d)
        before = open(p, encoding="utf-8").read()
        r = run(p, "--apply")
        assert r.returncode == 0, r.stderr
        data = json.load(open(p, encoding="utf-8"))
        kept = data["plugins"]["kaizen@kaizen"]
        assert [e["scope"] for e in kept] == ["project", "local"] and all(e["projectPath"] == live for e in kept), kept
        assert len(data["plugins"]["claude-md-management@claude-plugins-official"]) == 1  # a user-scope entry has no path
        baks = [f for f in os.listdir(d) if f.endswith(".bak")]
        assert len(baks) == 1 and open(os.path.join(d, baks[0]), encoding="utf-8").read() == before


def test_a_plugin_left_with_no_entries_is_dropped_and_a_missing_file_is_an_error():
    with tempfile.TemporaryDirectory() as d:
        p = os.path.join(d, "installed_plugins.json")
        with open(p, "w", encoding="utf-8", newline="\n") as f:
            json.dump({"version": 2, "plugins": {"x@y": [{"scope": "local", "projectPath": os.path.join(d, "nope")}]}}, f)
        assert run(p, "--apply").returncode == 0
        assert json.load(open(p, encoding="utf-8"))["plugins"] == {}
        r = run(os.path.join(d, "missing.json"))
        assert r.returncode != 0 and "missing.json" in (r.stdout + r.stderr)


if __name__ == "__main__":
    from tool_tests import run_cases
    run_cases([v for k, v in sorted(globals().items()) if k.startswith("test_")], "test_plugin_prune")
