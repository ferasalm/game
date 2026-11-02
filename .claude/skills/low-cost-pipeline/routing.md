# Routing: who does what (the one routing table; Feras 11-01, extended 11-02)
Numbers (caps, memory floor, idle and quiet limits, models, reviewer map) live in `tools/builders.conf`; never copy them here.
Model cards and calibration: `.claude/skills/builders/models.md`, `docs/research/calibration-2026-10.md`.

## Who does what
| Work | Worker | How | Gate |
|---|---|---|---|
| Plan, spec, brief, decisions, final review, merge | the Claude head (Opus or Sonnet, high) | this chat | Feras |
| Red tests (scope run) | GLM-5.3 max, or DeepSeek max for logic-heavy code | `EXPECT_RED=1 bash tools/cf_build.sh <task>-tests ...` | scope_gate, then the head reads every test |
| Logic, scripts, tools, every fix pass, correctness review | DeepSeek V4.1 Flash 1017 max (high for routine) | `bash tools/cf_build.sh <task> <brief> <base> [model]` | check.sh, build_gate, cross-review by GLM |
| Player text, dialogue, UI wording, design prose, the player-side read of a brief | GLM-5.3 max | cf_build.sh with the GLM model, RUN_KIND=py | cross-review by DeepSeek, review-canon |
| Godot code and API or physics facts, discovery, research digests | agy gemini-3.8-flash-medium | `bash tools/build_pipeline.sh agy <task> <brief> <base>` | locked tests, review by DeepSeek or GLM |
| Mechanical edits with no reasoning | DeepSeek non-reasoning (`fast`) | mechanical.md | diff equals the edit list, a locked test |
| Sorting, summaries, digests, quick questions | DeepSeek non-reasoning or GLM-5.3-flash | `python tools/cf_probe.py --effort none` | the caller spot-checks 3 lines |
| Colour and character-visible pre-filter | Clef-flash | `/ai/run` (models.md) | review-player keeps the text |
| Flag confirmation (greps only) | Haiku low subagent | Agent tool, template in foremen.md | the head adjudicates what holds |
| Reads over ~20k tokens across files that cf_probe cannot do | Haiku medium | Agent tool, template answer | the caller re-greps every "not found" |
| A noisy chunk that strictly needs this chat's memory | a fork, max 2, under ~100k context | Agent tool, subagent_type fork | report of 15 lines or fewer |
| Sonnet as a subagent | allowed at high with an Opus-scoped brief (Feras 11-02, to save Opus usage) | Agent tool, model sonnet | the head reviews its report |

## Model personalities (Feras 11-02, his reading of the benchmarks; calibrate with docs/runs.csv)
- DeepSeek V4.1 Flash 1017 max: the most disciplined, top logic scores, weakest on knowledge. Gives it exact specs, locked tests, a Pattern file and a Do NOT edit list.
- GLM-5.3 max: the most nuanced and imaginative, best human understanding and writing, a mini Fable. Gets anything a person reads, and the player's side of a brief. Calibrated only as a second-level reviewer for code (1/2 key defects): judge its flags, do not copy them.
- agy gemini-3.8-flash: the most knowledgeable (physics, HLE, Omniscience), the least disciplined, transparent and imaginative. Gets facts and Godot work behind locked tests; never alone on discipline-heavy work; always reviewed by another family.
- Reviewer is always a different family than the author (tools/builders.conf XR_REVIEWER_*). The brief critic is a different family than the test writer.

## Efforts
Only the efforts Feras names: DeepSeek none (fast), low, high, max; GLM-5.3 max; GLM-5.3-flash has no levels; agy medium (low or high only when asked); Haiku low (medium only for >20k reads); Claude head and Sonnet subagents at high. Fix passes always get the reasoning model.

## Parallel parts
Several runs of one model at once are fine up to the caps (per builder family). Complementary, never conflicting: disjoint May edit sets, one owner for a shared new file, no part touching another's tests. Check with tools/parts_plan.py.
