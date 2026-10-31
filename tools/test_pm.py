#!/usr/bin/env python3
"""Self-test for plugins/pm/scripts/pm.py (row 23 a, 2026-11-01): board, next, row add|set|done, week, report.
Runs on fixture copies of HANDOFF.md and BRIEFING.md in a temp dir; PM_DOC_CHECK is the doc_check command (a stub here)."""
import json
import os
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__))).replace("\\", "/")
PM = ROOT + "/plugins/pm/scripts/pm.py"

HANDOFF = """# HANDOFF (current state only; ONE queue for every chat; max 60 lines)
Last updated: 2026-11-01 (fixture).

## How this file works
- One queue, top row first.

## Queue
| # | Task (brief or doc) | Dept | Lane | Who | Status | Blocked by |
|---|---|---|---|---|---|---|
| 23 | pm plugin and one-call handoff | Ops | builder + chat (review) | agy, cf; Sonnet high | next: Sun 11-01 | - |
| 24 | One home for every rule | Ops | builder + chat (review) | agy, cf; Sonnet high | Mon 11-02 | 23 |
| 25 | Opus gate on system-v3 | Ops | chat (review) | Opus high | Mon 11-02 | 24 |
| 3 | M1 brief | Gameplay | chat (plan) | Opus high | Tue 11-03 | 25 |
| 4 | M1 build | Gameplay | builder | agy | after row 3 | 3 |
| 6 | Bake Roya | Art | chat (MCP) | Opus high | after row 3 | 3 |
| 5 | Feras plays M1 on PC and phone | QA | Feras | - | later: after row 4 | 4 |
Key: builders are free code bots.

## Open points
| Point | Owner | Since |
|---|---|---|
| Bilqis portraits: keep or overturn | Feras | 10-27 |
| Cleanup of old worktrees | Claude | 10-31 |

## This week (weekly limit resets Sat 16:00 GMT+3)
| Day | Plan |
|---|---|
| Sun 11-01 | Row 22 done; row 23 (Sonnet high, one paste). |
| Mon 11-02 | Row 24 (Sonnet high), then row 25 (Opus gate). Hard stop 23:59. |
| Tue 11-03 | M1 brief (row 3); M1 build (row 4) overnight. |

## Prompt for the next chat
Type `/model sonnet`, then paste this as one message:
`/goal Row 23 is finished: every Done-when line is true. How: you are Sonnet high.`
"""

BRIEFING = """# BRIEFING
Intro line kept.

## Open now (Sun 11-01 01:50)
| # | Open item | Status | Checked | Your move? | When |
|---|---|---|---|---|---|
| 0 | old row | old | old | no | old |

## Report Sun 11-01 01:50 (GMT+3)
Done: kept byte for byte.
"""

OK_STUB = "import sys\nsys.exit(0)\n"
BAD_STUB = "import sys\nprint('FAIL fixture')\nsys.exit(1)\n"


def setup(doc_check_ok=True):
    d = tempfile.mkdtemp().replace("\\", "/")
    for name, text in (("HANDOFF.md", HANDOFF), ("BRIEFING.md", BRIEFING), ("ok.py", OK_STUB), ("bad.py", BAD_STUB)):
        with open(f"{d}/{name}", "w", encoding="utf-8", newline="\n") as f:
            f.write(text)
    return d, f"{d}/{'ok' if doc_check_ok else 'bad'}.py"


def pm(d, stub, *args):
    env = {**os.environ, "PM_DOC_CHECK": f'"{sys.executable}" "{stub}"'}
    return subprocess.run([sys.executable, PM, "--handoff", f"{d}/HANDOFF.md", "--briefing", f"{d}/BRIEFING.md", *args],
                          capture_output=True, text=True, env=env, encoding="utf-8")


def read(d, name="HANDOFF.md"):
    with open(f"{d}/{name}", encoding="utf-8", newline="") as f:
        return f.read()


def section(out, head):
    """The lines under an '== head' line up to the next '== ' line."""
    part = out.split(f"== {head}", 1)[1].split("\n== ", 1)[0]
    return part.splitlines()[1:]


def test_board_has_top_five_rows_open_points_week_and_feras_moves():
    d, ok = setup()
    r = pm(d, ok, "board")
    assert r.returncode == 0, r.stderr
    queue = section(r.stdout, "Queue")
    nums = [l.split()[0] for l in queue if l.startswith("#")]
    assert nums == ["#23", "#24", "#25", "#3", "#4"], queue
    assert all("|" in l for l in queue if l.startswith("#")), "row line: #N | Dept | task | Who | Status"
    assert any("Bilqis" in l for l in section(r.stdout, "Open points"))
    assert any("Sun 11-01" in l for l in section(r.stdout, "This week"))
    moves = "\n".join(section(r.stdout, "Your moves"))
    assert "#5" in moves and "Bilqis" in moves and "#23" not in moves and "Cleanup" not in moves, moves


def test_next_prints_the_top_row_and_the_paste_ready_prompt():
    d, ok = setup()
    r = pm(d, ok, "next")
    assert r.returncode == 0, r.stderr
    lines = r.stdout.splitlines()
    assert lines[0].startswith("#23 "), lines[0]
    assert "/goal Row 23 is finished" in r.stdout and "`" not in r.stdout.split("/goal", 1)[1], r.stdout
    assert any(l.startswith("/goal ") for l in lines), "the prompt sits on its own line"


