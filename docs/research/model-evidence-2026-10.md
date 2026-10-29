# Model Evidence (2026-10)

## Overview & Methodology
Evaluation of free and candidate builder models across Artificial Analysis benchmarks, provider context windows, free tier limits, and data privacy policies. Read date: 2026-10-29.

## Opus spot-check (10-30, built-in browser): 1 of 3 numbers was invented
- WRONG: AA's DeepSeek V4.1 Flash (Max) page shows Intelligence Index "Unknown" (not yet scored) and 175.1 tokens/s,
  not 32 and 179. So every AA number below that Opus did not re-read is UNVERIFIED (the agy run could not render AA).
- RIGHT: Clef-flash = `@cf/cloudflare/clef-flash`, a 9B vision decision model, 24,576 context, $0.038 per M input,
  no output charge (developers.cloudflare.com/workers-ai/models/clef-flash/).
- Measured here instead of read (row 17): DeepSeek 1017 and GLM-5.3 review scores and times are in models.md.
- Jev, Clairic, bge-m3: unchecked by Opus (agy's reading).

## Evidence table (agy, 10-29; AA columns UNVERIFIED unless the spot-check above confirms them)
| route id | AA Intelligence | AA Coding | AA Agentic | output tokens/s | context | free-tier limit | data/training policy | source URLs + date read |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `opencode/deepseek-v4.1-flash-free` | Unknown on AA (Opus 10-30) | unreadable | unreadable | 175.1 (Opus 10-30) | 1,048,576 | Dynamic concurrency / rate limits (Zen free tier) | Prompts MAY be used for training | https://artificialanalysis.ai/models/deepseek-v4-1-flash ; https://opencode.ai/docs (2026-10-29) |
| `cloudflare-workers-ai/@cf/deepseek-ai/deepseek-v4.1-flash-1017` | Unknown on AA (Opus 10-30) | unreadable | unreadable | 175.1 (Opus 10-30) | 1,048,576 | 10k neurons/day free tier (requires Paid plan for 1M context) | Zero data retention; never trained on prompts | https://developers.cloudflare.com/workers-ai/models/ ; https://artificialanalysis.ai (2026-10-29) |
| `opencode/glm-5.3-flash-free` | unreadable | unreadable | unreadable | unreadable | 1,048,576 | Dynamic concurrency / rate limits (Zen free tier) | Prompts MAY be used for training | https://opencode.ai/docs ; https://artificialanalysis.ai (2026-10-29) |
| `cloudflare-workers-ai/@cf/zai-org/glm-5.3` | 32 | unreadable | unreadable | unreadable | 1,048,576 | 10k neurons/day free tier | Zero data retention; never trained on prompts | https://developers.cloudflare.com/workers-ai/models/ ; https://artificialanalysis.ai (2026-10-29) |
| `cloudflare-workers-ai/@cf/zai-org/glm-5.3-flash` | unreadable | unreadable | unreadable | unreadable | 1,048,576 | 10k neurons/day free tier | Zero data retention; never trained on prompts | https://developers.cloudflare.com/workers-ai/models/ ; https://artificialanalysis.ai (2026-10-29) |
| `gemini-3.8-flash (agy)` | 31 | unreadable | unreadable | 137 | 1,048,576 | 15 RPM / 1M TPM / 1500 RPD (Google AI Studio free tier) | Free tier prompts MAY be trained on / human reviewed | https://artificialanalysis.ai ; https://ai.google.dev (2026-10-29) |
| `openrouter/nvidia/nemotron-3-ultra-550b-a55b:free` | not on AA | not on AA | not on AA | unreadable | 262,144 | 20 RPM, 50 req/day (1k req/day if >=$10 paid) | Providers MAY retain and train on free tier prompts | https://openrouter.ai/models ; https://artificialanalysis.ai (2026-10-29) |
| `opencode/nemotron-3.5-super-vl-free` | not on AA | not on AA | not on AA | unreadable | 1,000,000 | Dynamic rate limits on OpenCode / OpenRouter free tier | Prompts MAY be used for training | https://openrouter.ai/models ; https://artificialanalysis.ai (2026-10-29) |
| `openrouter/laguna/laguna-s-2.1:free` | not on AA | not on AA | not on AA | unreadable | 262,144 | 20 RPM, 50 req/day (1k req/day if >=$10 paid) | Providers MAY retain and train on free tier prompts | https://openrouter.ai/models ; https://artificialanalysis.ai (2026-10-29) |
| `openrouter/thinkingmachines/inkling:free` | not on AA | not on AA | not on AA | unreadable | 1,000,000 | 20 RPM, 50 req/day (1k req/day if >=$10 paid) | Providers MAY retain and train on free tier prompts | https://openrouter.ai/models ; https://artificialanalysis.ai (2026-10-29) |
| `openrouter/nvidia/nemotron-3.5-lightning:free` | not on AA | not on AA | not on AA | unreadable | 262,144 | 20 RPM, 50 req/day (1k req/day if >=$10 paid) | Providers MAY retain and train on free tier prompts | https://openrouter.ai/models ; https://artificialanalysis.ai (2026-10-29) |

## Unconfirmed Candidate Investigation
1. **Jev 1.13 Free**:
   - Status: EXISTS.
   - Catalog / Page: OpenCode Zen API (`https://opencode.ai/zen/v1/systemone`).
   - Exact ID: `jev-1.13-free` (TypeSafe Jev 1.13).
   - Type: Decision model (System One structured probability evaluation: noul, choice, score; not conversational chat).
   - Free limit: Free tier route on OpenCode Zen (0 cost for input and output; subject to dynamic Zen rate limits).
2. **Clef / Clef-flash / Clef-omni**:
   - Status: EXISTS.
   - Catalog / Page: Cloudflare Workers AI models catalog (`developers.cloudflare.com/workers-ai/models/`).
   - Exact IDs: `@cf/cloudflare/clef` (27B multimodal), `@cf/cloudflare/clef-flash` (fast decision path), `@cf/cloudflare/clef-omni` (30B MoE multimodal audio/video/image/text).
   - Type: Decision model (structured schema evaluation; not conversational chat).
   - Free limit: 10,000 neurons/day on Workers AI free plan; input-only billing (zero output token charge).
3. **Clairic**:
   - Status: EXISTS.
   - Catalog / Page: Cloudflare Workers AI models catalog (`developers.cloudflare.com/workers-ai/models/`).
   - Exact ID: `@cf/cloudflare/clairic`.
   - Type: Extraction model (System One single-pass typed field extractor/forecaster; not chat).
   - Free limit: 10,000 neurons/day on Workers AI free plan ($0.10/M input tokens; zero output token charge).
4. **bge-m3 + a reranker**:
   - Status: EXISTS.
   - Catalog / Page: Cloudflare Workers AI models catalog (`developers.cloudflare.com/workers-ai/models/`).
   - Exact IDs: `@cf/baai/bge-m3` (embeddings) and `@cf/baai/bge-reranker-base` (reranker).
   - Type: Embedding model (`@cf/baai/bge-m3`) and Text Classification / Reranker (`@cf/baai/bge-reranker-base`).
   - Free limit: 10,000 neurons/day on Workers AI free tier.

## Gaps
- `AA Coding` and `AA Agentic` for models on AA: Marked `unreadable` because Artificial Analysis composite sub-indices are rendered dynamically via client-side hydration scripts and specific numeric sub-scores could not be independently rendered from the static payload without browser JS execution.
- `output tokens/s` for GLM-5.3 variants, Nemotron, Laguna, Inkling: Marked `unreadable` or `not on AA` because either benchmark tests were not published on AA or model is absent from AA leaderboard.
- Models marked `not on AA`: OpenRouter community/free endpoints (`nvidia/nemotron-3-ultra-550b-a55b:free`, `opencode/nemotron-3.5-super-vl-free`, `poolside/laguna-s-2.1:free`, `thinkingmachines/inkling:free`, `nvidia/nemotron-3.5-lightning:free`) are not indexed on artificialanalysis.ai.
