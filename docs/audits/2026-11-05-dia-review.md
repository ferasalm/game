# Dia review of the workflow (2026-11-05): verified, decided, done, handed off
Input: feedback by Dia (the Dia browser's assistant) after reading main's routing.md, builders.conf, model cards, USAGE.md
and HANDOFF. Chat: Opus 5.5 xhigh, worktree dia-review. Feras's picks: decisions-log 11-05 (five lines).

## Claims, checked on main and the open branches (verdict | evidence)
| # | Dia's claim | Verdict | Evidence and correction |
|---|---|---|---|
| 1 | agy and DeepSeek code both go to GLM-5.3-flash, the weakest code reviewer | true | builders.conf XR_REVIEWER_*; models.md head to head (GLM 4 findings, "real but few"); WORKFLOW and models.md said DeepSeek: the conf was the stale copy of 11-02, the 11-04 decision already said DeepSeek |
| 2 | routing.md gives red tests to retired GLM-5.3 max; DeepSeek max should write them | stale line true, fix rejected | DECISIONS 11-04: the head writes red tests; DeepSeek writing them would undo it |
| 3 | Cerebras qwen-3.8-27b sits in the chain without a card (D11) | true, worse | $0.99 in, $1.49 out per M, no cache discount, 131k context (opencode models cache); part a's interim made it the FIRST day hop; Nemotron Ultra (last hop) was calibrated as a lens only |
| 4 | Laguna-S, Inkling, Clef-flash, GLM-5.3 full are dead weight | true | Laguna 5/6 vs Nemotron 6/6, unused; Inkling = opencode.json default, uncalibrated; Clef and GLM-5.3 max still routed in routing.md |
| 5 | Long chats drive cost | true | USAGE.md row 26: 448 calls, 307M cache reads, 619k peak; "one part per chat" already existed (10-31) and was broken |
| 6 | DeepSeek to paid OpenRouter, ~$0.04 a max review | true | already part a; 66k out x $0.60/M |
| 7 | The meter logs Cerebras at $0 | true | one global NV_INPUT_RATE=0 "every provider is free" vs free_providers.txt "Cerebras spends credit" |
| 8 | Pipeline crowds out the game | roughly true | most sessions since 10-27 are Ops; M1 not started |
| 9 | 98% of the weekly cap by 10-31; Opus gates every merge | true | USAGE.md 10-31 row; the Opus gate is Feras's priority 1, kept |
| 10 | 1 min of code vs 57 min end to end | true, causes wrong | models.md: checks ~11 min each and a stale-MAP fix pass idle 25 min, not the memory floor or sibling tests |
| 11 | Docs disagree with builders.conf | true | also found: review agents at effort low vs the 11-04 xhigh rule; "Haiku low" in six routing lines; HOW_WE_WORK named the retired cf lane |

## Feras decided (11-05)
1. Row 28 keeps its order (c, b, a, e, then i, h, j, f) before M1: Dia's time-box not taken.
2. Calibrated models only, one chain per family: DeepSeek for accuracy, GLM-5.3-flash for creativity.
3. DeepSeek's code is reviewed by Claude studio:review-code (Haiku xhigh), not agy or GLM.
4. Soft 300k context line replaces 10-31's "context never hands off".

## Done in this chat (merged with part d, which Opus reviewed: the preflight parses the real `auth list --standalone` columns)
- tools/builders.conf: reviewer map, NV_CHAIN and GLM_CHAIN (same model only), meter comment; tools/free_providers.txt: Cerebras and Groq out.
- tools/cross_review.sh: a family mapped to `claude` runs no lens and writes the hand-off into the review file.
- tools/nv_build.sh: 4th arg deepseek|glm|model. tools/hooks/token_handoff.py: one note past 300k context, re-armed below.
- Tests: test_routing (map), test_nv_build (family words, one model per chain), test_build_pipeline (chain), test_free_providers
  (any *_CHAIN scanned), test_token_handoff (300k note), new test_routing_docs.py (no copied reviewer map, no retired model
  in routing docs; probed with bad cases).
- Docs: routing.md rewritten to the 11-04 roles; models.md (NOT USED line, prices and cliffs, pointer to the conf);
  WORKFLOW, HOW_WE_WORK, CLAUDE.md, DECISIONS, decisions-tools, low-cost-pipeline SKILL and changelog, foremen,
  emergency-efficiency, players-eye-gate, pm handoff skill; plugins/studio review agents effort xhigh; opencode.json bare default = NV_MODEL (the calibrated builder; Inkling was never calibrated).
- Briefs: a revised, e renamed row28-e-meter and rescoped, f gains qwen, plan status 11-05.

## Implementation plan for the rest (the row 28 chat: Opus high, `pwsh tools\next_chat.ps1`; Sonnet high can run it)
Order is Feras's (11-05). Each part: red tests written by the head on `<part>-tests`, `bash tools/lock_tests.sh`, build,
gate, review per builders.conf, merge one at a time. Workers: routing.md; never more than one Haiku subagent per part.
1. c cliff-guard and b peak-gate in parallel (agy; tests drafted in docs/briefs/row28-locked-tests/*.py.txt: copy to
   tools/ on each part's own base, `git add -A`, map.py, doc_graph.py, push). agy runs are reviewed by DeepSeek max
   (`bash tools/cross_review.sh`); on NIM time-outs the backup lens runs, then the head's own diff read.
2. a lanes (agy; brief revised 11-05): paid lines with rates, PAID_DEEPSEEK/PAID_GLM as the last hop only with PAID_OK=1.
   No paid call: Feras's OK per run. The head fills the two rates from openrouter.ai before locking the tests.
3. e meter (agy, after a; nv_build.sh is shared, so merge it only when no run is live).
4. With Feras awake: i (test consults), h (GLM content lane: `nv_build.sh ... glm`, review-canon), j (overnight NIM), f
   (calibration, qwen included, any Cerebras spend = a SPEND line + his OK).
5. Reviewer rollback test (carried P6): plant one defect in the first Godot agy run's diff copy; DeepSeek max missing it on
   2 such runs in a row -> GLM back as a second lens (decisions-log 11-05). A DeepSeek run's review file says Claude:
   launch studio:review-code (Agent tool, effort xhigh) on `git diff <base>...<head>`.
6. Then row 4 (M1 wave 1 on agy).
Nested subagents: a builder never spawns Claude; a Haiku subagent may run greps but not another agent; a head may fork once
for a noisy log read (routing.md). Stuck twice on one step: ask Feras for /advisor opus.

## Left out on purpose
- Dia's DeepSeek-writes-tests and the 150k hard line (Feras picked otherwise); time-boxing row 28 (Feras: keep the plan).
- Build time (claim 10): needs data, not a guess: the carried kaizen item (5 runs of `python tools/kaizen_report.py`) now
  also reads check.sh step times; planned in the row 28 chat after c and b.
- The ops review the session hook called due: this audit covers the routing half; the full one stays planned (WORKFLOW Protocols).
- Paid smoke of DeepSeek on OpenRouter: waits on Feras's per-run OK (decisions 11-04).

## How this chat worked (for next time)
Greps and two small excerpts per file instead of a reader subagent (the facts sat in 8 files under 160 lines each);
one AskUserQuestion with four decisions, each with a pick; part d reviewed and merged here because its HANDOFF and
prompt lines collided with this work (a straight history beats a merge conflict for the next chat); Opus wrote the
gate and hook code itself (small, risky), briefs carry the token-heavy builds; one Haiku review-code (xhigh) on the code
diff and review-feras before merge; checks by script.
