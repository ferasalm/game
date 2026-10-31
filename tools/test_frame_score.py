"""Tests tools/frame_score.py. Run: python tools/test_frame_score.py"""
import json
import os
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
TOOL = os.path.join(HERE, "frame_score.py")

sys.path.insert(0, HERE)
from frame_score import parse_lines, score, to_bool


def check(cond: bool, msg: str) -> None:
    if not cond:
        print("FAIL", msg)
        sys.exit(1)
    print("ok", msg)


def test_to_bool_reads_markdown_and_ignores_inner_words() -> None:
    check(to_bool(True) is True, "to_bool True is True")
    check(to_bool(False) is False, "to_bool False is False")
    check(to_bool(0.5, threshold=0.5) is True, "to_bool 0.5 >= 0.5 is True")
    check(to_bool(0.49, threshold=0.5) is False, "to_bool 0.49 >= 0.5 is False")
    check(to_bool(1) is True, "to_bool 1 is True")
    check(to_bool(0) is False, "to_bool 0 is False")
    check(to_bool("**Yes.**") is True, "to_bool **Yes.** is True")
    check(to_bool("Answer: NO") is False, "to_bool Answer: NO is False")
    check(to_bool("nothing") is None, "to_bool nothing is None")
    check(to_bool("yesterday") is None, "to_bool yesterday is None")
    check(to_bool(None) is None, "to_bool None is None")


def test_parse_lines() -> None:
    check(parse_lines("1. yes\n2) no", 2) == [True, False], "parse_lines numbered fills slots")
    check(parse_lines("1. yes\n3. no", 3) == [True, None, False], "parse_lines numbered gap leaves None")
    check(parse_lines("1. yes\n5. no", 2) == [True, None], "parse_lines ignores number beyond count")
    check(parse_lines("no yes yes", 3) == [False, True, True], "parse_lines words on one line")
    check(parse_lines("no yes yes", 2) == [False, True], "parse_lines words on one line limits count")
    check(parse_lines("yes", 3) == [True, None, None], "parse_lines short reply")
    check(parse_lines("Answer: NO", 2) == [False, None], "parse_lines short reply single text")


def test_score_counts_false_pass_false_fail_and_unparsed() -> None:
    ref = {"f1": [False, True], "f2": [True, True]}
    ans = {"f1": [True, False], "f2": [True, None]}
    res = score(ref, ans)
    expected = {"total": 4, "agree": 1, "false_pass": 1, "false_fail": 1, "unparsed": 1}
    check(res == expected, "score counts false_pass, false_fail, agree, unparsed")


def test_score_missing_frame() -> None:
    ref = {"f1": [True, False], "f2": [False, True]}
    ans = {"f1": [True, False]}
    res = score(ref, ans)
    check(res["total"] == 4, "total counts all reference slots")
    check(res["agree"] == 2, "f1 slots agree")
    check(res["unparsed"] == 2, "missing frame f2 counts all slots unparsed")


def test_cli() -> None:
    with tempfile.TemporaryDirectory() as tmp:
        ref_path = os.path.join(tmp, "ref.json")
        ans_path = os.path.join(tmp, "ans.json")
        lines_path = os.path.join(tmp, "ans_lines.json")

        with open(ref_path, "w", encoding="utf-8") as f:
            json.dump({"f1": [True, False]}, f)
        with open(ans_path, "w", encoding="utf-8") as f:
            json.dump({"f1": [True, False]}, f)
        with open(lines_path, "w", encoding="utf-8") as f:
            json.dump({"f1": "yes no"}, f)

        res = subprocess.run([sys.executable, TOOL, "--reference", ref_path, "--answers", ans_path],
                             capture_output=True, text=True)
        check(res.returncode == 0, "cli exits 0 on valid files")
        data = json.loads(res.stdout.strip())
        check(data["agree"] == 2 and data["total"] == 2, "cli outputs score JSON line")

        res_lines = subprocess.run([sys.executable, TOOL, "--reference", ref_path, "--answers", lines_path, "--lines", "2"],
                                   capture_output=True, text=True)
        check(res_lines.returncode == 0, "cli with --lines exits 0")
        data_lines = json.loads(res_lines.stdout.strip())
        check(data_lines["agree"] == 2, "cli with --lines parses text answers")

        missing_path = os.path.join(tmp, "missing.json")
        res_err = subprocess.run([sys.executable, TOOL, "--reference", ref_path, "--answers", missing_path],
                                 capture_output=True, text=True)
        check(res_err.returncode == 1, "cli exits 1 on missing file")
        check("ERROR:" in res_err.stdout, "cli prints ERROR on missing file")


def main() -> None:
    test_to_bool_reads_markdown_and_ignores_inner_words()
    test_parse_lines()
    test_score_counts_false_pass_false_fail_and_unparsed()
    test_score_missing_frame()
    test_cli()


if __name__ == "__main__":
    main()
