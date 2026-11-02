#!/usr/bin/env python3
"""Row 26 P2 locked tests for tools/kaizen_report.py: one Kaizen line per batch in at most 20 lines.
Each test writes a runs.csv in a temp dir and asserts the exact lines docs/briefs/row26-p2-kaizen.md specifies:
the header, one line per worker/effort group with unknown cells left out, the tune lines in order, and the cap."""
import os
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
REPORT = os.path.join(HERE, "kaizen_report.py")
HEADER = ("date,task,worker,effort,gate,fix_passes,minutes,cost,real_findings,tokens_in,tokens_out,usd_est,"
          "cost_source,idle_min")
OLD_HEADER = "date,task,worker,effort,gate,fix_passes,minutes,cost,real_findings"


def row(date="2026-10-01", worker="cf", effort="max", gate="PASS", fix=0, minutes=10, tokens_in=100,
        tokens_out=10, usd="0.01", idle=0, cost_source="opencode-export"):
    """One 14-column runs.csv row, with the boring cells defaulted."""
    return [date, "job", worker, effort, gate, fix, minutes, 0, 0, tokens_in, tokens_out, usd, cost_source, idle]


def run(d, rows=None, *args, header=HEADER, raw=None):
    """Write the csv (raw text, or header plus rows) and return kaizen_report's lines; no file means a missing csv."""
    path = os.path.join(d, "runs.csv")
    if raw is None and rows is not None:
        raw = header + "\n" + "".join(",".join(str(cell) for cell in r) + "\n" for r in rows)
    if raw is not None:
        with open(path, "w", encoding="utf-8", newline="") as f:
            f.write(raw)
    r = subprocess.run([sys.executable, REPORT, "--csv", path, *args], capture_output=True, text=True, timeout=60)
    assert r.returncode == 0, (r.stdout, r.stderr)
    return r.stdout.splitlines()


def test_groups_are_sorted_and_summed_with_unknowns_left_out():
    rows = [
        row(date="2026-10-01", fix=1, minutes=20, tokens_in=1000, tokens_out=100, usd="0.01", idle=2),
        row(date="2026-10-02", fix=2, minutes=30, tokens_in=2000, tokens_out=300, usd="0.02", idle=3),
        row(date="2026-10-03", gate="FAIL", minutes=10, tokens_in="?", tokens_out=50, usd="?", idle="?",
            cost_source="unknown"),
        row(date="2026-10-04", fix=1, minutes=20, tokens_in=500, tokens_out=50, usd="0.01", idle=5),
        row(date="2026-10-05", worker="agy", effort="-", minutes=25, tokens_in="?", tokens_out="?", usd="?",
            idle=1, cost_source="unknown"),
        row(date="2026-10-06", worker="agy", effort="-", gate="FAIL", minutes=35, tokens_in="?", tokens_out="?",
            usd="?", idle=2, cost_source="unknown"),
        row(date="2026-10-07", worker="glm", effort="high", fix=3, minutes=45, tokens_in=800, tokens_out=80),
    ]
    with tempfile.TemporaryDirectory() as d:
        lines = run(d, rows)
    assert lines == [
        "KAIZEN 7 runs, 2026-10-01..2026-10-07",
        "cf/max  runs 4  pass 75%  min avg 20.0  fix avg 1.0  idle 10 min  tok 3500/500  usd 0.04 (1 unknown)",
        "agy/-  runs 2  pass 50%  min avg 30.0  fix avg 0.0  idle 3 min  tok ?/?  usd ? (2 unknown)",
        "glm/high  runs 1  pass 100%  min avg 45.0  fix avg 3.0  idle 0 min  tok 800/80  usd 0.01 (0 unknown)",
        "tune: 3 row(s) have no cost reading (older runs or non-opencode builders)",
    ]


def test_an_old_nine_column_file_reads_every_new_column_as_unknown():
    old = [["2026-09-01", "job", "cf", "max", "PASS", 0, 20, 0, 0]]
    with tempfile.TemporaryDirectory() as d:
        lines = run(d, old, header=OLD_HEADER)
    assert lines == [
        "KAIZEN 1 runs, 2026-09-01..2026-09-01",
        "cf/max  runs 1  pass 100%  min avg 20.0  fix avg 0.0  idle ? min  tok ?/?  usd ? (1 unknown)",
        "tune: 1 row(s) have no cost reading (older runs or non-opencode builders)",
    ]


def test_since_filters_by_date_and_the_header_names_the_range():
    rows = [
        row(date="2026-10-04", minutes=10, tokens_in=100, tokens_out=10, usd="0.01", idle=1),
        row(date="2026-10-05", minutes=20, tokens_in=200, tokens_out=20, usd="0.02", idle=2),
        row(date="2026-10-09", minutes=30, tokens_in=300, tokens_out=30, usd="0.03", idle=3),
    ]
    with tempfile.TemporaryDirectory() as d:
        all_lines = run(d, rows)
        since_lines = run(d, rows, "--since", "2026-10-05")
    assert all_lines[0] == "KAIZEN 3 runs, 2026-10-04..2026-10-09", all_lines
    assert "tok 600/60" in all_lines[1], all_lines
    assert since_lines == [
        "KAIZEN 2 runs, 2026-10-05..2026-10-09",
        "cf/max  runs 2  pass 100%  min avg 25.0  fix avg 0.0  idle 5 min  tok 500/50  usd 0.05 (0 unknown)",
    ], since_lines


