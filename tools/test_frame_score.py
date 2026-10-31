"""Tests tools/frame_score.py. Run: python tools/test_frame_score.py"""
import json
import math
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
    check(to_bool("_yes_") is True, "to_bool _yes_ is True")
    check(to_bool("__NO__") is False, "to_bool __NO__ is False")
    check(to_bool(float("nan")) is None, "to_bool float NaN is None")


def test_parse_lines() -> None:
    check(parse_lines("1. yes\n2) no", 2) == [True, False], "parse_lines numbered fills slots")
    check(parse_lines("1. yes\n3. no", 3) == [True, None, False], "parse_lines numbered gap leaves None")
    check(parse_lines("1. yes\n5. no", 2) == [True, None], "parse_lines ignores number beyond count")
    check(parse_lines("no yes yes", 3) == [False, True, True], "parse_lines words on one line")
    check(parse_lines("no yes yes", 2) == [False, True], "parse_lines words on one line limits count")
    check(parse_lines("yes", 3) == [True, None, None], "parse_lines short reply")
    check(parse_lines("Answer: NO", 2) == [False, None], "parse_lines short reply single text")


def test_numbered_slots_win_and_preamble_takes_no_slot() -> None:
    check(parse_lines("1. yes\nno yes", 3) == [True, False, True], "1. yes\\nno yes, 3 -> [True, False, True]")
    check(parse_lines("1. maybe\nyes", 2) == [None, True], "1. maybe\\nyes, 2 -> [None, True]")
    check(parse_lines("1. no 2. yes", 2) == [False, True], "1. no 2. yes, 2 -> [False, True]")
    check(parse_lines("no\n1. yes", 2) == [True, False], "no\\n1. yes, 2 -> [True, False]")
    check(parse_lines("Looking at the frames:\nyes\nno", 2) == [True, False], "Looking at...\\nyes\\nno, 2 -> [True, False]")
    check(parse_lines("no yes\nyes", 3) == [False, True, True], "no yes\\nyes, 3 -> [False, True, True]")
    check(parse_lines("No, there is no rain.", 2) == [False, None], "No, there is no rain., 2 -> [False, None]")


def test_score_counts_false_pass_false_fail_and_unparsed() -> None:
    ref = {"f1": [False, True], "f2": [True, True]}
    ans = {"f1": [True, False], "f2": [True, None]}
    res = score(ref, ans)
    expected = {"total": 4, "agree": 1, "false_pass": 1, "false_fail": 1, "unparsed": 1}
    check(res == expected, "score counts false_pass, false_fail, agree, unparsed")
    short_ans = score({"f1": [True, False, True]}, {"f1": [True]})
    check(short_ans == {"total": 3, "agree": 1, "false_pass": 0, "false_fail": 0, "unparsed": 2}, "answers shorter than ref")
    check(sum(short_ans[k] for k in ("agree", "false_pass", "false_fail", "unparsed")) == short_ans["total"], "counters add to total")
    plain = score({"f1": True}, {"f1": [True]})
    check(plain["total"] == 1 and plain["unparsed"] == 1, "plain ref counts unparsed")


def test_score_missing_frame() -> None:
    ref = {"f1": [True, False], "f2": [False, True]}
    ans = {"f1": [True, False]}
    res = score(ref, ans)
    check(res["total"] == 4, "total counts all reference slots")
    check(res["agree"] == 2, "f1 slots agree")
    check(res["unparsed"] == 2, "missing frame f2 counts all slots unparsed")


def test_cli() -> None:
    with tempfile.TemporaryDirectory() as tmp:
        ref_path, ans_path = os.path.join(tmp, "ref.json"), os.path.join(tmp, "ans.json")
        lines_path, bom_path = os.path.join(tmp, "ans_lines.json"), os.path.join(tmp, "bom.json")
        with open(ref_path, "w", encoding="utf-8") as f:
            json.dump({"f1": [True, False]}, f)
        with open(ans_path, "w", encoding="utf-8") as f:
            json.dump({"f1": [True, False]}, f)
        with open(lines_path, "w", encoding="utf-8") as f:
            json.dump({"f1": "yes no"}, f)
        with open(bom_path, "wb") as f:
            f.write(b"\xef\xbb\xbf" + json.dumps({"f1": [True, False]}).encode("utf-8"))
        res = subprocess.run([sys.executable, TOOL, "--reference", ref_path, "--answers", ans_path],
                             capture_output=True, text=True)
        check(res.returncode == 0, "cli exits 0 on valid files")
        data = json.loads(res.stdout.strip())
        check(data["agree"] == 2 and data["total"] == 2, "cli outputs score JSON line")
        res_bom = subprocess.run([sys.executable, TOOL, "--reference", bom_path, "--answers", ans_path],
                                 capture_output=True, text=True)
        check(res_bom.returncode == 0 and res_bom.stderr == "", "cli on a BOM file exits 0 with empty stderr")
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


def test_cli_rejects_bad_shapes_with_error_and_empty_stderr() -> None:
    with tempfile.TemporaryDirectory() as tmp:
        valid_ref = os.path.join(tmp, "valid_ref.json")
        valid_ans = os.path.join(tmp, "valid_ans.json")
        with open(valid_ref, "w", encoding="utf-8") as f:
            json.dump({"f1": [True, False]}, f)
        with open(valid_ans, "w", encoding="utf-8") as f:
            json.dump({"f1": [True, False]}, f)
        cases = [
            ("ref_true.json", '{"f1": true}', "--reference", valid_ans, None),
            ("ref_yes.json", '{"f1": "yes"}', "--reference", valid_ans, None),
            ("ans_yes.json", '{"f1": "yes"}', "--answers", valid_ref, None),
            ("ans_bool_list.json", '{"f1": [true]}', "--answers", valid_ref, "1"),
            ("malformed.json", '{"f1": [true', "--reference", valid_ans, None),
        ]
        for name, content, flag, other_path, lines_arg in cases:
            path = os.path.join(tmp, name)
            with open(path, "w", encoding="utf-8") as f:
                f.write(content)
            cmd = [sys.executable, TOOL]
            cmd += [flag, path, "--answers" if flag == "--reference" else "--reference", other_path]
            if lines_arg:
                cmd += ["--lines", lines_arg]
            res = subprocess.run(cmd, capture_output=True, text=True)
            check(res.returncode == 1, f"bad shape {name} exits 1")
            check(res.stdout.startswith("ERROR:"), f"bad shape {name} prints ERROR: ...")
            check(res.stderr == "", f"bad shape {name} has empty stderr")


def main() -> None:
    test_to_bool_reads_markdown_and_ignores_inner_words()
    test_parse_lines()
    test_numbered_slots_win_and_preamble_takes_no_slot()
    test_score_counts_false_pass_false_fail_and_unparsed()
    test_score_missing_frame()
    test_cli()
    test_cli_rejects_bad_shapes_with_error_and_empty_stderr()


if __name__ == "__main__":
    main()
