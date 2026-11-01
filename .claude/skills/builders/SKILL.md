---
name: builders
description: Run code builders (agy, Cloudflare DeepSeek, free text runs) from spec to merge, debug recipe, and the prompt recipe for every executor. Use before briefing or reviewing any builder or subagent.
---
# Builders: one skill for planning, building, debugging and briefing

## When to use
Any code or text work handed to someone else: a builder run (agy, DeepSeek via cf_build, OpenRouter :free lens), a Haiku
subagent, a review lens, or a bug you diagnose. Claude plans, orchestrates and reviews; builders write (CLAUDE.md).
Who runs it (Feras 10-28, departments are labels): the chat that launches a run reviews it (tiered) and merges it: the
father, or an Opus child chat that waits idle on its runs; docs/WORKFLOW.md, Start here step 3. Many may run at once; tools/slots.sh still caps runs.

## Roster and caps
Numbers live in `tools/builders.conf` (caps, memory floor, idle minutes, models); never copy them here. `bash tools/slots.sh`
shows what is running. Models and routes: DECISIONS "Tools and builders"; model cards: models.md (pick by card). Calibrated readers and lenses:
docs/research/calibration-2026-10.md.

## Who does what (Feras 11-01 Rank 1; only these workers and efforts)
| Work | Worker | How | Gate |
|---|---|---|---|
| Code, tools, tests, docs from a brief | agy `gemini-3.8-flash-medium` | build_pipeline.sh agy; `RUN_KIND=py` for tools and docs | check, build_gate, cross-review by cf max (`XR_OC_MODEL` nemotron :free backup) |
| Hard logic, risky scripts, complex test/spec drafts, every fix pass, cross-review | cf DeepSeek max | cf_build.sh (or `cf_probe.py --effort max` for 1-shot draft) | same; agy reviews |
| Exact edits with a Pattern file and locked red tests | cf DeepSeek non-reasoning | cf_build.sh ... fast | same; agy reviews |
| Sorting, summaries, repo recon digests, quick questions, patches from a diagnosis | cf DeepSeek non-reasoning | cf_probe.py --effort none; generate_patch | the caller spot-checks 3 lines (if `cf_probe` exits 2 on `[DONE]` cut, retry at `low` or `agy`) |
| Bulk text, colour pre-filter | GLM-5.3-flash | cf_probe.py; off until its row 24 calibration passes | the caller spot-checks 3 lines |
| Reads over ~20k tokens across files (when `cf_probe` cannot) | Haiku medium | Agent tool: `model: haiku`, `effort: medium`, template answer | the caller re-greps every "not found" claim |
| Launch-and-wait CLI wrapper, template checks, simplest Claude-only task | Haiku low | Agent tool: `model: haiku`, `effort: low` (never spawn a Sonnet subagent) | template check |
| A chunk of 10+ noisy calls that strictly needs this chat's memory | a fork, at most 2 at once | Agent tool: `subagent_type: fork`, only under ~100k context; above that a Haiku low subagent with a brief | report of 15 lines or fewer |
`/subtask` is the same fork, but only a person can type it. A fork runs on its parent's model, so keep it under ~100k context and use `Haiku low` subagents whenever chat memory is not required. Never spawn a Sonnet subagent to call builders or Haiku subagents.
Every worker's result is one line: `worker | task | gate | evidence path | time | cost | real findings`. One smoke call before any batch.

## The loop
1. Spec: a design with no open questions (Opus decides; Sonnet never invents design).
2. Failing tests first, written or locked by Claude; the builder may not edit them (the gate rejects it). Parallel builder parts each get only their own red test in their branch (row 23 lesson: sibling red tests in the shared base fail every part's check; merge parts by hand once each part's own test passes).
3. Brief from docs/briefs/TEMPLATE.md: Why, Read first, What to build, Do NOT edit, May edit, Ripple (every listener, key
   and id the change touches), Tests, Checklist, Proof. The builder's skill is named in the brief ("<name> skill").
4. `bash tools/slots.sh`, then `bash tools/build_pipeline.sh <oc|agy|cf> <task> <brief> <base>` with run_in_background
   (cf: tools/cf_build.sh). It refuses when full or the base is unpushed. Python or docs only: `RUN_KIND=py` (no Godot
   slot or memory floor; `check.sh --no-godot`; the gate fails any Godot file; merge_run reruns the full check).
   Then the cache waker, also in the background: `bash tools/wait_run.sh <task>...`; obey its "Best move" line; TaskStop
   it in the message that gates the run. Expected over ~3 h (an overnight build): /handoff at launch instead (a
   fresh chat gates it).
