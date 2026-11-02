# WORKFLOW: how the studio works (protocols, routing, limits, routes)

Why the rules in CLAUDE.md exist. Not loaded at session start. Built 2026-10-19 from reem-bot and feras-career playbooks plus repo methods. Drop a rule when its why stops being true.

## Start here: one unit of work (Feras 2026-10-28: the lean process; departments are labels)
Feras -> the **father** chat (Opus high or the Sonnet high Lead; xhigh only for planning) -> the worker from the step 3 table -> gates ->
Feras plays -> his notes become queue rows. Speed, never needless spend: each task goes to the cheapest worker that
does it well; Opus or the Lead reviews what another model made, and Opus owns whatever reaches Feras. tools/doc_check.py makes every queue
row name a Dept from the Routing table and a lane.
1. **Look** (free): `bash tools/status.sh`: builders, branches not on main, worktrees, the queue, Feras's list.
2. **Pick**: the top HANDOFF queue row. Its Dept is a label: the Routing table row says which skills and persona to
   load and who reviews.
3. **Who does it**: `low-cost-pipeline` skill (`.claude/skills/low-cost-pipeline/routing.md`).

4. **Brief**: docs/briefs/TEMPLATE.md; child brief recipes in `builders` skill (`.claude/skills/builders/SKILL.md`, Prompt recipes).
5. **The worker orchestrates** (a child chat): routes by the Routing table's lane; build flow in the `low-cost-pipeline` skill (`.claude/skills/low-cost-pipeline/SKILL.md`, Flow of one part); visual work passes players-eye-gate, review-player, review-feras and `python tools/hooks/review_stamp.py`. Nested agents work (10-28) but each costs a fresh start.
6. **The father** reads the report, checks it with `bash tools/status.sh` (branch on main, row updated), picks next.
   Open children are the queue rows whose Status says "child open"; status.sh lists their branches and worktrees.
7. **Evolve**: each chat upgrades one tool, check, skill or doc; every 5 chats ops-review reads /session-report
   and review-cost; a lesson becomes a check or is archived after 30 days (D9). claude-md-management runs inside
   /handoff under doc_check caps.
Emergency mode (emergency-efficiency skill, the 5-hour window past 50%) suspends child chats: one director chat,
builders and Haiku readers only, until the window resets.

**Department brief** (fill every line; a child chat gets it as its first message, a subagent as its prompt):
```
Department: <Id> (a label: Routing table). Queue row: <#>. Model: Opus <effort> | Sonnet high.
Skills: <names; a skill the chat does not list yet: Read .claude/skills/<name>/SKILL.md>. Persona: <.agents/skills name>
Goal: <one line; player-visible where it can be>
Context: <the decisions, files and CANON lines it needs; no chat history>
Lane plan: <pieces for agy / cf / oc, Haiku readers, reviewers; what the chat does itself>
May edit: <paths>. Do NOT edit: <paths other chats own right now>. Commit and merge: <yes | no, the father does>
Done when: <check.sh passes; the gate or render; merged to main; queue row updated>
Report: 15 lines or fewer: what changed (commits), runs launched, what failed, questions for Feras.
```

## The budget
Feras is on Claude Pro ($20/month): a 5-hour usage window plus a weekly cap, shared with his other projects. Money is
fixed; throughput is the limit. Every turn re-sends the whole chat (cheap when cached, still counted), so the costs
are: what loads at start, how long a chat runs, what gets read, and output.

## Protocols
docs/HOW_WE_WORK.md draws this loop for Feras: a change to these Protocols updates it in the same commit.
- **Father and children (Feras 10-29):** Feras talks to the father chat. It starts a child chat only for an
  independent part of ~15+ calls, at most 2 working at once, one writer per set of files; while a child works it keeps
  itself warm with `bash tools/wait_run.sh` (no task: a 50-min timer) in the background. Children report at
  milestones; the father reviews, merges each child branch into its own, runs check.sh, merges to main, runs
  sync_main.sh in C:\dev\game and the final /handoff (report in feras/BRIEFING.md).
