# Routing: who does what (the one routing table; Feras 11-01, roles 11-04 "what-we-have pipeline", reviewers and chains 11-05)
Numbers (caps, memory floor, idle and quiet limits, models, chains, reviewer map) live in `tools/builders.conf`; never copy them here (tools/test_routing_docs.py).
Model cards and calibration: `.claude/skills/builders/models.md`, `docs/research/calibration-2026-10.md`. Calibrated = passed a gold set (D11); nothing else runs.

## Who does what
| Work | Worker | How | Gate |
|---|---|---|---|
| Plan, spec, brief, decisions, red tests, final review, merge | the Claude head (Opus or Sonnet, high) | this chat; test ideas may come from isolated one-shot consults (row 28 part i), the implementing builder never sees them | Feras |
| Most building: Godot code, scenes, tools, docs | agy gemini-3.8-flash-medium | `bash tools/build_pipeline.sh agy <task> <brief> <base>` | locked tests, check.sh, build_gate, cross-review (builders.conf) |
| Accuracy work: debugging, balancing, optimization, controls, physics and combat logic, every fix pass | DeepSeek V4.1 Flash 1017 (max today: opencode.json defines max and none only; high for routine builds once row 28 part a adds the variant) | `bash tools/nv_build.sh <task> <brief> <base>` (the deepseek chain) | check.sh, build_gate, cross-review (builders.conf) |
| Creative work: level design, technical art, dialogue, narrative, player text, UI wording, design prose (designs and JSON data, not core code) | GLM-5.3-flash | `bash tools/nv_build.sh <task> <brief> <base> glm`, RUN_KIND=py | review-canon, cross-review (builders.conf) |
| Mechanical edits with no reasoning | DeepSeek non-reasoning (`fast`) | mechanical.md | diff equals the edit list, a locked test |
| Sorting, summaries, digests, quick questions | DeepSeek non-reasoning or GLM-5.3-flash | `bash tools/nv_audit.sh` (one-shot) | the caller spot-checks 3 lines |
| Routine reads | agy gemini-3.8-flash-low, then a Haiku medium subagent | agy -p, or Agent tool with a template answer | the caller re-greps every "not found" |
| Flag confirmation (greps only) | Haiku medium subagent | Agent tool, template in foremen.md | the head adjudicates what holds |
| Code review of a DeepSeek run, big diffs, Claude diffs | studio:review-code (Haiku xhigh) | Agent tool; cross_review.sh says when builders.conf hands a run to Claude | the head confirms each flag |
| Read a web page (research, docs, a builder that needs one) | Obscura headless browser, no Chrome | `bash tools/obscura.sh <url> [text\|markdown\|links]` (never --stealth; local/private addresses stay blocked; login pages are out of reach) | the caller spot-checks the text |
| A noisy chunk that strictly needs this chat's memory | a fork, max 2, under ~100k context | Agent tool, subagent_type fork | report of 15 lines or fewer |
| Sonnet as a subagent | allowed at high with an Opus-scoped brief (Feras 11-02, to save Opus usage) | Agent tool, model sonnet | the head reviews its report |
| Consultant on a named decision | GLM-5.3-Max or GPT-6.1-Sol | Feras's OK each time | the head |

## Lanes and fallbacks (Feras 11-04, 11-05)
- Free first. A provider refusal retries the SAME model on its next route (builders.conf NV_CHAIN, GLM_CHAIN), never another model; every route refused ends the run red and the head re-routes the part (agy builds most).
- NVIDIA NIM is today's free route for DeepSeek and GLM: slow and flaky (a review may time out; then the backup lens, then Claude's gate). It becomes the overnight queue (row 28 part j) once the paid lane exists.
- Paid OpenRouter (DeepSeek 1017, GLM-5.3-flash) on its own key with a $3 monthly provider-side cap, PAID_OK=1 and Feras's OK per run (row 28 part a).
- Backup review lens: Nemotron 3 Ultra :free (builders.conf XR_OC_MODEL), only after nv fails twice; never a builder.

## Model personalities (Feras 11-02, his reading of the benchmarks; calibrate with docs/runs.csv)
- DeepSeek V4.1 Flash 1017: the most disciplined, top logic scores, weakest on knowledge. Gives it exact specs, locked tests, a Pattern file and a Do NOT edit list.
- GLM-5.3-flash: the most nuanced and imaginative, best human understanding and writing. Gets anything a person reads, and the player's side of a brief. Not a code reviewer (fewest real findings in the 10-31 head to head, Feras 11-05).
- agy gemini-3.8-flash: the most knowledgeable (physics, HLE, Omniscience), the least disciplined, transparent and imaginative. Gets facts and Godot work behind locked tests; never alone on discipline-heavy work; always reviewed by another family.
- Reviewer is always a different family than the author (tools/builders.conf XR_REVIEWER_*). The brief critic is a different family than the test writer.

## Efforts
Only the efforts Feras names: DeepSeek none (fast), low, high, max; GLM-5.3-flash has no levels; agy medium (low for reads, high only when asked); Haiku medium for reads, xhigh for anything that writes, reviews or debugs (max not used); Claude head and Sonnet subagents at high. Fix passes always get the reasoning model.

## Parallel parts
Several runs of one model at once are fine up to the caps (per builder family). Complementary, never conflicting: disjoint May edit sets, one owner for a shared new file, no part touching another's tests. Check with tools/parts_plan.py.
