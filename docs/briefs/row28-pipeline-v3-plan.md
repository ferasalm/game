# Row 28: low-cost pipeline v3 after Cloudflare (plan input, Feras 2026-11-04; planned in a fresh Opus high chat)
Status: input only. The planning chat reads this, verifies every "check" item live, asks Feras the open questions
(AskUserQuestion, recommended first), then writes part briefs. Home of the workflow: .claude/skills/low-cost-pipeline/.

## What Feras decided or reported (11-04, verbatim intent)
1. Cloudflare retired (waiver refused; tokens and env vars deleted; the plan lapses unpaid). OpenCode Go: NOT now.
2. OpenRouter topped up: $13 lifetime, $8 balance, so :free models get 1000 requests/day (20/min). Use the free
   requests FIRST. The free-models router may join after a smoke test (decisions-log 11-04).
3. NVIDIA NIM advises its endpoints for prototyping, not development: the nv lane on NIM is a stopgap, not the plan.
4. (Superseded 11-04 by "What-we-have pipeline" below: DeepSeek debugs and owns accuracy-critical mechanics; agy builds most.) DeepSeek V4.1 Flash 1017 stays the main writer, on OpenRouter: builds at reasoning effort HIGH (not max); max only
   where it is sensitive (test writing). Pick providers by 1) reliability 2) price (OpenRouter provider routing).
5. Other models that do the work as well may replace DeepSeek: Feras researches candidates, consults Claude, then we
   test them (calibration vs a gold task, D11).
6. agy and Haiku take a larger role to make up for less DeepSeek.
7. Price cliffs to design around: Claude Sonnet doubles and Haiku x5 past 200k context; GPT 6 Luna rises past 250k;
   DeepSeek costs double in peak hours (Feras read: Mon-Fri 04:00-07:00 and 09:00-13:00 GMT+3) -> DeepSeek runs only
   off-peak.
8. Balances (memory provider-credits): Cerebras $4.85 prepaid (capped fallback hop, kept), OpenRouter $8, Runware $4;
   agy free.

