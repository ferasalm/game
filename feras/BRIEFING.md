# Briefing for Feras (one file for you: newest report first, the last 5 kept; every chat updates it at /handoff)
Open it from any chat: `feras/BRIEFING.md` (C:\dev\game\feras\BRIEFING.md after a sync). Claude's own queue is
HANDOFF.md; this file is your view of it. Each report: Done | Still open | When | How | Your move vs mine | Checked.

## 2026-10-30 (Fri, early): your row 17 follow-ups (Opus 5.5 high), closed
**Done (on main):**
- Bandwidth: git already sends only changes (a sync is KBs; CI runs on GitHub, not your line). The 109 MB is old
  binaries uploaded once. New check: no tracked file > 10 MB, or > 2 MB outside assets/. The bigger cost is AI
  traffic (this chat sent ~60 MB of context), so short fresh chats matter most.
- Cloudflare: no $ cap (spend still logged). DeepSeek 1017 at max effort for reviews and builds, opencode's hidden
  output cap raised to 384k, DeepSeek's full output (that 32k cap broke "high"). Max vs low on the same review: same key bug, less noise, 443 s, ~$0.08.
- Nemotron: backup lens only; Cloudflare DeepSeek now cross-reviews agy runs. agy stays high: proven it's
  Gemini 3.8 Flash's top level (agy refuses max). Cache hook: informs at 25M, never asks for an early wrap-up.
- Kaizen coach session: its commit (ef1b284) is on main; its local-only changes (settings.local.json, memory, the
  usage hook) don't touch git, so no conflict. Its "persona check exits 0 on drift" finding was a misread: that FAIL
  line is the test's own planted case (real drift check passes); now silenced so it can't mislead again.
**Still open:** row 18 calibrations (GLM-5.3-flash on Cloudflare, Clef-flash, Jev), planned Sat 10-31 16:00, then your routing
OK (waiting on Feras after it); the first DeepSeek build at max effort is unwatched until then (planned with row 4); the
coach-cleanup worktree is removed after the kaizen CLI session ends (planned, next chat).
High effort was also measured: a valid review but 900 s, slower than max.
**Later the same night (Feras):** routing OK waits for all of row 18 (waiting on Feras then); M1 moves after the system pass (planned: row 18 Sat, M1 brief Sun at the earliest); opencode v2 upgrade planned in row 18 with a rollback; coach branch deleted (done), old worktree folders checked and cleaned next chat (planned).
**Next chat prompt** (Opus high, after Sat 16:00): "Continue ferasalm/game on main. Read HANDOFF.md. Take the top queue row for your lane; /handoff."
**Checked:** tests (pipeline 12, cross-review 6, token hook 13, file sizes 2, personas 4) and check.sh --no-godot, read.

## 2026-10-30 (Thu night): row 17 models, builders, licences, diagram (Opus 5.5 high), closed
**Done (on main):**
- DeepSeek 1017 fixed (done). Access works on every route. Your long builds never hit the bug because each agent step
  is short. A one-shot review is one long answer: Cloudflare's default "high" thinking filled the whole 32k output
  budget, hidden, with no text (3 of 3 replays). `reasoning_effort: low` fixed it: a valid review in 195 s, ~$0.04.
- The opencode free "hang" (done): opencode's free usage limit is spent ("Free usage limit reached"), and opencode
  hides it (no text, exit 0). Runs now log it and stop at once as "NOWORK quota: rerun on cf", with a test.
- GLM-5.3 (Cloudflare) calibrated (done): same score as nemotron and DeepSeek-low (1 of 2 planted bugs), 3x slower.
  GLM-5.3-flash: Cloudflare answers; opencode free timed out on the spent quota (calibration planned with row 18).
- Your AI-search list (done, partly checked): Clef-flash is real (9B vision yes/no model, ~free). Jev, Clairic, bge-m3:
  agy says real, unchecked. The AA scores are not trustworthy: AA shows DeepSeek V4.1 Flash as "Unknown"; agy wrote 32.
- Licences (done): 13 of 15 rows verified; 2 dead links removed (GDQuest 2D RPG, Quaternius cyberpunk). 3 of 3 spot-checks right.
- Diagram v2 (done): the whole system on one page, your moves in orange:
  https://github.com/ferasalm/game/blob/main/docs/HOW_WE_WORK.md
