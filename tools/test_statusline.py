#!/usr/bin/env python3
"""Self-test for tools/statusline.py (row 23 e, 2026-11-01). Field names are from the official statusline docs (fetched 11-01):
rate_limits.five_hour|seven_day.{used_percentage 0-100, resets_at epoch seconds}, context_window.used_percentage, model.display_name,
workspace.project_dir. The raw payload is also kept in .check/statusline_raw.json so the first real run confirms the names."""
import json
import os
import subprocess
import sys
import tempfile
import time

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__))).replace("\\", "/")
LINE = ROOT + "/tools/statusline.py"
HOOK = ROOT + "/tools/hooks/token_handoff.py"


def run(payload, raw=None):
    d = tempfile.mkdtemp().replace("\\", "/")
    data = raw if raw is not None else json.dumps({**payload, "workspace": {"project_dir": d, "current_dir": d}})
    r = subprocess.run([sys.executable, LINE], input=data, capture_output=True, text=True, encoding="utf-8")
    return d, r


FULL = {"session_id": "s1", "model": {"id": "claude-sonnet-5-5", "display_name": "Sonnet 5.5"},
        "context_window": {"used_percentage": 12.4},
        "rate_limits": {"five_hour": {"used_percentage": 23.5, "resets_at": 1893456000},
                        "seven_day": {"used_percentage": 41, "resets_at": 1893999999}}}


def test_one_line_with_model_context_and_both_windows():
    d, r = run(FULL)
    assert r.returncode == 0 and len(r.stdout.strip().splitlines()) == 1, (r.stdout, r.stderr)
    line = r.stdout
    assert "Sonnet 5.5" in line and "ctx 12%" in line and "5h 24%" in line and "7d 41%" in line, line


def test_usage_json_written_with_the_numbers():
    d, r = run(FULL)
    u = json.load(open(d + "/.check/usage.json", encoding="utf-8"))
    assert u["five_hour_pct"] == 23.5 and u["seven_day_pct"] == 41 and u["context_pct"] == 12.4, u
    assert u["five_hour_resets_at"] == 1893456000 and u["session_id"] == "s1" and abs(u["updated"] - time.time()) < 60, u
    assert json.load(open(d + "/.check/statusline_raw.json", encoding="utf-8"))["model"]["id"] == "claude-sonnet-5-5"


def test_missing_windows_and_nulls_never_crash():
    d, r = run({"model": {"display_name": "Haiku 5.5"}, "context_window": {"used_percentage": None}})
    assert r.returncode == 0 and "Haiku 5.5" in r.stdout and "5h" not in r.stdout, (r.stdout, r.stderr)
    u = json.load(open(d + "/.check/usage.json", encoding="utf-8"))
    assert u["five_hour_pct"] is None and u["seven_day_pct"] is None


def test_bad_input_prints_a_line_and_exits_zero():
    for raw in ("", "not json", "[1]"):
        d, r = run(None, raw=raw)
        assert r.returncode == 0 and r.stdout.strip(), (raw, r.stdout, r.stderr)


def hook(cwd, total, usage=None):
    """Runs token_handoff on a transcript whose cache reads already pass 25M; returns the hook's stdout."""
    tr = cwd + "/t.jsonl"
    line = {"type": "assistant", "message": {"id": "m1", "role": "assistant", "usage": {"cache_read_input_tokens": total}}}
    open(tr, "w", encoding="utf-8").write(json.dumps(line) + "\n")
    if usage is not None:
        os.makedirs(cwd + "/.check", exist_ok=True)
        json.dump(usage, open(cwd + "/.check/usage.json", "w", encoding="utf-8"))
    env = {**os.environ, "TOKEN_HANDOFF_STATE_DIR": tempfile.mkdtemp(), "TOKEN_HANDOFF_STEP_BYTES": "1"}
    p = subprocess.run([sys.executable, HOOK], input=json.dumps({"transcript_path": tr, "session_id": "x", "cwd": cwd}),
                       capture_output=True, text=True, encoding="utf-8", env=env)
    return p.stdout


def test_token_handoff_adds_the_five_hour_figure_when_fresh():
    d = tempfile.mkdtemp().replace("\\", "/")
    out = hook(d, 26_000_000, {"five_hour_pct": 61.0, "seven_day_pct": 20, "updated": time.time()})
    assert "Cache reads" in out and "5-hour window 61%" in out, out


def test_token_handoff_ignores_stale_or_missing_usage():
    d = tempfile.mkdtemp().replace("\\", "/")
    assert "5-hour window" not in hook(d, 26_000_000)
    d2 = tempfile.mkdtemp().replace("\\", "/")
    out = hook(d2, 26_000_000, {"five_hour_pct": 61.0, "updated": time.time() - 3 * 3600})
    assert "Cache reads" in out and "5-hour window" not in out, out


def test_wiring_text_is_tool_neutral():
    for path in ("CLAUDE.md", "docs/WORKFLOW.md"):
        assert "get_usage" not in open(f"{ROOT}/{path}", encoding="utf-8").read(), path
    gate = open(ROOT + "/tools/hooks/review_gate.py", encoding="utf-8").read()
    assert '"SendUserFile"' in gate and '"Artifact"' in gate, "the review gate matcher keeps working"


if __name__ == "__main__":
    from tool_tests import run_cases
    run_cases([v for k, v in sorted(globals().items()) if k.startswith("test_")], "test_statusline")
