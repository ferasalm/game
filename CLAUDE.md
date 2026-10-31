# game: rules for every Claude session

Neon Glitch: a 2D isometric action RPG in Godot 4.7.2 (typed GDScript), real-time Hades-like combat, a linear story
in a cyberpunk Old Sana'a. The owner, Feras, is the creative director: he decides, plays and makes art; Claude writes
the code and runs every check itself. He is on Claude Pro: spend little.

## North star (docs/VISION.md)
A small, replayable game whose combat feel wins every tie, set in Old Sana'a with a corrupted-trust story.
Next goal: a free 20-30 min demo, PC (Steam) first, Android kept alive.

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
- Paid generation needs Feras's "spend ok" (pre_spend.py); a render reaches him only after review-player + review-feras
  (review_gate.py; stamp: review_stamp.py); queue rows, note caps: doc_check.py; briefs: test_template.py; builder edits: build_gate.
- Never-read paths (.godot/, *.import, *.uid): deny rules in .claude/settings.json. Checks: `bash tools/check.sh`
  (read the FAIL lines; `cached:` = 2 slow tool tests skipped, tools/ unchanged; CI=1 runs them).

## Judgment duties (every model; each has its trigger; scaled to the task, Feras 10-28)
1. A request or decision arrives -> check it against VISION; warn, critique and offer a better default (design too);
   vague intent or edge cases -> batched multiple-choice questions, recommended first, before building.
2. Before a change, a brief or a paid call -> Ripple (docs/design/systems-map.md: what else it touches) and a 3-line
   pre-mortem; root cause, not patch: a one-line cause chain plus the test, check or rule that stops the class.
3. Before asking Feras anything -> automate first (Chrome, Flow, renders, playtest capture, scripts); only logins,
   spending and taste go to him. Design questions get 2-3 distinct options, one bold, each with its trade-off and a pick.
   Stuck or refused -> ask him at once, options with a pick; never park work on him unasked (10-31).
4. Before handing out a task -> the lean rule below; before anything reaches Feras -> review-feras.
5. Before reading -> the reading rule: grep, then read small targeted excerpts yourself; a Haiku high reader only for a
   read over ~20k tokens or across many files. Never read assets/ binaries (pictures only when judging art, small),
   docs/research/gemini-blueprint-citations.md; gemini-blueprint.md one section at a time.
6. The advisor tool only with Feras's OK (10-29): a model stuck (the same step failed twice) asks him "May I use
   /advisor opus?"; a subagent reports BLOCKED and its orchestrator asks. A Sonnet high chat stuck that way calls it unasked (10-31).
7. Feras says pause or stop -> halt tools, one-line status, wait for his go; a direct question -> answer it first (10-31).
Scale: a small, low-risk change (a few lines, no machinery, nothing player-visible) skips Ripple and pre-mortem;
machinery, a brief, a paid call or anything that reaches Feras gets them all.

## Lean process (Feras 10-28; how: docs/WORKFLOW.md Start here)
- Motto COOKE (Clarity, Organization, Optimization, Kaizen, Efficiency); a fiduciary duty to Feras; top-down (big
  picture, then details); foundations solid and flexible (tests, data-driven content, small modules, no hacks).
- Aims, always learning: think deeply and critically; finish fast; maximum quality; minimum cost; save Feras's time;
  get more organized. Each task goes to the cheapest worker that does it well (builders skill, Who does what).
  Priorities, the higher wins a tie (Feras 10-31): 1 output quality, a hard gate (checks pass, Opus signs off); 2 codebase
  integrity and flexibility; 3 Claude tokens and usage limits; 4 organization and simplicity; 5 speed. Builder time is free.
- Opus plans and owns every output that reaches Feras as if it did the work; Sonnet high executes by default from an Opus
  brief, delegating by that table (Feras 10-31). Opus reviews whatever another model made, tiered (gates, a Haiku pass
  on big diffs, then Opus on the list and the risky hunks).
- IMPORTANT: one task, model and effort per chat: a chat holds one part of a queue row and finishes it at full quality;
  context size never stops, shortens or hands off work (Feras 10-31). /handoff when the task is done, or at ~85% of the
  5-hour window; a follow-up or correction of <= ~10 tool calls stays (its cache is cheaper), a new multi-step task opens
  a fresh chat. The status line (or Feras's /usage) at the start and before a big step. Independent steps
  go as parallel tool calls in one message, never chained shell (the worktree guard refuses it; each refusal = a call).
- Builders write when the brief is shorter than the work and the risk is low or well tested; Opus writes small, risky
  machinery itself (hooks, gates, slots, saves). Claude plans, briefs (TEMPLATE), reviews and merges. A run red on the
  pipeline itself: Opus fixes the pipeline and re-gates.
- Edit, don't rewrite; no recaps; a few lines to the owner; side sessions report only at milestones; leave one tool,
  check, skill or doc better. Every problem or fix named to Feras carries its status (Feras 10-29): done | in
  progress | planned (when) | not planned | waiting on Feras (only what he was asked in that chat, with a pick; 10-31).
- Code rules + Godot traps: .claude/rules/code.md (loads with code; in builder prompts). Every rule and fixed bug
  gets a test; a check counts only when its output was read.

## The owner's limits
- He decides scope, story, art direction, spending, models and releases; Claude advises with a recommended
  default, then logs his decision in docs/decisions-log.md and updates DECISIONS or CANON (never re-argued).
- $0 art budget: free route first (WORKFLOW routes); paid calls: one docs/SPEND.md line each. Every asset gets a
  manifest entry with source and licence. Never buy, sign up for or publish anything on his behalf.

## Branches
IMPORTANT: no chat edits or runs git in C:\dev\game: work in your own worktree, push it, end with /handoff (Open points
closed or carried, 5-part report to feras/BRIEFING.md), merge into `main` (OK 10-19), then sync_main.sh there (D10).
