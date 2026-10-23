---
name: coding-gameplay
description: Builds gameplay features in the Qarnaw repo test-first: Claude fixes the acceptance tests and brief, GLM-5.3 implements in its own worktree, Gemma 4 26B scaffolds boilerplate, and the build gate plus headless Godot tests verify it. Use when writing new game scripts, implementing a mechanic from a spec, refactoring a module, or adding a headless test harness.
argument-hint: [feature-or-file-target]
disable-model-invocation: false
---

# Building a gameplay feature

Claude does not write bulk code in its own context: it writes the brief and tests, a builder writes the code
(CLAUDE.md, docs/EFFICIENCY.md 3b). Grep docs/MAP.md and docs/ARCHITECTURE.md for the area first.

## Routes (audited 2026-10-24)
No MCP tool calls GLM-5.3 or Gemma; both run as opencode builders on Cloudflare Workers AI (paid, logged in
../game-wt/cf_spend.csv) through tools/cf_build.sh -> build_pipeline.sh (check.sh, one fix pass, build_gate.py).
Run with run_in_background, cwd = the main checkout, `< /dev/null`; `bash tools/slots.sh` first.

| Job | Model | Command |
| --- | --- | --- |
| Feature code, multi-file | GLM-5.3 | `bash tools/cf_build.sh <task> <brief> main cloudflare-workers-ai/@cf/zai-org/glm-5.3` |
| Boilerplate: Def classes, JSON content, test stubs | Gemma 4 26B | `bash tools/cf_build.sh <task> <brief> main cloudflare-workers-ai/@cf/google/gemma-4-26b-a4b-it` |
| Free first choice when its quota is open | Inkling :free / Gemini | `bash tools/build_pipeline.sh oc <task> <brief> main` / `... agy ...` |

## Steps
1. Tests first: name the tests/test_<feature>.gd cases from the spec (docs/specs/ or docs/design/) in the brief, with
   exact expected values read from content JSON, never hard-coded in the builder's code.
2. Boilerplate (Defs, JSON rows, localization keys in an existing CSV) as its own Gemma task when it is large;
   otherwise it rides in the feature brief.
3. Feature brief from the 3b TEMPLATE, under ~4k tokens: the spec section, the files to touch, the code rules
   (typed, <= 200 lines a file, <= 40 a function, `## purpose` line, no path lookups, no numbers in code), the game
   skill to load (godot-gameplay-scripter, game-designer, ...), and a Checklist the gate tests.
4. Read only a PASS result. Review the diff against the brief (Haiku subagent first; Claude reviews rules, saves and
   signals; trace rewired signals to their old listeners). Read fix-pass test diffs for hard-coded values.
5. Merge with `bash tools/merge_run.sh`. A FAIL with test or Godot errors goes to /debugging-games.

## Retry and failover
A run that ends FAIL (not a test FAIL the fix pass owns) or times out: rerun once unchanged. A second failure: never
invent the code; rerun the brief on agy (`bash tools/build_pipeline.sh agy <task>-agy <brief> main`). agy out of
quota too: report blocked.
