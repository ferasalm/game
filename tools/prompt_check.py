"""prompt_check.py lints a brief, a oneshot prompt, or a chat prompt."""
import argparse
import re
import sys

BRIEF_HEADINGS = [
    "Why",
    "Read first",
    "What to build",
    "Do NOT edit",
    "May edit",
    "Ripple",
    "Pre-mortem",
    "Tests",
    "Checklist",
    "Proof",
]

ONESHOT_LABELS = [
    "Goal",
    "Inputs",
    "Do NOT",
    "Output contract",
    "Done",
    "Stop rules",
]

CHAT_LABELS = [
    "Department",
    "Queue row",
    "Model",
    "Skills",
    "Persona",
    "Goal",
    "Context",
    "Lane plan",
    "May edit",
    "Do NOT edit",
    "Commit and merge",
    "Done when",
    "Report",
]


def check_brief(text: str) -> list[str]:
    misses = []
    for h in BRIEF_HEADINGS:
        if not re.search(rf"^##\s+{re.escape(h)}(?:\s|$)", text, re.M):
            misses.append(f"missing heading: ## {h}")
    lines = len(text.splitlines())
    if lines > 80:
        misses.append(f"brief exceeds 80 lines ({lines})")
    return misses


def check_oneshot(text: str) -> list[str]:
    misses = []
    for label in ONESHOT_LABELS:
        pattern = rf"^[#\s\*\-]*{re.escape(label)}(?::|\*\*|\s*$)"
        if not re.search(pattern, text, re.M):
            misses.append(f"missing oneshot label: {label}")
    return misses


def check_chat(text: str) -> list[str]:
    misses = []
    is_goal = text.startswith("/goal")
    is_sonnet = is_goal or bool(re.search(r"\bModel:\s*Sonnet\b", text, re.I))

    if is_sonnet:
        if not is_goal:
            misses.append("Sonnet prompt must start with /goal")
        if len(text) >= 4000:
            misses.append(f"Sonnet prompt exceeds 4000 characters ({len(text)})")
        if not re.search(r"\b(?:\d+\s*turns?|turn\s+cap)\b", text, re.I):
            misses.append("Sonnet prompt missing turn cap")

    if not is_goal:
        for label in CHAT_LABELS:
            pattern = rf"(?:(?:\b|^){re.escape(label)}:|^#+\s+{re.escape(label)}(?:\s|$))"
            if not re.search(pattern, text, re.M):
                misses.append(f"missing chat label: {label}")

    return misses


def check(text: str, kind: str) -> list[str]:
    if kind == "brief":
        return check_brief(text)
    if kind == "oneshot":
        return check_oneshot(text)
    if kind == "chat":
        return check_chat(text)
    raise ValueError(f"unknown kind: {kind}")


def main(argv=None) -> int:
    parser = argparse.ArgumentParser(description="Lint worker prompts and briefs.")
    parser.add_argument("file", help="Path to prompt file")
    parser.add_argument("--kind", required=True, choices=["brief", "oneshot", "chat"],
                        help="Prompt kind (brief, oneshot, chat)")
    try:
        args = parser.parse_args(argv)
    except SystemExit as exc:
        code = exc.code if isinstance(exc.code, int) else 2
        return code if code != 1 else 2

    try:
        with open(args.file, "r", encoding="utf-8") as f:
            text = f.read()
    except Exception as exc:
        sys.stderr.write(f"Error reading {args.file}: {exc}\n")
        return 2

    misses = check(text, args.kind)
    if not misses:
        print(f"ok {args.file} ({args.kind})")
        return 0

    for m in misses:
        print(f"MISS {args.file}: {m}")
    return 1


if __name__ == "__main__":
    sys.exit(main())
