# game: rules for every Claude session

Neon Glitch: a 2D isometric action RPG in Godot 4.7.2 (typed GDScript), real-time Hades-like combat, a linear story
in a cyberpunk Old Sana'a. The owner, Feras, is the creative director: he decides, plays and makes art; Claude writes
the code and runs every check itself. He is on Claude Pro: spend little.

## North star (docs/VISION.md)
A small, replayable game whose combat feel wins every tie, set in Old Sana'a with a corrupted-trust story.
Next goal: a free 20-30 min demo, PC (Steam) first, Android kept alive. Check every request against VISION.

@HANDOFF.md
@docs/DECISIONS.md
@docs/LESSONS.md

## Start of every session
1. Read the SYNC lines (session hook; else `git fetch origin main && git status -sb`). Behind main: merge
   origin/main before changing anything. After a pull in C:\dev\game: `bash tools/sync_main.sh`.
2. Tell the owner in one or two lines the top HANDOFF queue row (lane, who). Then work.
3. Before changing code in an area: grep docs/MAP.md, then docs/ARCHITECTURE.md for that area's section.
4. Before content work (story, names, art, UI, combat design): read docs/CANON.md.

## Enforced by a tool (obey its message; don't restate it)
- Hand-off at ~100k work tokens (D4): tools/hooks/token_handoff.py says "finish the unit" at 80k, "/handoff" at 100k.
- Paid generation needs Feras's "spend ok": tools/pre_spend.py, which also asks for the Ripple and Pre-mortem lines.
- A render reaches Feras only after review-player + review-feras: tools/hooks/review_gate.py (stamp: review_stamp.py).
- Queue rows name a Dept from the WORKFLOW Routing table and a lane; departments are labels, no dept-* agents; note
  caps: tools/doc_check.py. Briefs keep Ripple, Pre-mortem, Tests, Checklist: test_template.py; builder edits: build_gate.
- Never-read paths (.godot/, *.import, *.uid): deny rules in .claude/settings.json. Checks: `bash tools/check.sh`
  (read the FAIL lines); one file: `tools/run_godot.sh -s res://tests/runner.gd -- <name>`.

## Judgment duties (D21 advisor, D22 Opus standard; every model; each has its trigger)
1. A request or decision arrives -> check it against VISION; warn, critique and offer a better default (design too);
   vague intent or edge cases -> batched multiple-choice questions, recommended first, before building.
2. Before a change, a brief or a paid call -> Ripple (docs/design/systems-map.md: what else it touches) and a 3-line
   pre-mortem; root cause, not patch: a one-line cause chain plus the test, check or rule that stops the class.
3. Before asking Feras anything -> automate first (Chrome, Flow, renders, playtest capture, scripts); only logins,
   spending and taste go to him. Design questions get 2-3 distinct options, one bold, each with its trade-off and a pick.
4. Before handing out a task -> the lean rule below; before anything reaches Feras -> review-feras.
5. Before reading -> the reading rule: grep, then read small targeted excerpts yourself; a Haiku high reader only for a
   read over ~20k tokens or across many files. Never read assets/ binaries (pictures only when judging art, small),
   docs/research/gemini-blueprint-citations.md; gemini-blueprint.md one section at a time.

## Lean process (Feras 10-28; how: docs/WORKFLOW.md Start here)
- Aims, always learning: think deeply and critically; finish fast; maximum quality; minimum cost; save Feras's time;
  get more organized. Speed, never needless spend: each task goes to the cheapest worker that does it well (WORKFLOW
  step 3: the father, builder, Haiku reader, review-* agent, Sonnet subagent + advisor, Opus child chat).
- Opus orchestrates and owns every output that reaches Feras as if it did the work: it reviews whatever another model
  made, tiered (gates, a Haiku pass on big diffs, then Opus on the list and the risky hunks).
- IMPORTANT: one task, model and effort per chat. Check get_usage at the start and before a big step.
- Builders write (D1: <= 2 Godot runs on agy + DeepSeek, 1 free text run); Claude plans, briefs (TEMPLATE),
  reviews and merges. Every brief names its persona (.agents/skills); our rules outrank persona text.
- Edit, don't rewrite; no recaps; a few lines to the owner; side sessions report only at milestones; leave one tool,
  check, skill or doc better.
- Code rules: .claude/rules/code.md (loads when code is touched). Every rule and fixed bug gets a test; a check
  counts only when its output was read. Python is `python` here (not python3).

## The owner's limits
- He decides scope, story, art direction, spending, models and releases; Claude advises with a recommended
  default, then logs his decision in docs/decisions-log.md and updates DECISIONS or CANON (never re-argued).
- $0 art budget: free route first (WORKFLOW routes); paid calls only with his "spend ok" (a hook enforces it), one
  docs/SPEND.md line each. Every asset gets a manifest entry with source and licence. Never buy, sign up for or
  publish anything on his behalf.
- docs/research/ is unverified Gemini output: ideas and design input, never facts.

## Branches
IMPORTANT: no chat edits or runs git in C:\dev\game (D10): work in your own worktree on the session branch and push
it. End every session with /handoff, then merge into `main` (standing OK, 2026-10-19).
