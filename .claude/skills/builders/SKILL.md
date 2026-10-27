---
name: builders
description: Run code builders (agy, Cloudflare DeepSeek, free text runs) from spec to merge, debug recipe, and the prompt recipe for every executor. Use before briefing or reviewing any builder or subagent.
---
# Builders: one skill for planning, building, debugging and briefing

## When to use
Any code or text work handed to someone else: a builder run (agy, DeepSeek via cf_build, opencode :free), a Haiku/Sonnet
subagent, a review lens, or a bug you diagnose. Claude plans, orchestrates and reviews; builders write (CLAUDE.md).

## Roster and caps
Numbers live in `tools/builders.conf` (caps, memory floor, idle minutes, models); never copy them here. `bash tools/slots.sh`
shows what is running. Models and routes: DECISIONS "Tools and builders". Calibrated readers and lenses:
docs/research/calibration-2026-10.md.

## The loop
1. Spec: a design with no open questions (Opus decides; Sonnet never invents design).
2. Failing tests first, written by Claude; the builder may not edit them (the gate rejects it).
3. Brief from docs/briefs/TEMPLATE.md: Why, Read first, What to build, Do NOT edit, May edit, Ripple (every listener, key
   and id the change touches), Tests, Checklist, Proof. The builder's skill is named in the brief ("<name> skill").
4. `bash tools/slots.sh`, then `bash tools/build_pipeline.sh <oc|agy|cf> <task> <brief> <base>` with run_in_background
   (cf: tools/cf_build.sh). It refuses when full or the base is unpushed.
5. Read the first word of `../game-wt/<task>.result` (PASS / FAIL / NOWORK / BREACH). Read a PASS only.
6. Review panel on the diff: `.claude/agents/review-code` (and review-player for renders), flags only; Claude confirms
   each flag against the code before acting. Max 3 fix rounds, then stop and report.
7. `bash tools/merge_run.sh <task>`; Claude merges, builders never merge or push to main.

## Debug recipe
1. Reproduce headless (`tools/run_godot.sh -s res://tests/runner.gd -- <name>`; read the FAIL lines).
2. Write a red test that fails for the reported reason.
3. Fix until it is green; keep the test.
4. State the root cause in one line (commit message or docs/LESSONS.md if it will recur).
5. Add the check that stops the class (lint rule, gate rule, or test), not only this instance.

## Prompt recipes
Every brief, for any executor, fits in 60 lines:
- **Goal**: why, in one line.
- **Inputs**: exact paths and line ranges, then "read nothing else".
- **Steps**: numbered, each with an observable output.
- **Do NOT**: paths and actions.
- **Output contract**: exact format, maximum lines, where it is written.
- **Done**: conditions that can be checked.
- **Stop rules**: maximum rounds, and when to stop and report.
- **Budget**: maximum tool calls or turns.

Per executor:
- **Haiku** (subagent; large, mechanical, reading-heavy; it overthinks complex work):
  - one task type per run, <= 8 steps;
  - exact files and grep patterns with head_limit;
  - a fixed output template, with one worked example line;
  - "if unsure write UNSURE and the evidence, never guess";
  - list what NOT to report;
  - split big jobs into parallel runs over disjoint inputs;
  - no design choices; effort from calibration (reader: high; lens: low).
- **Sonnet** (session or subagent; strong when scoped, loops when the task is vague):
  - Opus makes the decisions first, so no open design questions are left;
  - give the acceptance tests or checks;
  - `/advisor opus`; a loop cap of 3 rounds;
  - "grep, then read the named lines";
  - the delegation briefs pre-written;
  - milestone-only reports; hand off at ~100k work tokens.
- **agy** (Gemini Flash; Godot UI and code with renders; not creative):
  - geometry, colour and size numbers plus the concept path for any visual;
  - first commit within 15 minutes (the idle watchdog);
  - GEMINI.md review_misses;
  - it never judges legibility or feel; renders are judged by the player lens.
- **DeepSeek** (Cloudflare via opencode; code plus tests; edits outside its scope):
  - an explicit Do NOT edit list and tests written first and protected;
  - small file sets;
  - spend logged by cf_build.
- **Free models** (opencode or OpenRouter :free; text only):
  - public content only; one-shot when possible; within the 50-a-day budget;
  - only the roles that passed calibration (lens: nemotron-3-ultra :free; not a reader).
- **Reviewers** (lens agents):
  - inputs are the diff, the brief and the criteria only;
  - flag correctness and requirement gaps only;
  - <= 15 lines.

## Pointers
- Lessons for builders: lessons.md next to this file. Open questions to research: research-queue.md.
- Rules that apply to every task: CLAUDE.md, docs/EFFICIENCY.md 3b.