5. Read the first word of `../game-wt/<task>.result` (PASS / FAIL / NOWORK / BREACH). Read a PASS only.
6. Review panel on the diff: agent `studio:review-code` (plugins/studio/agents; and studio:review-player for renders), flags only; Claude confirms
   each flag against the code before acting. Max 3 fix rounds, then stop and report.
7. `bash tools/merge_run.sh <task>`; the child that started the run merges it; builders never merge or push to main.

## Debug recipe
1. Reproduce headless (`tools/run_godot.sh -s res://tests/runner.gd -- <name>`; read the FAIL lines).
2. Write a red test that fails for the reported reason.
3. Fix until it is green; keep the test.
4. State the root cause in one line (commit message or docs/LESSONS.md if it will recur).
5. Add the check that stops the class (lint rule, gate rule, or test), not only this instance.

## Prompt recipes
Every brief, for any executor, fits in 80 lines:
- **Goal**: why, in one line.
- **Inputs**: exact paths and line ranges, then "read nothing else".
- **Steps**: numbered, each with an observable output.
- **Do NOT**: paths and actions.
- **Output contract**: exact format, maximum lines, where it is written.
- **Done**: conditions that can be checked.
- **Stop rules**: maximum rounds, and when to stop and report.
- **Budget**: maximum tool calls or turns.

Per executor:
- **Haiku** (subagent; thin CLI launch-and-wait, template checks, or mechanical reading; it overthinks complex work):
  - one task type per run, <= 8 steps;
  - exact files and grep patterns with head_limit;
  - a fixed output template, with one worked example line;
  - "if unsure write UNSURE and the evidence, never guess";
  - list what NOT to report;
  - split big jobs into parallel runs over disjoint inputs;
  - no design choices; effort: `low` for launch-and-wait, lens, and checks; `medium` only for >20k multi-file reads when `cf_probe` cannot (never `high`; never call `/advisor` unasked—report BLOCKED to parent).
- **Sonnet** (the default session Lead, always at high, Feras 11-01; strong when scoped, never spawned as a subagent to call builders):
  - Opus makes the decisions first, so no open design questions are left;
  - give the acceptance tests or checks;
  - stuck twice on the same thing -> stop looping and ask Feras via AskUserQuestion (with a pick) to call `/advisor opus` (never call `/advisor opus` or `/advisor sonnet` unasked);
  - grep, then read <=2 small named excerpts yourself; delegate larger reads/summaries to `cf_probe.py --effort none` or Haiku `low`/`medium`;
  - the delegation briefs pre-written; write small things yourself only when writing the brief costs more tokens than the edit;
  - milestone-only reports; finish the task, whatever the context size;
  - the prompt is one message starting `/goal <done condition>` with a turn cap; it shows each check's result in the chat (the goal check reads only the chat) and asks with AskUserQuestion, never by ending a turn.
- **agy** (Gemini Flash; Godot UI and code with renders; Python tools, docs and reviews when its quota is free; not creative):
  - geometry, colour and size numbers plus the concept path for any visual;
  - first commit within 15 minutes (the idle watchdog);
  - GEMINI.md review_misses;
  - it never judges legibility or feel; renders are judged by the player lens.
- **DeepSeek** (Cloudflare via opencode; code plus tests; edits outside its scope):
  - an explicit Do NOT edit list and tests written first and protected;
  - include `.claude/rules/code.md` and a house Pattern example when running `fast` (`none`) so types and JSON traps (`is int`) pass checks;
  - small file sets;
  - spend logged by cf_build.
- **Free models** (OpenRouter :free active; `opencode/*-free` built-in routes off while quota is spent):
  - public content only; one-shot when possible; within the daily budget;
  - only the roles that passed calibration (lens: `nemotron-3-ultra :free` via `XR_OC_MODEL`; not a reader).
- **Reviewers** (lens agents):
  - inputs are the diff, the brief and the criteria only;
  - flag correctness and requirement gaps only;
  - <= 15 lines.

## Pointers
- Lessons for builders: lessons.md next to this file. Open questions to research: research-queue.md.
- Rules that apply to every task: CLAUDE.md, docs/WORKFLOW.md (Builder loop).