def test_row_add_set_done_edit_only_their_row():
    d, ok = setup()
    r = pm(d, ok, "row", "add", "--task", "Tool X", "--dept", "Ops", "--lane", "builder", "--who", "cf",
           "--status", "next", "--blocked", "-")
    assert r.returncode == 0, r.stderr
    assert "| 26 | Tool X | Ops | builder | cf | next | - |" in read(d)
    r = pm(d, ok, "row", "set", "24", "--status", "Tue 11-03")
    assert r.returncode == 0, r.stderr
    assert "| 24 | One home for every rule | Ops | builder + chat (review) | agy, cf; Sonnet high | Tue 11-03 | 23 |" in read(d)
    r = pm(d, ok, "row", "add", "--task", "Top", "--dept", "Ops", "--lane", "builder", "--who", "agy",
           "--status", "now", "--blocked", "-", "--at", "1")
    assert r.returncode == 0, r.stderr
    assert pm(d, ok, "next").stdout.startswith("#27 "), "--at 1 puts the new row first"
    r = pm(d, ok, "row", "done", "23")
    assert r.returncode == 0, r.stderr
    after = read(d)
    assert "| 23 |" not in after and "| 25 |" in after and after.count("| 26 |") == 1


def test_row_edit_is_restored_when_doc_check_fails():
    d, bad = setup(doc_check_ok=False)
    before = read(d)
    for args in (("row", "set", "23", "--status", "x"), ("row", "done", "23"),
                 ("row", "add", "--task", "T", "--dept", "Ops", "--lane", "builder", "--who", "cf", "--status", "s", "--blocked", "-")):
        r = pm(d, bad, *args)
        assert r.returncode != 0 and "doc_check" in (r.stdout + r.stderr), (args, r.stdout, r.stderr)
        assert read(d) == before, f"HANDOFF.md must be restored after a failed {args[:2]}"


def test_row_set_unknown_row_fails_without_touching_the_file():
    d, ok = setup()
    before = read(d)
    r = pm(d, ok, "row", "set", "99", "--status", "x")
    assert r.returncode != 0 and read(d) == before


def test_week_prints_one_your_moves_today_list_per_day():
    d, ok = setup()
    r = pm(d, ok, "week")
    assert r.returncode == 0, r.stderr
    assert r.stdout.count("Your moves today:") == 3, r.stdout
    first = r.stdout.split("Your moves today:")[0]
    assert "Sun 11-01" in first
    day2 = r.stdout.split("Your moves today:")[2]
    assert "- Row 24 (Sonnet high)" in day2 and "- Hard stop 23:59" in day2, day2


def test_report_rewrites_only_the_open_now_table():
    d, ok = setup()
    r = pm(d, ok, "report", "--now", "Sun 11-01 12:30")
    assert r.returncode == 0, r.stderr
    out = read(d, "BRIEFING.md")
    assert "## Open now (Sun 11-01 12:30)" in out and "| 0 | old row |" not in out
    assert "| # | Open item | Status | Checked | Your move? | When |" in out
    assert out.startswith("# BRIEFING\nIntro line kept.\n")
    assert out.endswith(BRIEFING[BRIEFING.index("## Report"):]), "everything after the table stays byte for byte"
    rows = {l.split("|")[2].strip(): [c.strip() for c in l.strip().split("|")[1:-1]]
            for l in out.splitlines() if l.startswith("| ") and "---" not in l and not l.startswith("| # ")}
    assert any("Feras plays M1" in k for k in rows) and any("Bilqis" in k for k in rows)
    feras_row = next(v for k, v in rows.items() if "Feras plays M1" in k)
    own_row = next(v for k, v in rows.items() if "M1 build" in k)
    assert feras_row[4] == "yes" and own_row[4] == "no", (feras_row, own_row)
    assert next(v for k, v in rows.items() if "Bilqis" in k)[4] == "yes"
    assert next(v for k, v in rows.items() if "Cleanup" in k)[4] == "no"


def test_real_handoff_board_and_next_run_read_only():
    real = ROOT + "/HANDOFF.md"
    before = open(real, encoding="utf-8", newline="").read()
    for cmd in ("board", "next", "week"):
        r = subprocess.run([sys.executable, PM, "--handoff", real, cmd], capture_output=True, text=True, encoding="utf-8")
        assert r.returncode == 0 and r.stdout.strip(), (cmd, r.stderr)
    assert open(real, encoding="utf-8", newline="").read() == before, "read commands never write"


def test_plugin_files_and_five_short_skills():
    with open(ROOT + "/plugins/pm/.claude-plugin/plugin.json", encoding="utf-8") as f:
        assert json.load(f)["name"] == "pm"
    with open(ROOT + "/.claude-plugin/marketplace.json", encoding="utf-8") as f:
        assert "pm" in [p["name"] for p in json.load(f)["plugins"]]
    for skill in ("status", "next", "row", "week", "report"):
        text = open(f"{ROOT}/plugins/pm/skills/{skill}/SKILL.md", encoding="utf-8").read()
        assert len(text.splitlines()) <= 15, f"{skill} has more than 15 lines"
        assert text.startswith("---\nname:") and "description:" in text and "pm.py" in text, skill


if __name__ == "__main__":
    from tool_tests import run_cases
    run_cases([v for k, v in sorted(globals().items()) if k.startswith("test_")], "test_pm")
