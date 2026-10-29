# Builder Model Cards
Model profiles, benchmarks, measured calibration scores, and failure modes.

## Gemini 3.8 Flash (agy)
- **ID**: `gemini-3.8-flash-high` (`AGY_MODEL` in `tools/builders.conf`)
- **Artificial Analysis**: Intelligence Index 31 (unverified, AA 2026-10-29), Coding Index 76.3 (unverified, AA 2026-10-29)
- **Calibration**: Review 3/5 known bugs found twice (audit sec 5); race B reached passing code in ~20 min
- **Known failure modes**: 1 of 10 findings harmful, 1 false; argued wrong side on fail-open/closed (audit sec 5); cannot review its own runs
- **Best use**: Build (Godot gameplay code with tests, UI renders, Python tools, docs); cross-review for oc/*

## DeepSeek V4.1 Flash (cf and opencode)
- **ID**: `cloudflare-workers-ai/@cf/deepseek-ai/deepseek-v4.1-flash-1017` (`CF_MODEL`) / `opencode/deepseek-v4.1-flash-free` (`OC_MODEL`)
- **Artificial Analysis**: Intelligence Index 48 (unverified, AA 2026-10-29), Coding Index 76 (unverified, AA 2026-10-29)
- **Calibration**: Review 0/3 blocks in live runs (audit sec 5); in race B edited a protected file (BREACH, audit sec 5)
- **Known failure modes**: Hit opencode 32k output cap, printed nothing (audit sec 5); BREACH on protected files; 0 blocks in live review
- **Best use**: Build (Godot code when agy is full, Python tools); opencode for text. Not for code review

## NVIDIA Nemotron 3 Ultra :free (OpenRouter)
- **ID**: `openrouter/nvidia/nemotron-3-ultra-550b-a55b:free` (`XR_OC_MODEL` in `tools/builders.conf`)
- **Artificial Analysis**: Intelligence Index 40 (unverified, AA 2026-10-29), Coding Index 70 (unverified, AA 2026-10-29)
- **Calibration**: Reading 8/12 right, 2 wrong (A8, A9), 0 unsure; lens 6/6 found, 0 false flags (calibration-2026-10.md)
- **Known failure modes**: Fails reader bar on absence claims; text-only input via OpenRouter tool (calibration-2026-10.md)
- **Best use**: Review lens (calibrated cross-reviewer for gemini/* runs)

## GLM-5.3-Flash (Cloudflare)
- **ID**: not listed in `tools/builders.conf` (Cloudflare-hosted / `openrouter/z-ai/glm-5.3-flash:free`)
- **Artificial Analysis**: Intelligence Index 36 (unverified, AA 2026-10-29), Coding Index 70 (unverified, AA 2026-10-29)
- **Calibration**: none yet
- **Known failure modes**: Uncalibrated; OpenRouter slug subject to drift (opencode-setup.md)
- **Best use**: Candidate text/tools builder after calibration

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

## Rule
A new model is used only after a calibration run (D11).
