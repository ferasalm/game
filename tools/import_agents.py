#!/usr/bin/env python3
"""Copies the chosen agency agents (~/.claude/agents, MIT) into .agents/skills/<name>/SKILL.md for every builder.

agy reads .agents/skills (GEMINI.md), opencode gets one subagent each (tools/oc_agents.py), and the cf-agents MCP takes
one as `agent` (tools/cf_mcp/server.py). Claude already sees ~/.claude/agents. Feras 2026-10-24.
Usage: python tools/import_agents.py [source dir]   (then: python tools/oc_agents.py)
"""
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
DEST = ROOT / ".agents" / "skills"
# Source file stem -> skill name. Left out on purpose: web, business, sales and product-management agents.
CHOSEN = {
    "engineering-code-reviewer": "code-reviewer",
    "engineering-minimal-change-engineer": "minimal-change-engineer",
    "engineering-software-architect": "software-architect",
    "engineering-codebase-onboarding-engineer": "codebase-onboarding-engineer",
    "engineering-technical-writer": "technical-writer",
    "engineering-prompt-engineer": "prompt-engineer",
    "engineering-rapid-prototyper": "rapid-prototyper",
    "engineering-git-workflow-master": "git-workflow-master",
    "engineering-devops-automator": "devops-automator",
    "specialized-codebase-archaeologist": "codebase-archaeologist",
    "specialized-workflow-architect": "workflow-architect",
    "specialized-mcp-builder": "mcp-builder",
    "specialized-cultural-intelligence-strategist": "cultural-intelligence-strategist",
    "testing-test-results-analyzer": "test-results-analyzer",
    "testing-performance-benchmarker": "performance-benchmarker",
    "design-ui-designer": "ui-designer",
    "design-ux-architect": "ux-architect",
    "design-ui-finish-gate-reviewer": "ui-finish-gate-reviewer",
    "design-image-prompt-engineer": "image-prompt-engineer",
    "product-feedback-synthesizer": "feedback-synthesizer",
}
NOTE = ("> Builder note: GEMINI.md and the brief win where this differs (typed GDScript in Godot 4.7, no web stacks, "
        "<= 200 lines a file, numbers in content JSON). Source: agency-agents (MIT), .agents/skills/AGENCY-LICENSE.\n\n")


def convert(text: str, name: str) -> str:
    m = re.match(r"^---\n(.*?)\n---\n", text, re.S)
    if not m:
        raise ValueError(f"{name}: no frontmatter")
    desc = re.search(r"^description:\s*(.*)$", m.group(1), re.M)
    body = text[m.end():].lstrip("\n")
    d = (desc.group(1).strip().strip("'\"") if desc else name).replace("'", "''")
    return f"---\nname: 'agency-{name}'\ndescription: '{d}'\n---\n\n{NOTE}{body}"


def main(argv: list) -> int:
    src = pathlib.Path(argv[1]) if len(argv) > 1 else pathlib.Path.home() / ".claude" / "agents"
    missing = [s for s in CHOSEN if not (src / f"{s}.md").is_file()]
    for s in missing:
        print(f"FAIL {src / s}.md not found")
    for stem, name in CHOSEN.items():
        if stem in missing:
            continue
        text = (src / f"{stem}.md").read_text(encoding="utf-8").replace("\r\n", "\n")
        out = DEST / name / "SKILL.md"
        out.parent.mkdir(parents=True, exist_ok=True)
        out.write_text(convert(text, name), encoding="utf-8", newline="\n")
    print(f"import_agents: wrote {len(CHOSEN) - len(missing)} skills to {DEST}")
    return 1 if missing else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
