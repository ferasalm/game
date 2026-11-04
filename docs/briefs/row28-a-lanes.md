# Brief: row28-a-lanes (agy; JSON, shell and Python, RUN_KIND=py; red tests first from the head)
You are in your own worktree on branch gemini/row28-a-lanes (made from origin/main after part d). Follow GEMINI.md, including
<review_misses>. Load the builders skill.
Pattern: tools/free_providers.txt, tools/test_free_providers.py, opencode.json
Timebox: 40 min (<= 45). First commit within 15 min, then small WIP commits.

## Why
Feras 11-04: DeepSeek 1017 and GLM-5.3-flash are paid on OpenRouter; use free requests first, then paid at reasoning high under a $3 per month provider-side cap and his OK per run. Peak pricing exists only on DeepSeek's own endpoint (verified live 11-04), so OpenRouter provider routing replaces the peak wait. Pillar served: combat feel wins ties (accurate mechanics code).

## Read first
opencode.json (nvidia models and options), tools/builders.conf (NV_CHAIN, NV_FALLBACK_RE), tools/free_providers.txt and its test, the paid rules in docs/SPEND.md, .claude/skills/low-cost-pipeline/routing.md.

## What to build
1. opencode.json: provider openrouter, models deepseek/deepseek-v4.1-flash-1017 and z-ai/glm-5.3-flash, each with options.provider {"quantizations": ["fp8","bf16"], "ignore": ["DeepSeek"], "sort": "price", "allow_fallbacks": true} (DeepSeek's own endpoint is the only peak-priced one) and reasoning effort high; a variant named max for test writing and debugging; limit.output 131072.
2. free_providers.txt: a new rule class `paid <prefix> <exact id>` for exactly those two ids, usable only when the env PAID_OK=1 is set by the launcher (the run's SPEND line is Feras's OK). Without PAID_OK=1 every paid id is refused by the pipeline guard that reads this file, with a message naming docs/SPEND.md.
3. builders.conf: a separate PAID_CHAIN with the two paid ids, unused until PAID_OK. The day chain NV_CHAIN becomes OpenRouter :free first, then cerebras, then nvidia (NIM last: prototyping only) ONLY after Feras re-logs OpenRouter into oc-v2 (11-04 its key says "User not found": every build would time out before falling back) and the `openrouter/free` smoke passes; until then NV_CHAIN stays cerebras then nvidia. NV_MODEL unchanged for the overnight queue (part j).
4. Tests extended in tools/test_free_providers.py: the two ids pass only with PAID_OK=1; any other openrouter id without :free is refused; opencode.json parses and carries ignore DeepSeek on both paid models.

## Do NOT edit
D6 defaults, protected by tools/build_gate.py without being listed. Keep this prose free of backticks outside May edit.

## May edit
`opencode.json`
`tools/free_providers.txt`
`tools/builders.conf`
`tools/test_free_providers.py`

## Ripple
Every builder and reviewer reads free_providers.txt (test_free_providers.py scans builders.conf and cross_review.opencode.json for slugs); routing.md and models.md name the chain (part e updates the docs). The OpenRouter key limit ($3 per month) is set by Feras on openrouter.ai: until he does, PAID_CHAIN stays unused.

## Pre-mortem
- opencode ignores options.provider: check one OpenRouter generation record after a smoke call (the provider named in it is not DeepSeek); if ignored, route by a dedicated model alias instead.
- A paid id leaks into the free chain: the guard test above.
- Free requests run out (1000 per day, 20 per minute): NV_FALLBACK_RE already falls to the next model.

## Tests
- tools/test_free_providers.py :: test_paid_ids_need_paid_ok, test_paid_models_skip_deepseek_endpoint (red on the base). Player-visible: not applicable (tooling).

## Checklist
- file: opencode.json
- has: tools/free_providers.txt :: paid
- test: tools/test_free_providers.py :: test_paid_ids_need_paid_ok

## Proof
`bash tools/check.sh --no-godot` raw last 15 lines; final message ends with `Built-by: Gemini 3.8 Flash (agy)`.
