---
name: debugging-games
description: Diagnoses and fixes Qarnaw crashes, failing tests, script errors and rendering bugs red-to-green: reproduce headless, triage with GLM-5.3 Flash (triage_trace MCP), patch with DeepSeek V4.1 Flash (generate_patch MCP), escalate hard cases to DeepSeek V4 Pro or GLM-5.3 builders, and verify with the test suite. Use for stack traces, SCRIPT ERROR lines, check.sh FAIL lines, visual bugs or broken assertions.
argument-hint: [error-trace-or-failing-test]
disable-model-invocation: false
---

# Debugging a game bug

Opus is the state controller, planner and terminal executor only: it writes briefs, tests and specs-of-record, runs commands and reviews; the models below write the long text, the math and the log reading.

Never apply a guess: every fix starts from a reproduced failure and ends with a test that was red and is green
(CLAUDE.md: every fixed bug gets a test).

## Routes (audited 2026-10-24)
| Job | Model | Route |
| --- | --- | --- |
| Trace, compiler or test triage | GLM-5.3 Flash | MCP `mcp__cf-agents__triage_trace` (trace, files, context) |
| Unified diff from the diagnosis | DeepSeek V4.1 Flash | MCP `mcp__cf-agents__generate_patch` (diagnosis, files, tests) |
| Huge logs, screenshots, shader or UI bugs | DeepSeek V4.1 Flash | `bash tools/cf_build.sh <task> <brief> main` (default model) |
| Bug across ticks or systems, no clear trace | DeepSeek V4 Pro | `bash tools/cf_build.sh <task> <brief> main cloudflare-workers-ai/@cf/deepseek-ai/deepseek-v4-pro-0813` |
| Patch that needs a multi-file fix | GLM-5.3 | `bash tools/cf_build.sh <task> <brief> main cloudflare-workers-ai/@cf/zai-org/glm-5.3` |

Personas: both MCP tools take `agent` (an .agents/skills name; it leads the system prompt, the tool's rules win).
triage_trace: godot-gameplay-scripter (code), godot-shader-developer (shaders), test-results-analyzer (test logs),
performance-benchmarker (FPS). generate_patch: minimal-change-engineer. Builder briefs name the same as "<name> skill";
DeepSeek V4 Pro on a cross-system bug: codebase-archaeologist.

MCP calls cost little and log to ../game-wt/cf_spend.csv; builder runs go in the background (`< /dev/null`) after
`bash tools/slots.sh`. Pass repo paths in `files`; never paste whole files or secrets.

## Steps
1. RED: `tools/run_godot.sh -s res://tests/runner.gd -- <name>` (or `tools/check.sh`; read the FAIL lines). Exit 124 or
   139 with other Godot runs open is memory or the timeout, not a test (docs/LESSONS.md): rerun first.
2. Triage: slice to the failing frame and suspect function; call triage_trace with the trace, those files and the
   design rule in `context`. Visual or multi-system bugs take the builder routes above instead.
3. GREEN: call generate_patch with the diagnosis, files and the test. Reject a diff that rewrites whole files, drops
   comments, touches unrelated logic or hard-codes a value. Save it in the scratchpad, then `git apply --check` and
   `git apply`.
4. Verify: rerun the one test, then `tools/check.sh` for the neighbouring systems. Green: commit on the session branch.
   Red: feed the new output to triage_trace once; still red: escalate to the DeepSeek V4 Pro route.

## Retry and failover
An MCP call that errors or times out: retry it once. A second failure: never invent a diagnosis or diff; brief the
same bug to agy (`bash tools/build_pipeline.sh agy <task> <brief> main`). agy out of quota too: report blocked.
