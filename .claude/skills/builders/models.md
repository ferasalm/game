# Builder Model Cards
Model profiles, benchmarks, measured calibration scores, and failure modes.

## Gemini 3.8 Flash (agy)
- **ID**: `gemini-3.8-flash-medium` (`AGY_MODEL` in `tools/builders.conf`; Feras 10-31, the calibration lines below ran at high)
- **Artificial Analysis**: Intelligence Index 31 (unverified, AA 2026-10-29), Coding Index 76.3 (unverified, AA 2026-10-29)
- **Calibration**: Review 3/5 known bugs found twice (audit sec 5); race B reached passing code in ~20 min
- **Known failure modes**: 1 of 10 findings harmful, 1 false; argued wrong side on fail-open/closed (audit sec 5); cannot review its own runs
- **Best use**: Build (Godot gameplay code with tests, UI renders, Python tools, docs); cross-review for oc/*

## DeepSeek V4.1 Flash (cf and opencode)
- **ID**: `cloudflare-workers-ai/@cf/deepseek-ai/deepseek-v4.1-flash-1017` (`CF_MODEL`) / `opencode/deepseek-v4.1-flash-free` (`OC_MODEL`)
- **Artificial Analysis**: Intelligence Index 48 (unverified, AA 2026-10-29), Coding Index 76 (unverified, AA 2026-10-29)
- **Calibration**: Review 0/3 blocks in live runs (audit sec 5); in race B edited a protected file (BREACH, audit sec 5)
- **Root causes (row 17, 10-30)**: (1) cf one-shot review: Workers AI thinks at "high" by default, in a channel opencode
  does not show; on the 17 KB parser packet it filled the 32k output cap (3 of 3 replays, 0 text). `reasoning_effort:
  "low"` in the opencode model options fixed it (tools/cross_review.opencode.json); `--variant low` and a raised
  `limit.output` did nothing. Builds never hit it: each agent step is short. (2) opencode free "hang": the free usage
  limit was spent; opencode prints nothing and exits 0. Now --print-logs + the pipeline stops at once (NOWORK quota).
- **Calibration (parser, 2 key bugs, 10-30, cf, low)**: valid block, 195 s, 25.5k out, ~$0.04: 1/2 key (non-UTF-8
  crash; CRLF missed), 1 real minor (--out crash), 2 doubtful (drive-letter path, reversed range), 1 unchecked (pipe escape)
- **Speed (cf_probe, 10-31, one 16-field Def task, n=1)**: `reasoning_effort: none` 6.7 s, 1.5k out, 228 tok/s, ~$0.002; max 167 s,
  28.3k out, ~$0.034; `thinking: disabled` is ignored by Workers AI (it thought 72 s). Whole builds gain less: Godot checks do not speed up.
- **Quality on that task**: none, bare prompt: untyped helpers (project.godot makes that a check failure), `is int` and `is PackedStringArray`
  JSON traps; max, bare: typed, `is int`-style trap kept. none + code rules + Def examples (12 s): typed, Array handled, flagged the
  DefReader house pattern, `is int` kept. So a Pattern file and the gates do the work; none is unmeasured on a real build.
- **Non-reasoning, other work (10-31, Opus scored)**: sorting 8/8 in 0.44 s; GDScript question right in 0.56 s (clumsy one-liner);
  diagnosed patch right in 1.0 s. Text only: a tool-using agent run is unmeasured.
- **Known failure modes**: BREACH on protected files (race B); opencode free quota runs out (opencode.ai/go to subscribe);
  on cf a streamed reply stops silently at the literal text `[DONE]` with finish "stop" (3 of 3, none; renamed: whole reply; max untested)
- **Best use**: hard logic and debugging at max; `fast` (no reasoning) for exact work with a Pattern and tests, bulk text, quick code
  questions, patches from a written diagnosis; review lens at max (cross-review at none not tested: builder time is free, ~$0.08 a review)

## NVIDIA Nemotron 3 Ultra :free (OpenRouter)
- **ID**: `openrouter/nvidia/nemotron-3-ultra-550b-a55b:free` (`XR_OC_MODEL` in `tools/builders.conf`)
- **Artificial Analysis**: Intelligence Index 40 (unverified, AA 2026-10-29), Coding Index 70 (unverified, AA 2026-10-29)
- **Calibration**: Reading 8/12 right, 2 wrong (A8, A9), 0 unsure; lens 6/6 found, 0 false flags (calibration-2026-10.md)
- **Known failure modes**: Fails reader bar on absence claims; text-only input via OpenRouter tool (calibration-2026-10.md)
- **Best use**: Review lens (calibrated cross-reviewer for gemini/* runs)

## GLM-5.3 (Cloudflare)
- **ID**: `cloudflare-workers-ai/@cf/zai-org/glm-5.3` (not in `tools/builders.conf`)
- **Calibration (parser, 10-30, default effort)**: valid block, 619 s, 30.3k out (near the 32k cap): 1/2 key (non-UTF-8;
  CRLF missed), 1 real minor (--out crash), 2 doubtful. Same score as nemotron and DeepSeek-low, 3x slower
- **Best use**: second-reviewer candidate; set reasoning low before long one-shot work

## GLM-5.3-Flash (Cloudflare, opencode free)
- **ID**: `cloudflare-workers-ai/@cf/zai-org/glm-5.3-flash` / `opencode/glm-5.3-flash-free`
- **Artificial Analysis**: Intelligence Index 36 (unverified, AA 2026-10-29), Coding Index 70 (unverified, AA 2026-10-29)
- **Calibration**: vision works on cf (one synthetic image, right answer, 1.5 s, 10-31); real frames vs review-player not run. No
  adjustable reasoning levels on the flash model (Feras 10-31; it still thought with `none`). Video, Terminal-Bench: unverified.
  Code is its weak spot: the 16-field Def task took 813 s (first text 763 s, 44k out, 54 tok/s) vs DeepSeek none 6.7 s
- **Best use**: Candidate screenshot pre-filter and bulk text after calibration; never the CLI step (check.sh, gate, merge are scripts)

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
- **Best use**: Text drafts, research lookups

## NVIDIA Nemotron 3.5 Lightning :free (OpenRouter)
- **ID**: `openrouter/nvidia/nemotron-3.5-lightning:free` (not listed in `tools/builders.conf`)
- **Artificial Analysis**: Intelligence Index 30 (unverified, AA 2026-10-29), Coding Index 62 (unverified, AA 2026-10-29)
- **Calibration**: none yet
- **Known failure modes**: Uncalibrated on gold sets
- **Best use**: Small text / helper tasks

## Settings in force (Feras 10-30)
- agy: `gemini-3.8-flash-medium` (Feras 10-31); `agy models` lists low, medium, high; no output cap flag.
- Cloudflare DeepSeek 1017: reasoning_effort max (opencode.json, tools/cross_review.opencode.json) + opencode's hidden
  output cap raised to 384k, its full output (OPENCODE_EXPERIMENTAL_OUTPUT_TOKEN_MAX in builders.conf; high effort: 900 s, 88k out). Parser set at max: valid block,
  443 s, 66k out, ~$0.08: 1/2 key, 1 real minor, 1 doubtful (less noise than low). Watch the first max build: if steps
  trip the 25-min no-commit watchdog, builds drop to high. GLM: cap raised; effort option untested (row 18).
- Cross-review: agy runs -> cf DeepSeek at max; nemotron only as a backup lens after cf fails twice. No $ cap on cf.

## Routing (row 17, Opus proposal; Feras OKs it after row 18's calibrations)
Evidence: docs/research/model-evidence-2026-10.md (AA numbers mostly UNVERIFIED: 1 of 3 spot-checked was invented)
and the measured calibration lines above. Calibrated = passed a gold set (D11).
| Task class | Model | Calibrated |
|---|---|---|
| Godot code, Python tools, docs | agy (Gemini 3.8 Flash); cf DeepSeek 1017 when agy is full | yes (agy 2/2 PASS row 16; cf builds) |
| Review lens on agy runs | cf DeepSeek 1017 at max (~$0.08); nemotron :free only as backup lens | yes (parser 1/2 at low and max; nemotron gold B 6/6) |
| Review lens on cf/oc runs | agy | yes (hook diff 3/5) |
| Research, licences | agy, then Opus re-reads 3 facts in a browser | partly: licences 3/3 right, AA numbers 1/3 invented |
| Bulk text (summaries, sorting, notes) | cf DeepSeek no reasoning (8/8 on one sort, 0.44 s); GLM-5.3-flash candidate | one sample; awaits Feras |
| Screenshot yes/no gate | Clef-flash (cf, 9B vision decision model) as a pre-filter before review-player | no: calibrate on known frames first |
| Error sorting, rubric scoring | Jev 1.13 (opencode decision API) | no: agy says it exists, unchecked |
| Docs search (bge-m3 + reranker) | not before M1: grep over docs/MAP.md is enough for a small game | - |
opencode free routes (DeepSeek, GLM-5.3-flash, Nemotron VL) are off while the free quota is spent (10-30).

## Rule
A new model is used only after a calibration run (D11).
