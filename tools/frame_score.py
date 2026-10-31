#!/usr/bin/env python
"""Score vision model yes/no answers on frames against reference labels."""
import argparse
import json
import re
import sys


def to_bool(value: object, threshold: float = 0.5) -> bool | None:
    if isinstance(value, bool):
        return value
    if isinstance(value, (int, float)):
        return value >= threshold
    if isinstance(value, str):
        m = re.search(r"\b(yes|no)\b", value, re.IGNORECASE)
        if m:
            return m.group(1).lower() == "yes"
    return None


def parse_lines(text: str, count: int) -> list:
    out = [None] * count
    lines = [line.strip() for line in str(text or "").splitlines() if line.strip()]
    if not lines or count <= 0:
        return out
    if len(lines) == 1:
        line = lines[0]
        m = re.match(r"^(\d+)[\.\):\-]\s*(.*)$", line)
        if m:
            num = int(m.group(1))
            if 1 <= num <= count:
                out[num - 1] = to_bool(m.group(2))
            return out
        words = re.findall(r"\b(?:yes|no)\b", line, re.IGNORECASE)
        if len(words) > 1:
            for i in range(min(count, len(words))):
                out[i] = to_bool(words[i])
            return out
        out[0] = to_bool(line)
        return out

    next_slot = 0
    for line in lines:
        m = re.match(r"^(\d+)[\.\):\-]\s*(.*)$", line)
        if m:
            num = int(m.group(1))
            if 1 <= num <= count:
                out[num - 1] = to_bool(m.group(2))
        else:
            while next_slot < count and out[next_slot] is not None:
                next_slot += 1
            if next_slot < count:
                out[next_slot] = to_bool(line)
                next_slot += 1
    return out


def score(reference: dict, answers: dict, threshold: float = 0.5) -> dict:
    res = {"total": 0, "agree": 0, "false_pass": 0, "false_fail": 0, "unparsed": 0}
    for frame, ref_slots in reference.items():
        ans_slots = answers.get(frame) if isinstance(answers, dict) else None
        for i, ref_val in enumerate(ref_slots):
            res["total"] += 1
            if ans_slots is None or not isinstance(ans_slots, list) or i >= len(ans_slots):
                res["unparsed"] += 1
                continue
            ans_val = to_bool(ans_slots[i], threshold)
            if ans_val is None:
                res["unparsed"] += 1
            elif ans_val == ref_val:
                res["agree"] += 1
            elif not ref_val and ans_val:
                res["false_pass"] += 1
            elif ref_val and not ans_val:
                res["false_fail"] += 1
    return res


def load_json(path: str) -> dict:
    with open(path, "r", encoding="utf-8") as f:
        data = json.load(f)
    if not isinstance(data, dict):
        raise ValueError(f"expected JSON object in {path}")
    return data


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--reference", default=None)
    parser.add_argument("--answers", default=None)
    parser.add_argument("--threshold", type=float, default=0.5)
    parser.add_argument("--lines", type=int, default=None)
    args = parser.parse_args()

    if not args.reference or not args.answers:
        print("ERROR: --reference and --answers are required")
        return 1
    try:
        ref_data, ans_data = load_json(args.reference), load_json(args.answers)
    except Exception as err:
        print(f"ERROR: {err}")
        return 1

    if args.lines is not None:
        ans_data = {
            f: parse_lines("\n".join(v) if isinstance(v, list) else v, args.lines)
            for f, v in ans_data.items()
        }
    print(json.dumps(score(ref_data, ans_data, args.threshold)))
    return 0


if __name__ == "__main__":
    sys.exit(main())