## What-we-have pipeline (Feras 11-04, second chat; decisions-log 11-04). Rename and re-route, not a rebuild
Evidence: Feras's zero-shot game playtests on OpenRouter (n = a few games per model; Design Arena Godot benchmark for Gemini).
| Role | Worker | Note |
|---|---|---|
| Head: plan, brief, write red tests, review, merge | Opus or Sonnet high | may consult agy/DS/GLM for test ideas in isolated one-shot chats; the implementing builder never sees them |
| Most building (Godot code, scenes, tools) | agy gemini-3.8-flash | free, plenty; reviewed by DeepSeek or Claude (other family) |
| Level design, technical art, dialogue, narrative | GLM-5.3-flash | designs and JSON data, not core code; review-canon gate before merge |
| Debugging, balancing, optimization, controls/physics/combat logic | DeepSeek V4.1 Flash 1017 | accuracy over creativity; VISION: combat feel wins ties |
| Routine reads | agy gemini-3.8-flash-low, then Haiku (medium default, xhigh max) | |
| Consultant, named decision only | GLM-5.3-Max or GPT-6.1-Sol | Feras's OK each time; GLM-5.3 (full) not used |
Lanes: free first (opencode free routes, OpenRouter :free, NVIDIA NIM only when time has zero priority = overnight queue);
paid OpenRouter (GLM-5.3-flash, DeepSeek) on its own key with a $3/month provider-side hard cap AND Feras's OK per run.
New parts: g. agency-agents skills reset to stock + ONE shared project overlay pasted into builder prompts (tools/import_agents.py;
copies in .claude/skills and .agents/skills). h. GLM-5.3-flash content lane (who calls it, output format = docs/JSON,
review-canon). i. Isolated test-idea consults (a script that sends the part spec without builder context, returns ideas only).
j. Overnight NIM queue. Check live first: GLM-5.3-flash free routes (NIM, OpenRouter :free) and its paid price; agy flash-low slug.
Haiku: medium for reads, xhigh for anything that writes, reviews or debugs (max not used).
Part g source: each repo copy (.claude/skills, .agents/skills, plugins/studio/agents) goes back to its EARLIEST git version
(`git log --diff-filter=A --format=%h -- <file>`), grep-verified free of project text (Neon, Sana'a, Feras, Godot 4.7, CANON);
~/.claude/agents are stock already (grep 11-04: 0 hits). The overlay is one new file under .agents/ (name it in the brief; <= 40 lines:
CANON/VISION pointers, code.md pointer, "the brief wins") that build_pipeline pastes; tools/import_agents.py NOTE shrinks to point at it.
Groq: dropped (does not work for Feras, 11-04); never in the chain.

## AA data read 11-04 in Chrome (Intelligence Index v5.0.1 | cost per index task | output tokens/s)
| Model (effort) | Index | $/task | tok/s |
|---|---|---|---|
| Sonnet 5.5 max / xhigh / high / medium / low | 55 / 50 / 42 / 31 / 26 | 10.02 / 4.09 / 1.64 / 0.78 / 0.51 | 139 / 107 / 103 / 97 / 97 |
| Haiku 5.5 max / xhigh / high / medium / low | 36 / 35 / 30 / 25 / 19 | 0.41 / 0.25 / 0.16 / 0.09 / 0.04 | 236 / 181 / 177 / 168 / 160 |
| DeepSeek V4.1 Flash 1017 max / high / non-reasoning | 33 / 29 / 19 | 0.60 / 0.46 / 0.43 | 165 / 201 / 172 |
| Gemini 3.8 Flash high / medium / low | 31 / 30 / 23 | 7.77 / 6.26 / n/a | 130 / n/a / n/a |
| GLM-5.3-Flash | 28 | 0.58 | 71 |
All 1M context. Reading: the index is generic (office, terminal, code, knowledge); Feras's game playtests outrank it for
creative and Godot roles. Gemini is costly per task on the API but free through agy, so it must never fall back to paid
Gemini. DeepSeek max is +4 for +30% cost: use max for debugging and mechanics within the $3 cap. Personality chart: read
it on the page (no table; values only on hover).

## Found in the 11-04 chat (facts, checked)
- BLOCKER: the pipeline's opencode data dir (oc-v2, lib.sh oc_run, --standalone) holds only the OpenRouter key; NVIDIA,
  Cerebras, Groq, Google keys live in opencode's default dir. The 11-04 smoke tests went through the background service
  (default dir), so they passed while a real nv build would fail to log in, and an auth error is not in NV_FALLBACK_RE.
  Fix: Feras logs each needed provider into oc-v2 (PowerShell: `$env:XDG_DATA_HOME="$HOME\.local\share\oc-v2";
  & "$HOME\.local\opt\opencode-2.2.2\opencode.exe" auth login --standalone`; WITHOUT --standalone the login goes to the
  background service, which ignores XDG_DATA_HOME and writes the default dir: Feras's 11-04 logins landed there as
  duplicates "Nvidia 2" etc., and that service, started before the Cloudflare vars were deleted, still lists them as
  "environment". Fix used 11-04: logout the old duplicates, `auth export <provider> --standalone | auth import --standalone`
  into oc-v2, restart the service), and nv_build.sh gets a preflight: the model's provider
  must appear in `auth list --standalone` for oc-v2, else REFUSED with the login line (plus a test). Providers to
  log in: NVIDIA, Cerebras, Google (Groq dropped 11-04). DONE 11-04: oc-v2 `auth list --standalone` shows Cerebras 2,
  Google 2, Nvidia 2, OpenRouter twice ("OpenRouter" and "API key": smoke-test which one is active); service restarted,
  no Cloudflare lines. Next chat: one live smoke call per provider through oc-v2 before any brief relies on it. The next chat checks `auth list` first; a missing provider
  -> that lane is skipped, not blocked.
- OpenRouter has no :free DeepSeek V4.1 Flash 1017. Paid: $0.15 in / $0.60 out per M, cache read $0.003, 1M context,
  393k output (opencode models.json cache 11-04; recheck live).
- Zen free routes are spent ("Free usage limit reached"); the chain skips them in ~2 s.
- NIM is slow: DeepSeek 439 s, GLM 218 s on a toy write-run-commit task (QUIET_SEC 300 risk).

## Check live before deciding (never from memory or this file)
- DeepSeek peak/off-peak hours and whether they apply through OpenRouter providers (DeepSeek's own API page vs each
  OpenRouter provider's price); convert to GMT+3; Feras's figure above is what he read, not verified.
- Context-tier prices: Claude Sonnet/Haiku past 200k (claude-api skill), GPT 6 Luna past 250k, DeepSeek 1017 tiers.
- OpenRouter provider list, uptime and price for deepseek/deepseek-v4.1-flash-1017 (list-model-endpoints,
  get-endpoint-uptime-history); whether `reasoning.effort: high` is honoured per provider.
- Which :free models on OpenRouter can build or review (calibrated lens list, models.md); the free router's slug.

## Parts to brief (draft; the planning chat orders and sizes them)
a. Lane: an `or` (OpenRouter) build lane or NV_CHAIN reordered: OpenRouter :free first, then DeepSeek 1017 paid at high
   (provider order by reliability then price, a per-key $ limit on OpenRouter as the hard cap), NIM only for
   prototyping. Effort per task class (high builds, max test writing) in opencode.json variants + routing.md.
b. Off-peak gate: a script (with a test) that refuses or queues a paid DeepSeek run in peak hours (GMT+3 table in
   builders.conf), and kaizen_report shows peak vs off-peak spend.
c. Context guard: every Claude subagent and paid model call stays under its price cliff (200k Claude, 250k Luna):
   briefs and foremen keep packets small; a check warns on a packet over the cliff.
d. Credentials preflight in nv_build.sh (above) + test; free_providers.txt rules for the opencode-go provider only if Feras
   subscribes later.
e. Routing v3: agy and Haiku take more (which classes), DeepSeek fewer and only off-peak; update routing.md, models.md,
   builders skill, WORKFLOW, DECISIONS; runs.csv records provider, effort, peak flag and $.
f. Candidate models (after Feras's research): one calibration task each, scored vs Haiku/agy (D11).

## Acceptance
check.sh green; CI green on main; one real build per lane reaches PASS through the pipeline (not the background
service); a peak-hour paid DeepSeek launch is refused by the gate in a test; Feras OKs the routing table.

## Carried from row 26 (its writer trial agy vs cf is moot; row and Open point closed 11-04)
- After 5 more pipeline runs read `python tools/kaizen_report.py` idle minutes, then tune QUIET_SEC (NIM/DeepSeek slowness).
- P6 (seeded-defect cross-review) on a Godot run; agy cost is unmetered; A/B and model personalities are n=1.
- OpenRouter free-models router as the last chain hop (smoke-test first, its exact slug in free_providers.txt).

## Status 11-04 night (chat 2, Opus high): live checks done, briefs written, part g built
Briefs: docs/briefs/row28-{a-lanes,b-peak-gate,c-cliff-guard,d-preflight,e-meter,f-calibration,h-glm-content,i-test-consult,j-night-queue}.md.
Build order: d (Opus writes), c, b (agy/nv, red tests from the head), a (its paid ids stay unused until Feras's cap), e, i, h, j, f.
Corrections to this file (checked live 11-04, they win): DeepSeek peak (04-07 and 09-13 GMT+3, Mon-Fri, x2) is DeepSeek's OWN endpoint
only; OpenRouter has 45 providers (many cheaper than DeepSeek off-peak at any hour), so paid DeepSeek goes through OpenRouter with
`provider.ignore: DeepSeek` and fp8 or better; a direct DeepSeek call passes a peak gate (part b). Cliffs: Haiku 5.5 x5 past 100k (not 200k),
GPT-6 Luna x2 past 272k, Sonnet 5.5 none. GLM-5.3-flash has no OpenRouter :free route (paid $0.03-0.15 in per M). Free router slug: `openrouter/free`.
Feras decided (decisions-log 11-04): route around peak on OpenRouter + gate for non-OpenRouter DeepSeek; split UI copies (stock for the two
.claude/skills UI personas, the studio agent ui-finish-gate-reviewer and market-player stay project-written); ONE OpenRouter key with a $3 monthly limit.
Smoke calls through oc-v2 (11-04 night): Cerebras OK; NVIDIA deepseek and glm timed out (ECONNRESET, NIM flaky, login fine); OpenRouter
"User not found" (the key in oc-v2 is dead: Feras must log in again with --standalone and set the $3 limit); Google not smoke-tested (no chain model uses it).
Part g shipped: 14 persona sources in .agents/skills are stock agency text (+ one NOTE line), .claude/skills copies are generated from them
(tools/sync_personas.py), .agents/project-overlay.md (pasted after the pasted skills by build_pipeline and after the reviewer skill by
cross_review), project rules that lived only in the old tailored personas kept in docs/design/persona-rules.md. test_personas.py now pins the
reverse of the 10-28 rule (no project words in a persona, one overlay). Generic craft advice from the old tailored copies is dropped (the stock text covers it); the old copies stay in git history (commit before row 28 part g).

## Status 11-05 (Dia-review chat, Opus xhigh; docs/audits/2026-11-05-dia-review.md): this section wins over the ones above
Part d merged: the redo on worktree-row28-next was reviewed by Opus (the preflight parses the real `auth list --standalone`
columns) and landed on main with this chat's work. Feras 11-05: the order stays c, b, a, e, then i, h, j, f, all before M1.
Done here, so no part redoes it: reviewer map (agy and GLM runs -> DeepSeek max; DeepSeek runs -> Claude studio:review-code,
Haiku xhigh; cross_review.sh writes the hand-off into the review file); one fallback chain per family (NV_CHAIN DeepSeek,
GLM_CHAIN GLM-5.3-flash; nv_build.sh takes deepseek|glm; Cerebras qwen and Nemotron left the build chain, Cerebras and
Groq left free_providers.txt); routing.md rewritten to the 11-04 roles (the head writes red tests); models.md trimmed
(Laguna-S, Inkling, GLM-5.3 full, qwen in one NOT USED line) plus prices and cliffs; opencode.json default = NV_MODEL
(DeepSeek on NIM); review agents at Haiku xhigh; soft 300k context line (hook + docs); tools/test_routing_docs.py.
Changed briefs: a (paid ids carry rates; the family's paid id is the last hop only with PAID_OK=1; no Cerebras or
OpenRouter :free hop; adds nv_build.sh), e renamed row28-e-meter (per-model rates for every spend line, runs.csv columns;
the docs half is done). b stays as briefed, though paid DeepSeek already skips DeepSeek's peak endpoint (it guards a
direct call only). f gains qwen-3.8-27b as a candidate. Carried P6 is now the reviewer rollback test: seed a defect into
the first Godot agy run; DeepSeek max missing it twice in a row brings GLM back as a second lens.
