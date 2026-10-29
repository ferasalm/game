# Chat brief: process completion (HANDOFF row 16; Feras 2026-10-29 "Process first, M1 Sat")
For a fresh Opus chat (Ops, high). Everything agreed in the row 12 chat (local_ffae0e47) is listed here: read this
brief and docs/audits/2026-10-29-process-review.md (sections 1-7), nothing from that chat. Motto COOKE: Clarity,
Organization, Optimization, Kaizen, Efficiency. Claude has a fiduciary duty to Feras's time, money and limits.

## Why
Feras wants the process finished and synced before M1, so later chats cost less, nothing agreed slips, and he always
sees what was done, what was not, what was checked and what comes next. Measured cost driver: model calls x context
(row 12 chat: 94 calls x ~150k cached reads); the ~90k fixed load per call is ~63k tool definitions, ~7k docs.

## Do first (in this order)
1. Calendar (feras.almekhlaf@gmail.com, all-day "Your moves today:" events, his GMT+3): Thu 10-29 and Fri 10-30 =
   this brief; Sat 10-31 = 16:00 reset, then the M1 brief (row 3) and agy builds M1 overnight; Sun 11-01 = M1 review
   + eye gate, Roya bake; Mon 11-02 = Feras plays M1 (sync_main.sh first, now also run by chats). Edit the existing
   events (Thu, Fri, Sat, Sun ids in the 10-28 set), add Mon.
2. HANDOFF: an "## Open points" section (each line: point | owner | since), max 10 lines; doc_check fails on a missing
   section; every /handoff closes or carries each line (handoff skill step). Seed it with the Feras items below.

## What to build (each with a test or a check; Opus writes hooks and CLAUDE.md, builders the rest)
1. CLAUDE.md (stay <= 80 lines: move detail to WORKFLOW, keep pointers): the COOKE motto + fiduciary duty; the cache
   rule (follow-ups and corrections up to ~10 tool calls stay in the chat; a new multi-step task opens a fresh chat);
   batch = parallel tool calls in one message (the worktree guard refuses compound shell: never chain git/gh/bash);
   advisor once before the approach on tasks over a few steps, the closing call only when the change is untested or
   risky; the D10 sync exception; the Open points rule; the 5-part report (Done | Still open | When | How | Your move
   vs mine) + "what was checked / not checked". Then run claude-md-improver (claude-md-management plugin) once as an
   audit and apply only what fits the caps.
2. Heredoc hook (Opus): PreToolUse Bash, via tools/hooks/run.sh; blocks `python - <<` / `python3 - <<` heredocs whose
   body holds a backslash escape, telling Claude to use Write/Edit (lesson broken again 10-29: 4 calls lost);
   test_hook_* with one bad and one good case; the LESSONS line becomes "enforced by" + archive.
3. Token hook (Opus): also warn when cumulative cache reads in the transcript pass ~10M tokens (calls x context),
   not only at 200k/250k context; test.
4. handoff skill: step 6 adds `bash tools/sync_main.sh` in C:\dev\game when `git -C C:/dev/game status --porcelain`
   is empty (D10 exception); step 7 closes Open points; the report says what was checked and what was not.
5. "How we work" page: a published Artifact (Artifact quickstart first) with one clear diagram of the whole loop
   (Feras -> Opus chat -> brief -> builder pipeline -> gate -> cross-review -> Opus gate -> eye gate -> main ->
   handoff/calendar), the roles table, the cost rules and the week; its link in HANDOFF "Parked and context"; it is
   updated whenever WORKFLOW Protocols change.
6. Builder rows (briefs from TEMPLATE, RUN_KIND=py, agy; cross-reviewed by nemotron :free, then Opus):
   a. tools/doc_dupes.py: Cloudflare Workers AI embeddings (bge, via the CLOUDFLARE_ACCOUNT_ID + opencode auth the cf
      builder already uses; Claude never handles the token) list near-duplicate or superseded lines across CLAUDE.md,
      DECISIONS, LESSONS, WORKFLOW, skills; a test with a stubbed embedding call; free tier only.
   b. Model cards in the builders skill: per model (agy Gemini 3.8 Flash, DeepSeek V4.1 Flash, nemotron :free, GLM
      5.3 Flash, others on OpenRouter :free) = Artificial Analysis index numbers fetched by an oc builder (D18:
      research by builders; numbers marked unverified) + our calibration scores (hook diff 5 bugs; parser 2 bugs) +
      failure modes; a new model is used only after a calibration run (D11).
7. Report fixes in docs/audits/2026-10-29-process-review.md: section 1 point 3 overstated (cached reads cost ~1/10;
   the break-even is ~10-15 calls), the never-used connector list, the advisor facts (caller Opus 5.5 high; the
   advisor's model and effort are not visible).

## Feras's own moves (Open points seed)
- Switch off in the app (Settings -> Connectors): Gmail, Google Drive, Google Docs, the duplicate Rodin connector,
  Cloudflare Bindings (decided 10-29).
- Add the allow rules to C:\Users\AUC\.claude\settings.json "permissions.allow": Bash(bash tools/cross_review.sh:*),
  Bash(bash tools/build_pipeline.sh:*), Bash(bash tools/check.sh:*), Bash(bash tools/sync_main.sh:*).
- Art homework, Bilqis portraits call, VISION OK (HANDOFF Waiting on Feras).

## Limits
Weekly limit ~85% used until Sat 16:00 (GMT+3): builders write, Opus briefs and gates; parallel tool calls; no
advisor closing call on doc edits. Never edit settings.json from a chat (refused as self-modification).

## Done when
check.sh passes (Godot skipped only if no Godot file changed); every item above is on main or is an Open point with
an owner; the calendar shows the new week; the "How we work" link is in HANDOFF; /handoff with the 5-part report.
