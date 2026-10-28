"""Parse cross-review finding blocks from reviewer logs into structured data."""
import argparse
import re
import sys


def _extract_block(text: str):
    raw_lines = text.splitlines()
    start_idx = -1
    for i, line in enumerate(raw_lines):
        if line.strip() == "BEGIN FINDINGS":
            start_idx = i
    if start_idx == -1:
        return None, "no BEGIN FINDINGS marker"
    end_idx = -1
    for i in range(start_idx + 1, len(raw_lines)):
        if raw_lines[i].strip() == "END FINDINGS":
            end_idx = i
            break
    if end_idx == -1:
        return None, "no END FINDINGS marker"
    lines = []
    for line in raw_lines[start_idx + 1:end_idx]:
        s = line.strip()
        if not s or s.startswith("```"):
            continue
        lines.append(s)
    if not lines:
        return None, "empty findings block"
    return lines, ""


def _parse_finding(line: str):
    parts = line.split("|", 3)
    if len(parts) != 4:
        return None, f"expected 4 pipe-delimited fields: {line}"
    sev, loc, scenario, fix = [p.strip() for p in parts]
    sev_lower = sev.lower()
    if sev_lower not in ("high", "medium", "low"):
        return None, f"invalid severity in line: {line}"
    m = re.match(r"^([^:\s]+):(\d+)(?:-(\d+))?$", loc)
    if not m:
        return None, f"invalid location in line: {line}"
    line_num = int(m.group(2))
    if line_num < 1:
        return None, f"line number must be >= 1: {line}"
    if m.group(3) is not None and int(m.group(3)) < line_num:
        return None, f"invalid line range in line: {line}"
    if "->" not in scenario:
        return None, f"scenario missing '->' in line: {line}"
    if not fix:
        return None, f"fix is empty: {line}"
    return {
        "severity": sev_lower,
        "file": m.group(1),
        "line": line_num,
        "scenario": scenario,
        "fix": fix,
    }, ""


def parse(text: str) -> dict:
    lines, err = _extract_block(text)
    if err:
        return {"status": "INVALID", "findings": [], "reason": err}
    if lines == ["NONE"]:
        return {"status": "OK", "findings": [], "reason": ""}
    if "NONE" in lines:
        return {"status": "INVALID", "findings": [], "reason": "NONE mixed with other lines"}
    if len(lines) > 12:
        return {"status": "INVALID", "findings": [], "reason": f"too many findings ({len(lines)} > 12)"}
    findings = []
    for line in lines:
        finding, ferr = _parse_finding(line)
        if ferr:
            return {"status": "INVALID", "findings": [], "reason": ferr}
        findings.append(finding)
    return {"status": "OK", "findings": findings, "reason": ""}


def _format_markdown(findings: list[dict]) -> str:
    if not findings:
        return "NONE\n"
    rows = [
        "| severity | file:line | failure scenario | fix |",
        "|---|---|---|---|",
    ]
    for f in findings:
        sev = f["severity"].replace("|", r"\|")
        loc = f"{f['file']}:{f['line']}".replace("|", r"\|")
        scen = f["scenario"].replace("|", r"\|")
        fix = f["fix"].replace("|", r"\|")
        rows.append(f"| {sev} | {loc} | {scen} | {fix} |")
    return "\n".join(rows) + "\n"


def main(argv=None) -> int:
    parser = argparse.ArgumentParser(description="Cross-review parser")
    subparsers = parser.add_subparsers(dest="command")
    parse_parser = subparsers.add_parser("parse")
    parse_parser.add_argument("log")
    parse_parser.add_argument("--out", default=None)
    args = parser.parse_args(argv)
    if args.command != "parse":
        sys.stderr.write("Usage: cross_review.py parse <log> [--out <file>]\n")
        return 2
    try:
        with open(args.log, encoding="utf-8", errors="replace") as f:
            content = f.read()
    except OSError as e:
        print(f"CROSS INVALID cannot read log file: {e}")
        if args.out:
            with open(args.out, "w", encoding="utf-8", newline="\n") as f:
                f.write(f"INVALID: cannot read log file: {e}\n")
        return 1
    res = parse(content)
    if res["status"] == "OK":
        h = sum(1 for f in res["findings"] if f["severity"] == "high")
        m = sum(1 for f in res["findings"] if f["severity"] == "medium")
        l = sum(1 for f in res["findings"] if f["severity"] == "low")
        print(f"CROSS OK {len(res['findings'])} (high {h}, medium {m}, low {l})")
        if args.out:
            with open(args.out, "w", encoding="utf-8", newline="\n") as f:
                f.write(_format_markdown(res["findings"]))
        return 0
    print(f"CROSS INVALID {res['reason']}")
    if args.out:
        with open(args.out, "w", encoding="utf-8", newline="\n") as f:
            f.write(f"INVALID: {res['reason']}\n")
    return 1


if __name__ == "__main__":
    sys.exit(main())
