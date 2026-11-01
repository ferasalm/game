# Brief: row17-evidence (research; one new doc; HANDOFF row 17 part a)
You are in your own worktree on branch gemini/row17-evidence (made from origin/main). Follow GEMINI.md, including
<review_misses>. Load the minimal-change-engineer skill (Ops has no research persona; our rules outrank its text).
Timebox: 45 min. First commit within 15 min, then small WIP commits: no commit for 25 min (IDLE_MIN) = NOWORK.

## Why
Feras wants to know which free model does which task, by evidence, not by guesses (row 17). The model cards in
.claude/skills/builders/models.md carry Artificial Analysis numbers marked "unverified" that may be invented.
Pillar served (docs/VISION.md): a small game finished fast, on cheap and reliable builders.

## Read first
.claude/skills/builders/models.md (the cards), tools/builders.conf (the ids in use), docs/research/opencode-setup.md
(section 1 only).

## What to build
Write docs/research/model-evidence-2026-10.md (<= 120 lines): one table, one row per model below, columns:
route id | AA Intelligence | AA Coding | AA Agentic | output tokens/s | context | free-tier limit | data/training policy | source URLs + date read.
1. Models (route ids exactly as given): opencode/deepseek-v4.1-flash-free; cloudflare-workers-ai/@cf/deepseek-ai/deepseek-v4.1-flash-1017;
   opencode/glm-5.3-flash-free; cloudflare-workers-ai/@cf/zai-org/glm-5.3; cloudflare-workers-ai/@cf/zai-org/glm-5.3-flash;
   gemini-3.8-flash (agy); openrouter/nvidia/nemotron-3-ultra-550b-a55b:free; opencode/nemotron-3.5-super-vl-free;
   openrouter/laguna/laguna-s-2.1:free; openrouter/thinkingmachines/inkling:free; openrouter/nvidia/nemotron-3.5-lightning:free.
2. Four names from an AI search Feras ran, unconfirmed: "Jev 1.13 Free" (said to be on OpenCode via a separate
   decision-model API), "Clef / Clef-flash / Clef-omni" (said to be Cloudflare vision models), "Clairic" (said to be
   Cloudflare), "bge-m3 + a reranker" (Cloudflare embeddings). For each: does it exist? On which page (the Cloudflare
   Workers AI models catalog developers.cloudflare.com/workers-ai/models/, opencode.ai docs, models.dev)? Its exact id,
   type (chat, vision, embedding, classifier) and free limit. Not found on any official page = write "NOT FOUND" plus
   the pages searched.
3. Artificial Analysis (artificialanalysis.ai) pages render with JavaScript: open them in your browser tool and read
   the rendered numbers. A model absent from AA = "not on AA". A page you could not render = "unreadable". Never fill
   a number you did not read on the page; never copy a number from models.md.
4. Free limits and data policy from the provider's own page (opencode Zen free models, Cloudflare Workers AI pricing:
   neurons per day, OpenRouter :free limits). Say plainly when a free model may train on prompts.
5. Below the table, a "Gaps" list: each cell left empty and why.

## Do NOT edit
D6 defaults apply. Change nothing except the one new file.
`.claude/`
`docs/research/opensource-candidates.md`

## May edit

## Ripple
none: one new research doc; Opus copies verified numbers into models.md later.

## Pre-mortem
- Invented numbers (Gemini research has done this): each number needs its URL; Opus re-reads 3 in a browser.
- AA unrenderable: "unreadable", never a guess.
- Feras's four names are AI-search output: they may not exist; "NOT FOUND" is a valid, useful answer.

## Tests
None new (a doc); check.sh --no-godot must still pass.

## Checklist
- file: docs/research/model-evidence-2026-10.md
- has: docs/research/model-evidence-2026-10.md :: artificialanalysis.ai
- has: docs/research/model-evidence-2026-10.md :: developers.cloudflare.com
- has: docs/research/model-evidence-2026-10.md :: Gaps

## Proof
`bash tools/check.sh --no-godot` raw last 15 lines; final message ends with `Built-by: Gemini 3.8 Flash (agy)`.