**Still open:** model routing proposal (waiting on Feras); cross-review keep/drop (in progress: 1 of 5 runs measured);
row 18 Clef + Jev calibration (planned after your OK).
**When:** your OK any day; row 3 M1 brief Sat 10-31 after 16:00 (unchanged).
**How:** row 18 = Ops, builder agy. **Your move:** read the Routing table in .claude/skills/builders/models.md and OK or
change it; subscribing to OpenCode Go is not needed (Cloudflare covers it for cents). **Mine:** M1 brief Saturday.
**Checked:** both test suites (build pipeline 12, cross-review 5) and check.sh --no-godot run and read; the diagram renders
on GitHub; 3 AA + 3 licence facts re-read. Not run: the Godot checks (only docs and Python tools changed; 1.5 GB free memory).
My mistake (fixed): I edited a pipeline script while two runs were using it, so both crashed; I re-gated them, nothing lost.

## 2026-10-29 (Thu, late): row 16 process completion (Opus 5.5 high), closed
**Done (on main):**
- Calendar Thu-Mon matches the plan (new Mon 11-02 "play M1"). HANDOFF "Waiting on Feras" is now "Open points"
  (point | owner | since, max 10; a check fails without it; every /handoff closes or carries each).
- Hooks: python heredocs with backslashes are blocked; the token hook also warns at 10M cumulative cache reads (it
  fired live in this chat). New cache waker tools/wait_run.sh: wakes a chat waiting on a builder at 50 min so the
  1-hour cache never expires; overnight runs hand off at launch.
- docs/HOW_WE_WORK.md (loop diagram, roles, cost rules), model cards (.claude/skills/builders/models.md, numbers
  unverified), open-source candidates (docs/research/opensource-candidates.md, licences to verify before import).
- Doc audit by agy: 5 fixes applied (CLAUDE.md dupes, a stale WORKFLOW review step, a stale decision line).
- VISION M1: combat feel first. Your Drive connector decision logged.
- Late (done): hand-off is a band (200-300k, finish the unit); father/child chats (WORKFLOW Protocols; the father
  syncs and merges; wait_run.sh with no task keeps it awake); every item I name carries a status; HOW_WE_WORK says
  who syncs and where reports land; this report is now written last (handoff skill).
**Still open:** planned Fri 10-30, row 17: model evidence + routing table (the AA numbers in models.md are
unverified and suspect), calibration, why the opencode free run hung, cross-review retry, licence check, diagram v2.
Waiting on you: VISION OK, Bilqis portraits, art homework. DeepSeek is not retired (builder yes, reviewer no).
**When / How:** Fri 10-30: row 17 (Ops, Opus high father + agy). Sat 10-31 after 16:00: row 3 M1 brief.
**Your move vs mine:** yours = start the row 17 chat Fri, art homework, the two calls; mine = row 17, then M1.
**Checked:** all new tests; check.sh full run (582 passed) at the docs merge, again at the audit merge; the hooks live.
**Not checked:** the open-source licences and benchmark numbers (marked unverified); CI is checked after the push.

## 2026-10-29 (Thu): row 12 chat (Opus 5.5 high), closed
**Done (on main, CI green; your checkout synced):**
- Cross-review: agy reviews DeepSeek/oc runs (3/5 known bugs); nemotron :free reviews agy runs (1/2); DeepSeek off
  as a reviewer (0 findings in 3 runs). The runner is tools/cross_review.sh; every finding is vetted by Opus.
- The session hook prints the top queue row; the review gate's frame-name bug fixed; process review written
  (docs/audits/2026-10-29-process-review.md); ideas inbox docs/ideas.md; the handoff report format.
- CLAUDE.md: COOKE, fiduciary duty, top-down, solid + flexible foundations, the cache rule (<= ~10 calls stay),
  parallel tool calls, the advisor only with your OK.
- Decisions logged: process first, M1 Saturday; chats sync C:\dev\game at handoff; connectors off; DeepSeek and
  other free models (Cloudflare-hosted, opencode free, OpenRouter :free) free to use, Claude assigns them, agy
  researches them.

**Still open (row 16, docs/briefs/process-completion.md):** calendar re-plan; Open points list in HANDOFF; the
heredoc hook; the token hook's cumulative warning (proposed, NOT built); the "How we work" page with the diagram;
builder jobs: doc_dupes (Cloudflare embeddings), model cards (agy researches Artificial Analysis), open-source
research (licences, art bible); combat-first M1 framing; CLAUDE.md audit with the plugin.

**When:** row 16 Thu-Fri; Sat 16:00 limit reset -> M1 brief (combat feel first); Sun M1 review; Mon you play.

**Your moves:** (1) add the 4 allow rules to C:\Users\AUC\.claude\settings.json now; (2) after this chat ends,
switch off Gmail, Google Drive, Google Docs, the duplicate Rodin connector, Cloudflare Bindings; (3) start a fresh
chat with: "Take HANDOFF row 16: docs/briefs/process-completion.md." **Mine:** everything in row 16.

**Checked:** check.sh (582 tests, earlier today; later changes docs/tools only: check.sh --no-godot passed),
CI green on the pushes I watched. **Not checked:** the game was not run; CI on the last two pushes.
