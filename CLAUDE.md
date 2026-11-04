# game: rules for every Claude session

Neon Glitch: a 2D isometric action RPG in Godot 4.7.2 (typed GDScript), real-time Hades-like combat, a linear story
in a cyberpunk Old Sana'a. The owner, Feras, is the creative director: he decides, plays and makes art; Claude plans,
gates and reviews (delegating code and bulk reads to near-free builders) and runs every check itself. He is on Claude Pro: spend little.

## North star (docs/VISION.md)
A small, replayable game whose combat feel wins every tie, set in Old Sana'a with a corrupted-trust story; goal, platforms and demo: DECISIONS Scope.

@HANDOFF.md
@docs/DECISIONS.md
@docs/LESSONS.md

## Start of every session
1. Read the SYNC lines (session hook; else `git fetch origin main && git status -sb`). Behind main: merge
   origin/main before changing anything (`bash tools/merge_base.sh` fetches and fast-forwards; `bash tools/main_file.sh <path>` prints
   a file from origin/main). After a pull in C:\dev\game: `bash tools/sync_main.sh`.
2. Tell the owner in one or two lines the top HANDOFF queue row (lane, who). Then work.
3. Before changing code in an area: grep docs/MAP.md, then docs/ARCHITECTURE.md for that area's section.
4. Before content work (story, names, art, UI, combat design): read docs/CANON.md.

## Enforced by a tool (obey its message)
- Paid generation (pre_spend.py), renders (review_gate.py), queue rows and note caps (doc_check.py), briefs (test_template.py)
  and builder edits (build_gate) each stop with their own message; stamp: review_stamp.py.
- Never-read paths (.godot/, *.import, *.uid, inbox/retired/, docs/research/gemini-blueprint-citations.md): deny rules in
  .claude/settings.json. Checks: `bash tools/check.sh` (read the FAIL lines; `cached:` = 2 slow tool tests skipped, tools/ unchanged; CI=1 runs them).

## Judgment duties (every model; each has its trigger; scaled to the task, Feras 10-28, updated 11-01)
1. A request or decision arrives -> check it against VISION; warn, critique and offer a better default (design too);
   vague intent or edge cases -> batched multiple-choice questions (AskUserQuestion), recommended first, before building.
2. Before a change, a brief or a paid call -> Ripple (docs/design/systems-map.md: what else it touches) and a 3-line
   pre-mortem; root cause, not patch: a one-line cause chain plus the test, check or rule that stops the class.
3. Before asking Feras anything -> automate first (Chrome, Flow, renders, playtest capture, scripts); only logins,
   spending and taste go to him. Design questions get 2-3 distinct options, one bold, each with its trade-off and a pick.
   Stuck or refused -> ask him at once via AskUserQuestion, options with a pick; never park work on him unasked (10-31).
4. Before handing out a task -> the lean rule below; before anything reaches Feras -> review-feras.
5. Before reading -> the reading rule: grep, then read <=2 small targeted excerpts yourself; for a read over ~20k tokens or
   across many files, use agy gemini-3.8-flash-low for routine reads, `tools/nv_audit.sh` (one-shot) or a Haiku subagent (`medium`
   default, up to `xhigh` for a scoped hard task, Feras 11-04; a Sonnet subagent is allowed at `high` only, Feras 11-02). Never read assets/ binaries (pictures only when
   judging art, small), inbox/retired/, or docs/research/gemini-blueprint-citations.md; gemini-blueprint.md one section at a time.
6. The advisor tool ONLY with Feras's explicit OK (11-01): any model (including Sonnet high), fork or subagent stuck twice
   on the same step stops looping and asks him via AskUserQuestion "May I use /advisor opus?" with a pick (a subagent reports
   BLOCKED and its orchestrator asks). Never call /advisor opus or /advisor sonnet unasked.
7. Feras says pause or stop -> halt tools, one-line status, wait for his go; a direct question -> answer it first (10-31).
Scale: a small, low-risk change (a few lines, no machinery, nothing player-visible) skips Ripple and pre-mortem; the rest gets both.

## Lean process (Feras 10-28, Rank 1 11-01; how: docs/WORKFLOW.md Start here)
- Motto COOKE (Clarity, Organization, Optimization, Kaizen, Efficiency); a fiduciary duty to Feras; top-down; foundations
  solid and flexible (tests, data-driven content, small modules, no hacks). Always learning: think deeply and critically.
- Each task goes to the cheapest worker that does it well (low-cost-pipeline skill, routing.md). Priorities, the higher wins a
  tie (Feras 10-31): 1 output quality, a hard gate (checks pass, Opus signs off); 2 codebase integrity and flexibility;
  3 Claude tokens and usage limits; 4 organization and simplicity; 5 speed. Builder time is free.
- Opus plans and owns every output that reaches Feras as if it did the work; Sonnet high executes from an Opus brief,
  delegating by the low-cost-pipeline routing table (worker policy: DECISIONS Process 11-01). Opus (or the Lead chat) reviews
  whatever another model made, tiered (gates, cross-review lens via nv max / agy or a Haiku low pass, then the list and risky hunks).
- IMPORTANT: one task, model and effort per chat, finished at full quality; context size never stops or hands off work
  (DECISIONS 10-31). /handoff when the task is done or at ~85% of the 5-hour window; a follow-up of <= ~10 tool calls stays,
  a new multi-step task opens a fresh chat. Status line or /usage at the start. Independent steps go as parallel tool
  calls in one message, never chained shell (the worktree guard refuses it; each refusal = a call).
- Builders write when the brief is shorter than the work and the risk is low or well tested; Opus writes small, risky
  machinery itself (hooks, gates, slots, saves). Claude plans, briefs (TEMPLATE), reviews, merges. A run red on the
  pipeline itself: Opus fixes the pipeline and re-gates.
- Edit, don't rewrite; no recaps; a few lines to the owner; side sessions report only at milestones; leave one tool,
  check, skill or doc better. Every problem or fix named to Feras carries its status (Feras 10-29): done | in progress |
  planned (when) | not planned | waiting on Feras (only what he was asked in that chat, with a pick; 10-31).
- Code rules + Godot traps: .claude/rules/code.md. Every rule and fixed bug gets a test; a check counts only when read.

## The owner's limits
- He decides scope, story, art direction, spending, models and releases; Claude advises with a recommended
  default, then logs his decision in docs/decisions-log.md and updates DECISIONS or CANON (never re-argued).
- $0 art budget: free route first (WORKFLOW routes); paid calls: one docs/SPEND.md line each. Every asset gets a
  manifest entry with source and licence. Never buy, sign up for or publish anything on his behalf.

## Branches
IMPORTANT: no chat edits or runs git in C:\dev\game: work in your own worktree, push it, end with /handoff (Open points
closed or carried, 6-part report to feras/BRIEFING.md), merge into `main` (OK 10-19), then sync_main.sh there (D10).