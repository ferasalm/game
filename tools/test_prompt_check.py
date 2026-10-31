#!/usr/bin/env python3
"""prompt_check.py lints a brief, a one-shot worker prompt or a chat prompt before it is sent (system-v3 row 22, 2026-11-01)."""
import os
import re
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
sys.path.insert(0, HERE)
import prompt_check as pc  # noqa: E402

TEMPLATE = open(os.path.join(ROOT, "docs", "briefs", "TEMPLATE.md"), encoding="utf-8").read()
WORKFLOW = open(os.path.join(ROOT, "docs", "WORKFLOW.md"), encoding="utf-8").read()
HANDOFF = open(os.path.join(ROOT, "HANDOFF.md"), encoding="utf-8").read()

ONESHOT = """Goal: list the stale links in docs/.
Inputs: docs/*.md. Read nothing else.
Steps: 1. grep. 2. write the list.
Do NOT: edit any file.
**Output contract**: one line per link, at most 30 lines, written to stdout.
## Done
The list is printed.
Stop rules: 2 rounds, then report.
"""

CHAT = """Department: Ops (a label: Routing table). Queue row: 22. Model: Opus high.
Skills: builders. Persona: none
Goal: one plugin holds the skills.
Context: docs/briefs/system-v3.md.
Lane plan: agy writes the tool, cf max reviews.
May edit: tools/. Do NOT edit: features/. Commit and merge: no, the father does.
Done when: check.sh passes.
Report: 15 lines or fewer.
"""

GOAL = "/goal Row 22 is finished and /handoff has run. Stop after 40 turns with a status report. How: read HANDOFF.md."


def without(text, needle):
    assert needle in text, needle
    return text.replace(needle, "", 1)


def misses_text(kind, text):
    return "\n".join(pc.check(text, kind))


def department_block():
    return re.search(r"\*\*Department brief\*\*[^\n]*\n```\n(.*?)```", WORKFLOW, re.S).group(1)


def handoff_prompt():
    after = HANDOFF.split("## Prompt for the next chat", 1)[1]
    return after[after.index("`") + 1:after.rindex("`")]


def run_cli(text, *args):
    with tempfile.TemporaryDirectory() as d:
        path = os.path.join(d, "p.md")
        with open(path, "w", encoding="utf-8", newline="\n") as f:
            f.write(text)
        done = subprocess.run([sys.executable, os.path.join(HERE, "prompt_check.py"), path, *args],
                              capture_output=True, text=True, timeout=60, stdin=subprocess.DEVNULL)
    return done.returncode, done.stdout + done.stderr


def test_the_brief_template_passes_the_brief_kind():
    assert pc.check(TEMPLATE, "brief") == []


def test_brief_names_each_missing_heading():
    text = without(without(TEMPLATE, "\n## Ripple\n"), "\n## Proof\n")
    out = misses_text("brief", text)
    assert "Ripple" in out and "Proof" in out and "Why" not in out, out


def test_brief_over_80_lines_is_a_miss():
    out = misses_text("brief", TEMPLATE + "\nx" * 100)
    assert "80" in out, out


def test_oneshot_in_any_label_style_passes():
    assert pc.check(ONESHOT, "oneshot") == []


def test_oneshot_names_every_missing_part():
    out = misses_text("oneshot", without(without(ONESHOT, "Stop rules: 2 rounds, then report.\n"), "**Output contract**"))
    assert "Stop rules" in out and "Output contract" in out and "Inputs" not in out, out


def test_oneshot_label_inside_a_sentence_does_not_count():
    out = misses_text("oneshot", ONESHOT.replace("Do NOT: edit any file.", "Say you do NOT: edit any file."))
    assert "Do NOT" in out, out


def test_chat_department_brief_from_workflow_passes():
    assert pc.check(department_block(), "chat") == []
    assert pc.check(CHAT, "chat") == []


def test_chat_names_each_missing_department_line():
    out = misses_text("chat", without(without(CHAT, "Lane plan: agy writes the tool, cf max reviews.\n"), "Report: 15 lines or fewer.\n"))
    assert "Lane plan" in out and "Report" in out and "Context" not in out, out


def test_sonnet_chat_prompt_must_start_with_goal():
    out = misses_text("chat", CHAT.replace("Model: Opus high", "Model: Sonnet high"))
    assert "/goal" in out, out


def test_goal_prompt_passes_and_needs_no_department_lines():
    assert pc.check(GOAL, "chat") == []


def test_goal_prompt_over_4000_characters_is_a_miss():
    out = misses_text("chat", GOAL + " x" * 2000)
    assert "4000" in out, out
    assert pc.check(GOAL + " x" * 1900, "chat") == []  # 3,800 characters: under the cap


def test_goal_prompt_without_a_turn_cap_is_a_miss():
    out = misses_text("chat", "/goal Row 22 is finished. How: read HANDOFF.md.")
    assert "turn cap" in out, out


def test_the_next_chat_prompt_in_handoff_passes_when_it_is_a_goal_prompt():
    prompt = handoff_prompt()
    assert prompt.strip()
    if prompt.startswith("/goal"):
        assert pc.check(prompt, "chat") == [], pc.check(prompt, "chat")


def test_cli_exit_1_names_each_miss_and_exit_0_says_ok():
    code, out = run_cli(without(without(ONESHOT, "Inputs: docs/*.md. Read nothing else.\n"), "Stop rules: 2 rounds, then report.\n"),
                        "--kind", "oneshot")
    assert code == 1 and "Inputs" in out and "Stop rules" in out, out
    assert sum(1 for ln in out.splitlines() if ln.startswith("MISS")) == 2, out
    code, out = run_cli(ONESHOT, "--kind", "oneshot")
    assert code == 0 and "ok" in out, out


def test_cli_rejects_an_unknown_kind_and_a_missing_file():
    code, out = run_cli(ONESHOT, "--kind", "poem")
    assert code != 0 and code != 1, (code, out)
    done = subprocess.run([sys.executable, os.path.join(HERE, "prompt_check.py"), "no_such_file.md", "--kind", "brief"],
                          capture_output=True, text=True, timeout=60, stdin=subprocess.DEVNULL)
    assert done.returncode not in (0, 1), done.stdout + done.stderr


if __name__ == "__main__":
    tests = [v for k, v in sorted(globals().items()) if k.startswith("test_")]
    for t in tests:
        t()
    print(f"test_prompt_check: {len(tests)} tests passed")
