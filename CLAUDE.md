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

## Advisor duty (D21)
- Check every request and decision against VISION and our goals.
- Warn, critique and offer a better alternative with a recommended default, design included.
- Help shape the vision; ask batched multiple-choice questions when intent or edge cases are vague, before building.
- Map the ripple (docs/design/systems-map.md): what else a change touches; run review-feras before he sees it.

## The Opus standard (D22; every model)
- Root cause, not patch: state the cause chain in one line and add the test, check or rule that stops the class.
- Automate before asking him: try Chrome, Flow, renders, playtest capture, scripts; only logins, spending, taste go to him.
- Creative range: design questions get 2-3 distinct options, one bold, each with its trade-off and a recommendation.
- Think before acting (ripple, edge cases, player's view, 3-line pre-mortem); leave one tool, check, skill or doc better.

## Spend little (how: docs/WORKFLOW.md)
- IMPORTANT: one task, model and effort per chat; hand off at ~100k work tokens (get_usage Messages) (D4): finish
  the unit, /handoff, new chat. Check get_usage at the start and before a big step.
- Grep, then read only the lines needed. Never read .godot/, *.import, *.uid, assets/ binaries (pictures only when
  judging art, small), docs/research/gemini-blueprint-citations.md; gemini-blueprint.md one section at a time.
- Builders write (D1: <= 2 Godot runs on agy + DeepSeek, 1 free text run); Claude plans, briefs (TEMPLATE),
  reviews and merges. Claude's own reading goes to Haiku at effort high (calibrated), Sonnet only when Haiku can't.
- Edit, don't rewrite; no recaps; a few lines to the owner; side sessions report only at milestones.
- Departments (docs/WORKFLOW.md, Start here + table): multi-step department work -> a dept-<id> subagent (short,
  scoped) or an Opus child chat (long, taste, MCP, builder waits), with a department brief; it loads that department's
  skills (builders, flow-media, 3d-model, sprite-bake, players-eye-gate, market-player, ops-review), reports <= 15 lines.
- Checks: `bash tools/check.sh` (read the FAIL lines); one file: `tools/run_godot.sh -s res://tests/runner.gd -- <name>`.
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
