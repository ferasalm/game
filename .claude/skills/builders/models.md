# Builder Model Cards
Model profiles, benchmarks, measured calibration scores, and failure modes.

## Gemini 3.8 Flash (agy)
- **ID**: `gemini-3.8-flash-medium` (`AGY_MODEL` in `tools/builders.conf`; Feras 10-31, the calibration lines below ran at high)
- **Artificial Analysis**: Intelligence Index 31 (unverified, AA 2026-10-29), Coding Index 76.3 (unverified, AA 2026-10-29)
- **Calibration**: Review 3/5 known bugs found twice (audit sec 5); race B reached passing code in ~20 min. Medium, first gated build
  (frame-score, RUN_KIND=py, 10-31): gate PASS with no fix pass, code and two own commits in ~6 min, 36 min end to end (the checks);
  its own background tasks are waited on, not polled. Reviews then found 6 real edge-case bugs its tests missed; research: licences 3/3 right, AA numbers 1/3 invented
- **Known failure modes**: 1 of 10 findings harmful, 1 false; argued wrong side on fail-open/closed (audit sec 5); cannot review its own runs
- **Best use**: Build (Godot gameplay code with tests, UI renders, Python tools, docs); cross-review for oc/*

## DeepSeek V4.1 Flash (nv and opencode)
- **ID**: `nvidia/deepseek-ai/deepseek-v4.1-flash` (`NV_MODEL`, NVIDIA NIM, free, since 11-04) / `opencode/deepseek-v4.1-flash-free` (spent).
  The lines below were measured on Cloudflare Workers AI (retired 11-04 after a $32.29 bill): same model, but NIM is slower
  (a one-number answer at max took 135 s, 11-04): re-measure on the first nv builds
- **Artificial Analysis**: Intelligence Index 48 (unverified, AA 2026-10-29), Coding Index 76 (unverified, AA 2026-10-29)
- **Calibration**: Review 0/3 blocks in live runs (audit sec 5); in race B edited a protected file (BREACH, audit sec 5)
- **Root causes (row 17, 10-30)**: (1) nv one-shot review: Workers AI thinks at "high" by default, in a channel opencode
  does not show; on the 17 KB parser packet it filled the 32k output cap (3 of 3 replays, 0 text). `reasoning_effort:
  "low"` in the opencode model options fixed it (tools/cross_review.opencode.json); `--variant low` and a raised
  `limit.output` did nothing. Builds never hit it: each agent step is short. (2) opencode free "hang": the free usage
  limit was spent; opencode prints nothing and exits 0. Now --print-logs + the pipeline stops at once (NOWORK quota).
- **Calibration (parser, 2 key bugs, 10-30, nv, low)**: valid block, 195 s, 25.5k out, ~$0.04: 1/2 key (non-UTF-8
  crash; CRLF missed), 1 real minor (--out crash), 2 doubtful (drive-letter path, reversed range), 1 unchecked (pipe escape)
- **Speed (nv_audit.sh, 10-31, one 16-field Def task, n=1)**: `reasoning_effort: none` 6.7 s, 1.5k out, 228 tok/s, ~$0.002; max 167 s,
  28.3k out, ~$0.034; `thinking: disabled` is ignored by Workers AI (it thought 72 s). Whole builds gain less: Godot checks do not speed up.
- **Quality on that task**: none, bare prompt: untyped helpers (project.godot makes that a check failure), `is int` and `is PackedStringArray`
  JSON traps; max, bare: typed, `is int`-style trap kept. none + code rules + Def examples (12 s): typed, Array handled, flagged the
  DefReader house pattern, `is int` kept. So a Pattern file and the gates do the work; none is unmeasured on a real build.
- **Non-reasoning, other work (10-31, Opus scored)**: sorting 8/8 in 0.44 s; GDScript question right in 0.56 s (clumsy one-liner);
  diagnosed patch right in 1.0 s. First real `fast` build (fast-probe-stream, RUN_KIND=py, 10-31): code in ~1 min, correct, gate PASS,
  cross-review 0 findings (agy medium); 57 min end to end: checks ~11 min each, stale MAP sent it to a max fix pass that sat 25 min
  idle on its own background check; the builder never committed (pipeline WIP commits).
- **Known failure modes**: BREACH on protected files (race B); opencode free quota runs out (opencode.ai/go to subscribe);
  a direct nv stream stops silently at the literal text `[DONE]` with finish "stop": none cuts the reply, max cuts in the thinking and
  returns nothing (10-31); opencode builds are not hit (fast and max: whole reply); cf_mcp does not stream; nv_audit.sh now exits 2, `"cut": true`
- **Best use**: hard logic and debugging at max; `fast` (no reasoning) for exact work with a Pattern and tests, bulk text, quick code
  questions, patches from a written diagnosis; review lens at max (cross-review at none not tested: builder time is free, ~$0.08 a review);
  setup audit lens at max via `tools/nv_audit.sh` (row 25 calibration 11-01, docs/audits/2026-11-01-coach-compare.md: 0 false claims in 15 checked,
  complementary to Haiku, so the union is the audit; run it with inline read-only config, the repo's opencode.json outranks OPENCODE_CONFIG)

## NVIDIA Nemotron 3 Ultra :free (OpenRouter)
- **ID**: `openrouter/nvidia/nemotron-3-ultra-550b-a55b:free` (`XR_OC_MODEL` in `tools/builders.conf`)
- **Artificial Analysis**: Intelligence Index 40 (unverified, AA 2026-10-29), Coding Index 70 (unverified, AA 2026-10-29)
- **Calibration**: Reading 8/12 right, 2 wrong (A8, A9), 0 unsure; lens 6/6 found, 0 false flags (calibration-2026-10.md)
- **Known failure modes**: Fails reader bar on absence claims; text-only input via OpenRouter tool (calibration-2026-10.md); OpenRouter key renewed and active (11-01; previously 401 on 10-31)
- **Best use**: Backup lens only, capped at 5 min (`XR_OC_TIMEOUT`, Feras 10-31: speed is its one merit; ~7 min on a review on 10-29, so
  the cap will often stop it, and then Claude's gate goes on alone)

## GLM-5.3 (Cloudflare, retired 11-04)
- **ID**: was `cloudflare-workers-ai/@cf/zai-org/glm-5.3`; on no free provider now
- **Calibration (parser, 10-30, default effort)**: valid block, 619 s, 30.3k out (near the 32k cap): 1/2 key (non-UTF-8;
  CRLF missed), 1 real minor (--out crash), 2 doubtful. Same score as nemotron and DeepSeek-low, 3x slower
- **Best use**: second-reviewer candidate; set reasoning low before long one-shot work

## GLM-5.3-Flash (NVIDIA NIM free; was Cloudflare)
- **ID**: `nvidia/z-ai/glm-5.3-flash` (`XR_REVIEWER_GEMINI` and `_DEEPSEEK`; reasoning_effort max accepted, 11-04) / `opencode/glm-5.3-flash-free` (spent)
- **Artificial Analysis**: Intelligence Index 36 (unverified, AA 2026-10-29), Coding Index 70 (unverified, AA 2026-10-29)
- **Calibration**: vision works on nv (one synthetic image, right answer, 1.5 s, 10-31). 6 real 640 px frames vs review-player (10-31,
  default, 4-17 s a frame): colour + character visible 11/12, text readable 2/6; both planted defects caught. No
  adjustable reasoning levels on the flash model (Feras 10-31; it still thought with `none`). Video, Terminal-Bench: unverified.
  Code is its weak spot: the 16-field Def task took 813 s (first text 763 s, 44k out, 54 tok/s) vs DeepSeek none 6.7 s
- **Row 24 calibration (11-01, bulk text)**: digest of a 116-line audit (docs/audits/2026-11-02-integrity.md) into <= 30 lines, scored on the audit's own Top 10 after grep: GLM-5.3-flash default **9/10** (217 s, 16.7k out; missed equipment_hero_header.gd:177; no invented file or line; filled the 30 lines, six of them `leave` noise) vs Haiku medium **9/10** (31 s, 64k Claude tokens, 19 lines grouped well; missed timeline.gd:8; no invented line). Pass bar 8/10: GLM ON for bulk text digests and sorting (n=1: the caller spot-checks 3 lines); the colour pre-filter job went to Clef-flash (Routing); GLM stays a candidate there only.
- **Audit lens (11-02, docs/audits/2026-11-01-coach-compare.md, Third lens)**: setup audit via `tools/nv_audit.sh` with `AUDIT_MODEL`: 6 of 7 claims true, 1 unique true find, 1 invented claim (reported a path as absent after a failed read of a wrong path); a third lens only, every claim checked
- **Best use**: Bulk text digests and sorting (calibrated row 24, 9/10) and a candidate screenshot pre-filter; never the CLI step (check.sh, gate, merge are scripts)

## Laguna-S 2.1 :free (OpenRouter)
- **ID**: `openrouter/laguna/laguna-s-2.1:free` (not listed in `tools/builders.conf`)
- **Artificial Analysis**: Intelligence Index 32 (unverified, AA 2026-10-29), Coding Index 64 (unverified, AA 2026-10-29)
- **Calibration**: Reading not run; lens 5/6 found (missed B6 licence), 0 false flags (calibration-2026-10.md)
- **Known failure modes**: Missed licence defect (B6); missing from opencode CLI catalogue (lessons-archive.md)
- **Best use**: Backup review lens

## ThinkingMachines Inkling :free (OpenRouter)
- **ID**: `openrouter/thinkingmachines/inkling:free` (not listed in `tools/builders.conf`)
- **Artificial Analysis**: Intelligence Index 28 (unverified, AA 2026-10-29), Coding Index 60 (unverified, AA 2026-10-29)
- **Calibration**: none yet
- **Known failure modes**: Works only inside agents (403 on MCP; lessons-archive.md)
- **Best use**: Text drafts, research lookups; opencode.json's bare default, so a build or review always passes its own --model

## NVIDIA Nemotron 3.5 Lightning :free (OpenRouter)
- **ID**: `openrouter/nvidia/nemotron-3.5-lightning:free` (not listed in `tools/builders.conf`)
- **Artificial Analysis**: Intelligence Index 30 (unverified, AA 2026-10-29), Coding Index 62 (unverified, AA 2026-10-29)
- **Calibration**: none yet
- **Known failure modes**: Uncalibrated on gold sets
- **Best use**: Small text / helper tasks; opencode.json's small_model, never a build or a review

## Review head to head (one agy diff, frame-score, 10-31; all findings read by Opus)
| Reviewer | Time | Findings | Worth |
|---|---|---|---|
| nv DeepSeek 1017 max (opencode) | ~10 min, 2 rounds | 10, then 6 | best: most real bugs, test gaps with concrete inputs; parser rejected both rounds on one line with no `->` |
| Haiku medium | 51 s, 39k tokens | 7, clean format | good: only one to catch prose answers invented as two (Claude tokens) |
| Haiku low | 34 s, 35k tokens | 9, clean, packet line numbers | good: preamble shift, plain-string answers (Claude tokens) |
| GLM-5.3-flash default | 429 s, 29k out | 4, clean format | real but few; only one to catch a BOM |
| nv DeepSeek none (direct) | 13 s, 1k out | 14 lines, half thinking aloud ending "Skip" | 2-3 real; breaks the format, not a lens |
| Nemotron 3.5 Super VL (`openrouter/nvidia/nemotron-3.5-super-vl:free`) | no result | 3 tries hung (2, 5, 15 min), no error | tiny prompt answered in 7 s earlier; speed on a real packet unmeasured (key renewed 10-31); opencode/...-free quota spent |

## Settings in force (Feras 10-30)
- agy: `gemini-3.8-flash-medium` (Feras 10-31); `agy models` lists low, medium, high; no output cap flag.
- NVIDIA DeepSeek V4.1 Flash (free): reasoning_effort max (opencode.json, tools/cross_review.opencode.json) + opencode's hidden
  output cap raised to 384k, its full output (limit.output on the model in opencode.json and tools/cross_review.opencode.json, builders.conf says why; high effort: 900 s, 88k out). Parser set at max: valid block,
  443 s, 66k out, ~$0.08: 1/2 key, 1 real minor, 1 doubtful (less noise than low). Watch the first max build: if steps
  trip the 25-min no-commit watchdog, builds drop to high. GLM: cap raised; effort option untested (row 18).
- opencode.json defines nv DeepSeek at max and none only: a default or high run (row 26) needs its model entry first.
- Cross-review: agy runs -> nv DeepSeek at max; nemotron only as a backup lens after nv fails twice. nv is free (tools/free_providers.txt).

## Routing
Which worker does what: the low-cost-pipeline skill, routing.md. A card's Best use says what a model suits; that table decides who runs.
Limits: Clef-flash pre-filters colour and character visible only, review-player keeps text; non-reasoning never reviews.
Evidence: docs/research/model-evidence-2026-10.md (AA numbers mostly UNVERIFIED: 1 of 3 spot-checked was invented)
and the measured calibration lines above. Calibrated = passed a gold set (D11).
- RETIRED 11-04 with Cloudflare: Clef-flash (`@cf/cloudflare/clef-flash`, not chat: `/ai/run`, model + state + questions, images = data-URI strings), colour/character pre-filter: 6 frames, 12/12 vs review-player, both planted defects, 3-9 s, ~$0.00002 a frame; text readable 3/6 (scores flat ~0.4).
- Jev 1.13 Free (`jev-1.13-free`, opencode.ai/inference/systemone/v1/systemone, no key, free for a limited time), error sorting and rubric scoring: 8/8 on easy lines with labelled causes, 1-3.5 s; a hard set not run.
opencode built-in free routes (DeepSeek, GLM-5.3-flash, Nemotron VL) are off while their free quota is spent (10-30); OpenRouter :free routes (XR_OC_MODEL nemotron-3-ultra) are active (key renewed 10-31). OC_MODEL still defaults to the spent DeepSeek route: a run on it ends NOWORK quota, use nv_build.sh.

## Rule
A new model is used only after a calibration run (D11).
