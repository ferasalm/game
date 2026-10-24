---
name: architecting-games
description: Designs game systems for the Qarnaw repo (state machines, data schemas, save layouts, multi-system rules, physics and camera math) by routing the reasoning to DeepSeek V4 Pro, Nemotron 3 and Gemini 3.8 Flash builders, then writes docs/specs/<system>.md. Use when planning a new system or mechanic, a data schema, or a spatial or physics formula before any code is written.
argument-hint: [system-or-mechanic-name]
disable-model-invocation: false
---

# Architecting a game system

Opus is the state controller, planner and terminal executor only: it writes briefs, tests and specs-of-record, runs commands and reviews; the models below write the long text, the math and the log reading.

Claude plans and reviews; builders reason and write (CLAUDE.md, docs/EFFICIENCY.md 3b). Before briefing, grep
docs/MAP.md and the area's section of docs/ARCHITECTURE.md, and keep every spec inside the code rules (typed GDScript,
`logic/` pure, content in JSON Defs, live numbers in state objects, saves in GameState).

## Routes (audited 2026-10-24: these are the only real ones)
The cf-agents MCP has two tools only (`mcp__cf-agents__triage_trace`, `mcp__cf-agents__generate_patch`); no MCP tool
calls DeepSeek V4 Pro, Nemotron or Gemini. Those run as builders, each in its own worktree, through the gate:

| Job | Model | Command (run_in_background, cwd = the main checkout, `< /dev/null`) |
| --- | --- | --- |
| System layout, dependency order, tick rate, save schema | DeepSeek V4 Pro | `bash tools/cf_build.sh <task> <brief> main cloudflare-workers-ai/@cf/deepseek-ai/deepseek-v4-pro-0813` |
| NPC or enemy state trees, transitions | Nemotron 3 120B | `bash tools/cf_build.sh <task> <brief> main cloudflare-workers-ai/@cf/nvidia/nemotron-3-120b-a12b` |
| Math: vectors, quaternions, curves, collision, Godot 4.7 API checks | Gemini 3.8 Flash | `bash tools/build_pipeline.sh agy <task> <brief> main` |
| Math fallback when agy is out of quota | Gemma 4 26B | `bash tools/cf_build.sh <task> <brief> main cloudflare-workers-ai/@cf/google/gemma-4-26b-a4b-it` |

Personas: name them in the brief as "<name> skill" (build_pipeline pastes up to 2 from .agents/skills):
DeepSeek V4 Pro = software-architect + game-designer (rules, economy) or level-designer (spaces); Nemotron =
workflow-architect; Gemini or Gemma math = godot-gameplay-scripter (or godot-shader-developer, technical-artist).

`bash tools/slots.sh` first (5 runs at most across all sessions; cf runs are paid, logged in ../game-wt/cf_spend.csv).

## Steps
1. Brief from docs/EFFICIENCY.md 3b's TEMPLATE: the system, the design doc it serves (docs/design/), the files to read,
   "write only docs/specs/<system>.md", exact numbers wanted, and a Checklist the gate tests.
2. One brief per route above that the system needs; math and layout may run at once (separate tasks).
3. Read only a PASS result (`../game-wt/<task>.result`). Merge the spec parts into one docs/specs/<system>.md with:
   - Def classes and their JSON fields; state objects and their fields; save keys and the GameState version bump.
   - System order and update rate (combat runs on 60 integer ticks/s, docs/DECISIONS.md).
   - The headless test assertions (tests/runner.gd names) that prove each rule.
4. A design choice the owner makes (scope, feel, story) goes to him as 2-4 options with a recommended first one.
5. Hand the spec to /coding-gameplay.

## Retry and failover
A run that ends FAIL or times out: rerun it once unchanged. A second failure: never invent its output; rerun the same
brief on agy (`bash tools/build_pipeline.sh agy <task>-agy <brief> main`). agy out of quota too: report blocked.
