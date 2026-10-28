#!/usr/bin/env python3
"""Self-test for the cross-review findings parser (row 12 A/B, 2026-10-28): python tools/test_cross_review.py.
The reviewer's log holds one block between BEGIN FINDINGS / END FINDINGS (tools/cross_review_prompt.md). A crashed or
chatty reviewer must never read as a clean review: only an explicit NONE line means zero findings."""
import os
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import cross_review as cr  # noqa: E402

LINE_A = "high | tools/hooks/a.py:42 | a missing state file -> load() raises, the hook exits 1 | catch OSError"
LINE_B = "medium | tools/b.sh:7 | an empty task name -> the worktree path is game-wt/ itself | refuse an empty name"


def block(*lines):
    return "BEGIN FINDINGS\n" + "".join(line + "\n" for line in lines) + "END FINDINGS\n"


def test_findings_parse_from_a_chatty_log():
    log = "Reading the diff...\nI found two issues.\n" + block(LINE_A, LINE_B) + "Done.\n"
    r = cr.parse(log)
    assert r["status"] == "OK" and len(r["findings"]) == 2, r
    a = r["findings"][0]
    assert (a["severity"], a["file"], a["line"]) == ("high", "tools/hooks/a.py", 42), a
    assert a["scenario"] == "a missing state file -> load() raises, the hook exits 1" and a["fix"] == "catch OSError", a


def test_none_means_zero_findings():
    r = cr.parse("all good\n" + block("NONE"))
    assert r["status"] == "OK" and r["findings"] == [], r


def test_crashed_or_empty_reviewer_is_invalid():
    for log in ("", "agy exited 124\n", "BEGIN FINDINGS\nEND FINDINGS\n", "BEGIN FINDINGS\n\n  \nEND FINDINGS\n",
                "BEGIN FINDINGS\n" + LINE_A + "\n"):  # no end marker: cut off mid-answer
        r = cr.parse(log)
        assert r["status"] == "INVALID" and r["findings"] == [] and r["reason"], (log, r)


def test_free_prose_and_bad_lines_are_invalid():
    bad = [
        "The code looks good overall, but the hook could be more robust.",
        "- " + LINE_A,  # a list marker is prose
        "high | tools/a.py:42 | a missing file -> crash",  # 3 fields
        "critical | tools/a.py:42 | a missing file -> crash | catch it",  # unknown severity
        "high | tools/a.py | a missing file -> crash | catch it",  # no line number
        "high | tools/a.py:0 | a missing file -> crash | catch it",  # lines start at 1
        "high | tools/a.py:42 | the error handling is weak | catch it",  # no "input -> result" scenario
        "high | tools/a.py:42 | a missing file -> crash | ",  # empty fix
    ]
    for line in bad:
        r = cr.parse(block(line))
        assert r["status"] == "INVALID" and r["findings"] == [], (line, r)
        r = cr.parse(block(LINE_B, line))  # one bad line spoils the block
        assert r["status"] == "INVALID", (line, r)
    assert cr.parse(block("NONE", LINE_A))["status"] == "INVALID", "NONE mixed with findings"
    assert cr.parse(block(*([LINE_B] * 13)))["status"] == "INVALID", "over 12 findings"
    assert cr.parse(block(*([LINE_B] * 12)))["status"] == "OK"


def test_last_block_wins_fences_case_ranges_and_pipes():
    echoed = block("high | tools/example.py:42 | an example -> an example | an example")
    real = block("```", "HIGH | tools/c.py:10-12 | x is None -> TypeError | use `a | b` or skip", "```")
    r = cr.parse(echoed + "my review:\n" + real)
    assert r["status"] == "OK" and len(r["findings"]) == 1, r
    f = r["findings"][0]
    assert (f["severity"], f["file"], f["line"], f["fix"]) == ("high", "tools/c.py", 10, "use `a | b` or skip"), f


def test_prompt_example_parses():  # the prompt's own example line must stay valid for the parser
    text = open(os.path.join(HERE, "cross_review_prompt.md"), encoding="utf-8").read()
    r = cr.parse(text)
    assert r["status"] == "OK" and len(r["findings"]) == 1, r


def test_cli_exit_codes_and_table():
    d = tempfile.mkdtemp()
    log, out = os.path.join(d, "review.log"), os.path.join(d, "job.cross.md")
    with open(log, "w", encoding="utf-8", newline="\n") as f:
        f.write(block(LINE_A, LINE_B + " | exit 2"))  # a pipe in the last field belongs to the fix
    r = subprocess.run([sys.executable, os.path.join(HERE, "cross_review.py"), "parse", log, "--out", out],
                       capture_output=True, text=True)
    assert r.returncode == 0 and r.stdout.startswith("CROSS OK 2 (high 1, medium 1, low 0)"), r.stdout + r.stderr
    table = open(out, encoding="utf-8").read()
    assert "| severity | file:line | failure scenario | fix |" in table and "| high | tools/hooks/a.py:42 |" in table, table
    assert "refuse an empty name \\| exit 2 |" in table, ("a pipe inside a field is escaped in the table", table)
    with open(log, "w", encoding="utf-8", newline="\n") as f:
        f.write("I could not finish the review.\n")
    r = subprocess.run([sys.executable, os.path.join(HERE, "cross_review.py"), "parse", log, "--out", out],
                       capture_output=True, text=True)
    assert r.returncode == 1 and r.stdout.startswith("CROSS INVALID"), r.stdout + r.stderr
    assert open(out, encoding="utf-8").read().startswith("INVALID: "), "the .cross.md says why, never a stale table"


def test_cli_non_utf8_log_and_lf_output():  # Opus review of the race winner, 10-28
    d = tempfile.mkdtemp()
    log, out = os.path.join(d, "review.log"), os.path.join(d, "job.cross.md")
    with open(log, "wb") as f:
        f.write(b"stray \xff byte\n" + block(LINE_A).encode("utf-8"))
    r = subprocess.run([sys.executable, os.path.join(HERE, "cross_review.py"), "parse", log, "--out", out],
                       capture_output=True, text=True)
    assert r.returncode == 0 and r.stdout.startswith("CROSS OK 1"), ("a stray byte crashed the parser", r.stdout, r.stderr)
    assert b"\r\n" not in open(out, "rb").read(), "the table is written with LF, not CRLF"


if __name__ == "__main__":
    tests = [v for k, v in sorted(globals().items()) if k.startswith("test_")]
    for t in tests:
        t()
    print(f"test_cross_review: {len(tests)} tests passed")
