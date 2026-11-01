# Chat brief: models, builders, licences, the system diagram (HANDOFF row 17; Feras 10-29)
For a fresh Opus father chat (Ops, high). Read this brief, docs/HOW_WE_WORK.md, .claude/skills/builders/models.md and
docs/research/calibration-2026-10.md; nothing from the row 16 chat (local_1f7e111b). Builders do the reading and
writing (D18: research by builders); Opus briefs, spot-checks and decides. Children only for a part of ~15+ calls.

## Why
Feras wants to see the whole system, know which free model does which task (by evidence), know why runs fail, and
close what row 16 left "not planned". Pillar: a small game finished fast (cheap, reliable builders).

## Facts from row 16 (10-29)
- Builders: agy (Gemini 3.8 Flash) 2/2 PASS (row16-docs, row16-audit2). oc (opencode free DeepSeek V4.1 Flash) hung:
  one log line, no commit for 25 min, watchdog NOWORK (C:/dev/game-wt/row16-audit.log). DeepSeek is NOT retired: it
  stays a builder (cf via Cloudflare); only its reviewer role is off (0 blocks in 3 runs).
- Cross-review: nemotron :free returned INVALID (no BEGIN FINDINGS) on row16-docs; Opus reviewed alone.
- models.md AA numbers are unverified and suspect: the AA comparison link Feras sent showed none of these models
  (the page fell back to its defaults); AA pages render with JavaScript (WebFetch sees no numbers): use a browser.

## Parts (each with a check; builders RUN_KIND=py, then cross-review, then Opus)
a. Evidence table (agy): every model we may use for free: Cloudflare Workers AI catalog, opencode free list,
   OpenRouter :free list. Per model: route id, Artificial Analysis Intelligence / Coding / Agentic index, output speed,
   context, free-tier limits, each with its URL and date read (rendered page); "not on AA" when absent. Opus
   spot-checks 3 numbers in the built-in browser.
b. Routing table in models.md (Opus decides): task class -> model (Godot code, Python tools, docs, review lens,
   research, bulk text: summaries, classification, extraction, translation of notes) with calibrated yes/no; weak fast
   models get only checked bulk work.
c. Calibration (D11) of the 2 best uncalibrated candidates (GLM-5.3 on Cloudflare first) on the gold sets in
   calibration-2026-10.md (hook diff 5 bugs; parser 2 bugs); scores into models.md.
d. Reliability: why the opencode free run hung (log, opencode version, rate limits); fix or reroute oc text runs;
   cross_review.sh: one retry or a second reviewer on INVALID; tests for each fix.
e. Cross-review keep or drop: count USAGE "cross-review hits"; decide at 5 measured runs (rule: < 1 real bug a run).
f. Licences: a builder opens each repo or asset page in docs/research/opensource-candidates.md, reads its LICENSE,
   confirms the repo exists; mark each row verified or remove it; Opus spot-checks 3.
g. Diagram v2 in docs/HOW_WE_WORK.md: the whole system for Feras: father and child chats, the builder pipeline inside
   (slots -> build -> check -> fix passes -> gate -> cross-review -> Opus gate -> merge -> main -> sync), the eye
   gate, his touch points (decisions, spend ok, play, notes) and where reports land (BRIEFING, calendar, Open
   points); renders on GitHub (check the page); send him the link.

## Done when
check.sh passes; models.md has the evidence table link, the routing table and calibration scores; d and f fixed or
Open points with owners; diagram v2 on main; /handoff with every item tagged done | in progress | planned (when) |
not planned | waiting on Feras.
