#!/usr/bin/env python3
"""Routing docs point at tools/builders.conf instead of copying its reviewer map, and route no work to a retired model
(Feras 11-05, after an outside review found WORKFLOW.md and models.md saying agy runs went to DeepSeek while builders.conf
sent them to GLM, and routing.md still sending work to Clef-flash and GLM-5.3 max). python tools/test_routing_docs.py"""
import os
import re

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ROUTING = [".claude/skills/low-cost-pipeline/routing.md", ".claude/skills/low-cost-pipeline/SKILL.md",
           ".claude/skills/builders/SKILL.md", "docs/WORKFLOW.md"]
MAP_DOCS = ROUTING + [".claude/skills/builders/models.md", "docs/decisions-tools.md"]
RETIRED = re.compile(r"Clef|Cloudflare|Inkling|Laguna|GLM-5\.3 max|qwen|Cerebras|\bcf\b", re.I)
REVIEW = re.compile(r"cross-review|reviewed by (agy|gemini|DeepSeek|GLM|nv|Haiku|Claude|nemotron)"
                    r"|reviews? (agy|gemini|DeepSeek|GLM|oc/|nv)", re.I)  # "reviewed by another family" is no map
MODEL = re.compile(r"\b(agy|gemini|DeepSeek|GLM|nemotron|Haiku|Claude)\b", re.I)
# "<family> runs: <model>" or "<family> runs -> <model>": the shape a wrapped map takes on one line
FAMILY_TO = re.compile(r"(gemini/\*|oc/\*|\bagy|\bDeepSeek|\bGLM)( \w+)? runs?\b[^|\n]{0,6}(->|:|\()\s*"
                       r"(nv\b|NVIDIA|DeepSeek|GLM|agy|Haiku|Claude)", re.I)


def lines(rel):
    with open(os.path.join(ROOT, rel), encoding="utf-8") as f:
        return f.read().splitlines()


def copies_the_map(line):
    """A line that says who reviews whom by model name without pointing at builders.conf."""
    named = bool(REVIEW.search(line) and MODEL.search(line)) or bool(FAMILY_TO.search(line))
    return named and "builders.conf" not in line


def test_routing_docs_name_no_retired_model():
    bad = [f"{rel}:{i}: {ln.strip()[:90]}" for rel in ROUTING for i, ln in enumerate(lines(rel), 1) if RETIRED.search(ln)]
    assert not bad, "retired model in a routing doc (models.md keeps the history):\n" + "\n".join(bad)


def test_no_doc_copies_the_reviewer_map():
    bad = [f"{rel}:{i}: {ln.strip()[:90]}" for rel in MAP_DOCS for i, ln in enumerate(lines(rel), 1) if copies_the_map(ln)]
    assert not bad, "a reviewer map outside tools/builders.conf (point at it instead):\n" + "\n".join(bad)


def test_the_rules_catch_one_bad_case_each():  # probe each new rule with one bad case (LESSONS 3)
    assert copies_the_map("PASS: cross-review; gemini/* runs: NVIDIA DeepSeek V4.1 Flash at max effort")
    assert copies_the_map("     oc/* runs (agy reviews, free, ~11 min); gemini/* runs: NVIDIA DeepSeek V4.1 Flash")
    assert copies_the_map("- Cross-review: agy runs -> nv DeepSeek at max")
    assert not copies_the_map("cross-review: the other family (tools/builders.conf XR_REVIEWER_*)")
    assert RETIRED.search("| Colour pre-filter | Clef-flash |") and RETIRED.search("Red tests | GLM-5.3 max")
    assert not RETIRED.search("Code review of a DeepSeek run | studio:review-code (Haiku xhigh)")


if __name__ == "__main__":
    from tool_tests import run_cases
    run_cases([v for k, v in sorted(globals().items()) if k.startswith("test_")], "test_routing_docs")
