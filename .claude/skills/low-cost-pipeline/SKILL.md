---
name: low-cost-pipeline
description: Feras's 11-01 three-tier pipeline for Sonnet-high chats: head (Sonnet + GLM-5.3 max critic), middle (GLM-5.3 max scopes and writes red tests via opencode), hand (DeepSeek V4.1 Flash low/high/max and agy gemini-3.8-flash-medium execute). Use when a chat must plan, delegate, build and review at near-zero Claude cost.
---
# Low-cost pipeline (Feras 11-01): head, middle, hand

Sits on top of the builders skill (its Who does what table, loop, gates and merge scripts stay in force). This skill only
adds the tier split and the commands. One smoke call per route before any batch (all five routes smoked 11-01).

## Tiers
| Tier | Worker | Job | Command |
|---|---|---|---|
| Head | Claude Sonnet 5.5 high (this chat) | design, brief, review, merge, decide; never writes bulk code | - |
| Head critic | GLM-5.3 max, Cloudflare | cross-check the plan, the brief and the diff before the head acts | `python tools/cf_probe.py --model @cf/zai-org/glm-5.3 --effort max --prompt-file p.md --out r.txt` (read-only) |
| Middle | GLM-5.3 max via opencode | scope a brief into steps and Ripple, write the red tests | `bash tools/cf_build.sh <task> <brief> <base> cloudflare-workers-ai/@cf/zai-org/glm-5.3` |
| Hand | DeepSeek V4.1 Flash, `low` / `high` / `max` / `fast` (none) | implement against the locked tests | `bash tools/cf_build.sh <task> <brief> <base> [cloudflare-workers-ai/deepseek-v4.1-flash-low\|-high\|fast]`; no model = max |
| Hand | agy `gemini-3.8-flash-medium` | Godot code, discovery, docs from a brief | `bash tools/build_pipeline.sh agy <task> <brief> <base>` (`RUN_KIND=py` for Python and docs) |

Models live in `opencode.json` (GLM max, DeepSeek low, high, fast, max; limits set). `cf_build.sh` takes the model as its 4th argument.

## Flow of one task
1. Head writes the spec (no open questions) and a brief from docs/briefs/TEMPLATE.md; the critic reads spec + brief and lists gaps; the head fixes real ones.
2. Middle (GLM max, `RUN_KIND=py` if no Godot) turns the brief into a scoped brief with Ripple and writes only the red tests in its own branch.
3. Head reads the tests (never trust a builder-written test unread: weak or gamed assertions are the usual defect), edits or rejects, then locks them. The gate rejects a hand that edits them.
4. Hand implements: DeepSeek low for exact edits with a Pattern, high for logic, max for hard logic and every fix pass; agy for Godot and docs. Parts run in parallel, each with only its own red test (builders loop, step 2).
5. Gate = `check.sh` + build_gate + `cross_review.sh` (critic lens: a different model than the author: GLM max reviews DeepSeek and agy work, DeepSeek max reviews GLM work). Head confirms every flag against the code.
6. Head merges (`merge_run.sh <task> oc` for cf runs), reads `.result`, never only the summary.

## Rules
- `/advisor`: CLAUDE.md duty 6 stands here too: stuck twice, ask Feras first; never unasked.
- The head writes only what the brief would cost more than the edit; risky machinery (hooks, gates, saves, settings) the head reads line by line.
- Cost: Cloudflare is billed in neurons (cf_spend.csv, no cap); GLM max is slower than DeepSeek (parser run: 619 s vs ~443 s), so run it background and wait for the notification.
- GLM-5.3 max calibration so far: second-reviewer level only (1/2 key defects, models.md); judge its tests and flags, do not copy them.
- Exit codes: a `.result` first word PASS / FAIL / NOWORK / BREACH decides; stdout of opencode proves nothing.
