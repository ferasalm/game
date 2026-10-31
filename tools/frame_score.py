#!/usr/bin/env python
"""Score vision model yes/no answers on frames against reference labels."""
import argparse
import json
import math
import re
import sys


def to_bool(value: object, threshold: float = 0.5) -> bool | None:
    if isinstance(value, bool):
        return value
    if isinstance(value, (int, float)):
        return None if isinstance(value, float) and math.isnan(value) else value >= threshold
    if isinstance(value, str):
        m = re.search(r"(?<![a-zA-Z0-9])(yes|no)(?![a-zA-Z0-9])", value, re.IGNORECASE)
        if m:
            return m.group(1).lower() == "yes"
    return None


def parse_lines(text: str, count: int) -> list:
    out = [None] * count
    if count <= 0:
        return out
    claimed, unnumbered = set(), []
    marker_re = re.compile(r"(?:^|\s+)(\d+)[\.\):-](?:[\t ]*(.*?))(?=(?:\s+\d+[\.\):-]|$))")
    for line in str(text or "").splitlines():
        line = line.strip()
        if not line:
            continue
        if re.search(r"(?:^|\s)\d+[\.\):-]", line):
            for m in marker_re.finditer(line):
                num = int(m.group(1))
                if 1 <= num <= count:
                    claimed.add(num - 1)
                    out[num - 1] = to_bool(m.group(2).strip())
        else:
            unnumbered.append(line)
    free = [i for i in range(count) if i not in claimed]
    idx = 0
    for line in unnumbered:
        if idx >= len(free):
            break
        words = re.findall(r"(?<![a-zA-Z0-9])(?:yes|no)(?![a-zA-Z0-9])", line, re.IGNORECASE)
        if not words:
            continue
        rest = re.sub(r"(?<![a-zA-Z0-9])(?:yes|no)(?![a-zA-Z0-9])", "", line, flags=re.IGNORECASE)
        if re.search(r"[a-zA-Z0-9]", rest):
            out[free[idx]] = words[0].lower() == "yes"
            idx += 1
        else:
            for w in words:
                if idx < len(free):
                    out[free[idx]] = w.lower() == "yes"
                    idx += 1
    return out


def score(reference: dict, answers: dict, threshold: float = 0.5) -> dict:
    res = {"total": 0, "agree": 0, "false_pass": 0, "false_fail": 0, "unparsed": 0}
    if not isinstance(reference, dict):
        return res
    for frame, ref_slots in reference.items():
        if not isinstance(ref_slots, list):
            res["total"] += 1
            res["unparsed"] += 1
            continue
        ans_slots = answers.get(frame) if isinstance(answers, dict) else None
        for i, ref_val in enumerate(ref_slots):
            res["total"] += 1
            if not isinstance(ans_slots, list) or i >= len(ans_slots):
                res["unparsed"] += 1
                continue
            ans_val = to_bool(ans_slots[i], threshold)
            ref_b = to_bool(ref_val, threshold) if not isinstance(ref_val, bool) else ref_val
            if ans_val is None or ref_b is None:
                res["unparsed"] += 1
            elif ans_val == ref_b:
                res["agree"] += 1
            elif not ref_b and ans_val:
                res["false_pass"] += 1
            else:
                res["false_fail"] += 1
    return res


def load_json(path: str) -> dict:
    with open(path, "r", encoding="utf-8-sig") as f:
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
        for f, v in ref_data.items():
            if not isinstance(v, list) or any(not isinstance(x, bool) for x in v):
                raise ValueError(f"reference frame '{f}' must be a list of bools")
        if args.lines is None:
            for f, v in ans_data.items():
                if not isinstance(v, list):
                    raise ValueError(f"answers frame '{f}' must be a list")
        else:
            for f, v in ans_data.items():
                if not (isinstance(v, str) or (isinstance(v, list) and all(isinstance(x, str) for x in v))):
                    raise ValueError(f"answers frame '{f}' must be text or list of text")
            ans_data = {
                f: parse_lines("\n".join(v) if isinstance(v, list) else v, args.lines)
                for f, v in ans_data.items()
            }
        print(json.dumps(score(ref_data, ans_data, args.threshold)))
        return 0
    except Exception as err:
        print(f"ERROR: {err}")
        return 1


if __name__ == "__main__":
    sys.exit(main())
