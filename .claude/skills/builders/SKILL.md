---
name: builders
description: The prompt recipe for every executor (Haiku, Claude/Sonnet, agy, DeepSeek, free lenses, reviewers) and the debug recipe. Use before briefing or reviewing any builder or subagent. The workflow itself (plan, routing, flow, merge) lives in the low-cost-pipeline skill.
---
# Builders: how to brief each executor, and how to debug
The workflow, the routing table, caps, the flow of one part and the proof runs are in `.claude/skills/low-cost-pipeline/`
(SKILL.md first). This skill keeps only what is true of each executor's prompt, plus the debug recipe. Models and routes:
docs/decisions-tools.md; model cards: models.md; lessons for builders: lessons.md; open questions: research-queue.md.

## Debug recipe
1. Reproduce headless (`tools/run_godot.sh -s res://tests/runner.gd -- <name>`; read the FAIL lines).
2. Write a red test that fails for the reported reason.
3. Fix until it is green; keep the test.
4. State the root cause in one line (commit message or docs/LESSONS.md if it will recur).
5. Add the check that stops the class (lint rule, gate rule, or test), not only this instance.

## Prompt recipes
Every brief, for any executor, fits in 80 lines (templates: `.claude/skills/low-cost-pipeline/templates/`):
- **Goal**: why, in one line.
- **Inputs**: exact paths and line ranges, then "read nothing else".
- **Steps**: numbered, each with an observable output.
- **Do NOT**: paths and actions.
- **Output contract**: exact format, maximum lines, where it is written.
- **Done**: conditions that can be checked.
- **Stop rules**: maximum rounds, and when to stop and report.
- **Budget**: maximum tool calls or turns.

Per executor:
- **Haiku** (subagent; thin CLI launch-and-wait, template checks, flag confirmer, or mechanical reading; it overthinks complex work):
  - one task type per run, <= 8 steps; exact files and grep patterns with head_limit;
  - a fixed output template, with one worked example line; "if unsure write UNSURE and the evidence, never guess";
  - list what NOT to report; split big jobs into parallel runs over disjoint inputs; no design choices;
  - effort `low` for launch-and-wait, lens and checks; `medium` only for >20k multi-file reads when `nv_audit.sh` cannot (never `high`; never call `/advisor` unasked: report BLOCKED to the parent).
- **Claude (Opus or Sonnet), as the head or a subagent** (Sonnet always at high, Feras 11-01; allowed as a subagent, Feras 11-02):
  - the decisions are made first, so no open design questions are left; give the acceptance tests or checks;
  - stuck twice on one thing -> stop looping and ask Feras via AskUserQuestion (with a pick) to call `/advisor opus` (never unasked);
  - grep, then read <=2 small named excerpts yourself; delegate larger reads and summaries to `tools/nv_audit.sh` (one-shot) or Haiku;
  - milestone-only reports; finish the task, whatever the context size.
- **agy** (Gemini Flash; Godot code, facts, discovery, Python tools and docs when its quota is free; not creative or disciplined):
  - geometry, colour and size numbers plus the concept path for any visual; first commit within 15 minutes (idle watchdog);
  - GEMINI.md review_misses; it never judges legibility or feel (the player lens does); always reviewed by another family.
- **DeepSeek** (NVIDIA NIM via opencode, free; code plus tests; edits outside its scope):
  - an explicit Do NOT edit list and tests written first and protected;
  - include `.claude/rules/code.md` and a house Pattern example when running `fast` (`none`) so types and JSON traps pass checks;
  - small file sets; exact edit lists for the mechanical lane; spend logged by runs.csv.
- **GLM-5.3** (NVIDIA NIM via opencode, free; the player-facing words, the player's side of a brief, test authoring): tests and text, not bulk code; judge its flags, do not copy them.
- **Free models** (OpenRouter :free active; `opencode/*-free` routes are spent): public content only; one-shot when possible; only the roles that passed calibration (lens: `nemotron-3-ultra :free` via `XR_OC_MODEL`; not a reader).
- **Reviewers** (lens agents): inputs are the diff, the brief and the criteria only; flag correctness and requirement gaps only; <= 15 lines.