def test_empty_or_missing_csv_reads_kaizen_0_runs():
    with tempfile.TemporaryDirectory() as d:
        assert run(d, None) == ["KAIZEN 0 runs"]
        assert run(d, raw="") == ["KAIZEN 0 runs"]
        assert run(d, raw=HEADER + "\n") == ["KAIZEN 0 runs"]


def test_the_idle_tune_fires_at_ten_minutes_and_fifteen_percent():
    ten = [row(date=f"2026-10-0{i}", minutes=10, idle=i) for i in (1, 2, 3, 4)]
    fifteen = [row(date=f"2026-10-0{i}", minutes=20, idle=3) for i in (1, 2, 3, 4)]
    wants = ["tune: cf/max lost 10 of 40 min to idle: lower QUIET_SEC or tighten the first-commit deadline",
             "tune: cf/max lost 12 of 80 min to idle: lower QUIET_SEC or tighten the first-commit deadline"]
    for rows, want in zip((ten, fifteen), wants):
        with tempfile.TemporaryDirectory() as d:
            lines = run(d, rows)
        assert [ln for ln in lines if ln.startswith("tune:")] == [want], lines


def test_the_low_pass_tune_fires_below_seventy_percent_with_three_runs():
    rows = [row(gate="FAIL") for _ in range(3)]
    with tempfile.TemporaryDirectory() as d:
        lines = run(d, rows)
    assert lines[1:] == [
        "cf/max  runs 3  pass 0%  min avg 10.0  fix avg 0.0  idle 0 min  tok 300/30  usd 0.03 (0 unknown)",
        "tune: cf/max passes only 0% of 3 runs: tighten briefs or move up an effort",
    ], lines


def test_the_fix_passes_tune_fires_over_one_fix_pass_a_run():
    rows = [row(fix=1), row(fix=2), row(fix=1)]
    with tempfile.TemporaryDirectory() as d:
        lines = run(d, rows)
    assert lines[1:] == [
        "cf/max  runs 3  pass 100%  min avg 10.0  fix avg 1.3  idle 0 min  tok 300/30  usd 0.03 (0 unknown)",
        "tune: cf/max needs 1.3 fix passes a run: write sharper tests",
    ], lines


def test_the_unknown_cost_tune_fires_on_a_question_mark_usd():
    rows = [row(usd="?", cost_source="unknown"), row(usd="?", cost_source="unknown")]
    with tempfile.TemporaryDirectory() as d:
        lines = run(d, rows)
    assert lines[1:] == [
        "cf/max  runs 2  pass 100%  min avg 10.0  fix avg 0.0  idle 0 min  tok 200/20  usd ? (0 unknown)",
        "tune: 2 row(s) have no cost reading (older runs or non-opencode builders)",
    ], lines


def test_every_tune_stays_silent_just_under_its_threshold():
    cases = {
        "idle 9 of 40 min": [row(minutes=10, idle=i) for i in (1, 2, 3, 3)],
        "idle 12 of 81 min": [row(minutes=m, idle=3) for m in (20, 20, 20, 21)],
        "pass 70% of 10": [row(gate="PASS" if i < 7 else "FAIL") for i in range(10)],
        "fix 1.0 a run": [row(fix=1) for _ in range(3)],
        "cost numeric": [row(usd="0.01")],
    }
    for name, rows in cases.items():
        with tempfile.TemporaryDirectory() as d:
            lines = run(d, rows)
        assert not [ln for ln in lines if ln.startswith("tune:")], (name, lines)


def test_tune_lines_come_in_the_brief_order():
    rows = [row(gate="FAIL", fix=2, minutes=10, idle=8, usd="?", cost_source="unknown") for _ in range(3)]
    with tempfile.TemporaryDirectory() as d:
        lines = run(d, rows)
    assert lines[1:] == [
        "cf/max  runs 3  pass 0%  min avg 10.0  fix avg 2.0  idle 24 min  tok 300/30  usd ? (0 unknown)",
        "tune: cf/max lost 24 of 30 min to idle: lower QUIET_SEC or tighten the first-commit deadline",
        "tune: cf/max passes only 0% of 3 runs: tighten briefs or move up an effort",
        "tune: cf/max needs 2.0 fix passes a run: write sharper tests",
        "tune: 3 row(s) have no cost reading (older runs or non-opencode builders)",
    ], lines


def test_the_report_never_exceeds_20_lines_and_caps_groups_at_12():
    quiet = [row(worker=f"g{i:02d}", effort="-") for i in range(1, 14)]
    loud = [row(worker=f"g{i:02d}", effort="-", gate="FAIL", fix=2, minutes=10, idle=8, usd="?",
                cost_source="unknown") for i in range(1, 14) for _ in range(3)]
    with tempfile.TemporaryDirectory() as d:
        lines = run(d, quiet)
    groups = [ln for ln in lines if "  runs " in ln]
    assert len(groups) == 12, lines
    assert groups[0].startswith("g01/-  runs 1") and groups[-1].startswith("g12/-  runs 1"), groups
    assert "... and 1 more groups" in lines, lines
    with tempfile.TemporaryDirectory() as d:
        loud_lines = run(d, loud)
    assert len(loud_lines) <= 20, loud_lines
    assert loud_lines[0] == "KAIZEN 39 runs, 2026-10-01..2026-10-01", loud_lines
    assert len([ln for ln in loud_lines if "  runs " in ln]) <= 12, loud_lines


if __name__ == "__main__":
    from tool_tests import run_cases
    run_cases([v for k, v in sorted(globals().items()) if k.startswith("test_")], "test_kaizen_report")