- **Start:** the hook prints the sync for this worktree; then the HANDOFF line; then the status line's usage (or Feras's /usage).
- **Brief:** docs/briefs/TEMPLATE.md (<= 80 lines, with a Do NOT edit list).
- **Build:** slots (tools/slots.sh), then the pipeline (tools/build_pipeline.sh).
- **Review (tiered, Feras 10-28: Opus never reads needlessly, and signs off on whatever reaches Feras):**
  1. Gates first: check.sh, build_gate (.result first line). FAIL, NOWORK or BREACH goes back unread.
     PASS: cross-review (row 12 A, 10-29): `bash tools/cross_review.sh <run> <brief> <base>` in the background. On for
     oc/* runs (agy reviews, free, ~11 min, 3/5 on calibration); gemini/* runs: Cloudflare DeepSeek 1017 at max effort
     (Feras 10-30; nemotron :free only as the backup lens after cf fails twice). USAGE logs real hits a run: under 1 on
     average over 5 runs -> drop the step. Opus vets the table
     (.check/reviews/<run>-cross.md) in step 3; real findings go to the builder as its fix pass, then the gate again;
     fail-open/closed findings stay Opus's (agy argued the wrong side on calibration).
  2. Big diffs (over ~300 lines or ~10 files): a Haiku low pass (or a free lens, Readers) lists the misses against
     the brief's Checklist; small diffs skip to 3.
  3. Opus reads that list, the WARN lines and the risky hunks only: logic/, saves, hooks, settings.json, anything no
     test reaches; review-code on the whole diff only when the tier-2 list is not clean.
  4. Anything that reaches Feras: the eye gate (tools/eye_gate.sh), review-player + review-feras, then
     `python tools/hooks/review_stamp.py <file>`; the review_gate hook blocks a send-to-Feras tool (a file send, an Artifact) on an
     unstamped render (tools/hooks/review_gate.py).
- **Handoff:** when the chat's task is done or at ~85% of the 5-hour window; context size never triggers it (CLAUDE.md). It records one improvement made and one proposed.
- **ops-review:** every 5 sessions, or at 50% of the window: `python tools/session_stats.py` (slips, guards, calls per turn),
  then `/kaizen:coach` (reads ~/.claude/coach-usage-log.jsonl from the track_usage hook; its score, accepted and declined items go to .claude/coach-history.md, committed, so the next run
  trends and never re-asks); its USAGE row says "ops-review done" (the session-start hook counts rows since it and
  prints OPS-REVIEW DUE at 5); usage trend and start cost; promote lessons to checks;
  condense the notes on schedule; dispatch research from the department queues and read the digests (Research
  protocol); archive idle sessions.
- **Lesson lifecycle:** a lesson is added, then promoted to a test, tool, hook or skill line, or archived after 30 days
  unused. A rule the agent keeps breaking becomes a check.

## Routing (one table; departments are labels, Feras 10-28 option B)
A department is a label, not an agent: the HANDOFF queue's Dept column names a Dept below, and that row says which
skills and persona the worker loads, its lane and its reviewer. Every brief names its persona; our rules (CLAUDE.md,
.claude/rules/code.md, CANON) outrank persona text. Lanes: agy, cf, oc = the builders (who takes what: low-cost-pipeline skill, routing.md; run caps: Limits); chat =
Opus for plan, taste, MCP, review. No department chat stays open between tasks; its lessons and research queue live in
its skill folder. tools/doc_check.py fails on an unknown Dept, a persona with no .agents/skills/<name>/SKILL.md, a
reviewer with no plugins/studio/agents/<name>.md, and any plugins/studio/agents/dept-*.md (retired to ~/.claude/archive, D7).

| Request | Dept | Skills | Persona | Lane | Reviewer |
|---|---|---|---|---|---|
| the queue, picks, briefs, reading reports (Feras directs) | Producer | builders; tools/status.sh | - | chat (plan) | review-feras |
| process, tools, hooks, checks, merging PASS runs | Ops | builders, ops-review; emergency-efficiency when the window is tight | - | builder (agy, cf) + chat (review) | review-code + review-cost |
| combat and systems design: specs, balance | Gameplay | builders + a spec in docs/design/ | game-designer | chat (plan) | review-feras |
| Godot gameplay code and tests | Gameplay | builders | godot-gameplay-scripter | builder (agy, cf) | review-code |
| levels, encounters, the roof layout | Gameplay | builders; docs/design/systems-map.md | level-designer | builder (agy) + chat (review) | review-code + review-player |
| shaders, VFX, rain, neon light | Art | builders; docs/design/art-bible.md | godot-shader-developer | builder (agy) | review-code + review-player |
| images, 3D models, sprites, renders | Art | flow-media, 3d-model, sprite-bake; docs/design/art-bible.md | technical-artist, blender-addon-engineer | chat (MCP) | review-player |
| sound and music (CC0 first) | Art | builders; docs/design/art-bible.md | game-audio-engineer | builder (agy) + chat (taste) | review-player |
| story, dialogue, names | Narrative | docs/CANON.md + the story bible | narrative-designer | builder (oc) drafts + chat (taste) | review-canon |
| menus, HUD, UI text | UI | .agents/skills/ui-card; docs/design/ui.md, rpg-menus.md | ui-designer | builder (agy) + chat (taste) | ui-finish-gate-reviewer + review-player |
| the player's eye before Feras plays; his play sessions | QA | players-eye-gate + the F12 capture (features/debug/playtest) | - | chat (review) | review-player + review-feras |
| audience, price, store page, playtests (drafts only) | Market | market-player; role cards (Business Strategist, Product Manager, UX Researcher, Persona Walkthrough Specialist, Feedback Synthesizer) | - | builder (oc) drafts + chat (review) | review-market |

## Limits (one table)
| Limit | Value | Enforced by |
|---|---|---|
| Godot builder runs, machine-wide | 2 at once (CAP_GODOT=2; agy CAP_AGY=2, Cloudflare DeepSeek CAP_CF=2; a RUN_KIND=py run counts toward its builder cap only) | tools/slots.sh (refuses when full) |
| Text run (opencode, OpenRouter :free; no Godot) | 1 (CAP_OC=1) | tools/slots.sh |
| Godot test suites at once | 2 (CHECK_SLOTS=2) | tools/check_slot.sh |
| Free memory before a Godot run | >= 2000 MB of available RAM (MIN_FREE_MB=2000, Feras 11-01) | tools/slots.sh |
| Builder with no commit | killed after 25 min (IDLE_MIN=25); result NOWORK | tools/build_pipeline.sh |
| OpenRouter :free requests | 50 a day, shared by all :free models | the provider; check before a run |
| Claude's handoff | the chat's task done, or ~85% of the 5-hour window; never context size (Feras 10-31) | the status line's usage; review-cost |
| Always-loaded notes | 27 KB each; lines: CLAUDE.md 80, HANDOFF 60, DECISIONS 70, LESSONS 100 (warns at 75%) | tools/doc_check.py |
| Godot code | <= 200 lines a file, <= 40 lines a function | tools/lint_gd.py |
| Paid image APIs | <= $1 each, only with Feras's OK | tools/hooks/pre_spend.py (see Routes) |

## Routes (free first)
| Need | Free route first | Paid fallback and cap |
|---|---|---|
| Images | Flow, Nano Banana (flow-media skill) | Paid image APIs only after Flow fails, <= $1, Feras OK |
| Video | Flow, Omni (flow-media skill) | Paid video only on Feras OK, cost named first |
| 3D models | Blender MCP search_assets / import_asset (CC0); open-source image-to-3D | Rodin while credits last: cost named first, log SPEND.md |
| Sprites | tools/art bake: offline renders (bake_sprites.tscn) | none needed |
| Sound and fonts | CC0 SFX (Freesound CC0, Kenney); CC0 fonts (OFL) | none; Feras OK before download, manifest entry |
| Research | see Research protocol | Cloudflare DeepSeek, no $ cap, spend logged |

PreToolUse hook tools/hooks/pre_spend.py blocks paid generation tools unless Feras says "spend ok" (P3.9). Before Rodin ends, prove free 3D route.

## Research protocol (audit plan D18)
Department research queues and dispatch: `.claude/skills/ops-review/SKILL.md` (Research prompts); results to `docs/research/<department>/`.


## Readers
Reading rule: CLAUDE.md. Reader models and review lenses: `low-cost-pipeline` skill (`.claude/skills/low-cost-pipeline/routing.md`).


## Model routing on Pro
Which worker does what and model routing: `low-cost-pipeline` skill (`.claude/skills/low-cost-pipeline/routing.md`).


## Builder loop (agy, Cloudflare DeepSeek, opencode)
Builder flow: `low-cost-pipeline` skill; debug recipe and prompt recipes: `builders` skill (`.claude/skills/builders/SKILL.md`).


## Practices taken from reem-bot and feras-career
Adopted across repo: note split and @ imports (CLAUDE.md, doc_check); /handoff (handoff skill); lane/dept on queue (doc_check); sync report (SessionStart); grep first (CLAUDE.md); checks and tests (check.sh); subagent rules (builders skill); batched questions (HANDOFF.md); generated MAP.md (map.py); orchestrator in builders skill.


## This repo's own methods
Methods adopted across repo: headless tests and summaries (CLAUDE.md, tools/check.sh); levels as text and code map (tools/map.py, docs/MAP.md); JSON content (content/); spec first and usage ledger (builders skill, docs/USAGE.md); eye gate (tools/eye_gate.sh); placeholders and engine (art-card skill, project.godot); manifest and CI (assets/manifest.json, .github/workflows/).


## How Feras can save tokens (prompt tips)
- Put the whole job in the first message, with what you already know; each missing detail costs a round trip.
- Answer numbered questions by number ("1 yes. 2 skip. 3 use your default").
- Say "use your defaults and log them" when you don't mind; Claude then stops only for real blockers.
- Name the output and its size ("just the screenshot verdict", "max 10 lines"); say what better means, not "improve it".
- Disagree once with "log decision: ..." so it is never argued again.
- `/clear` or a new chat between tasks; `/usage` shows what is left of the window; `/rewind` undoes a wrong turn.
