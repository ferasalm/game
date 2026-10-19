# game: rules for every Claude session

An HD-2D timeline RPG in Godot 4.7.2 (typed GDScript). The owner, Feras, is the creative director: he decides,
plays and makes art; Claude writes the code and runs every check itself. He is on Claude Pro: spend little.

@HANDOFF.md
@docs/DECISIONS.md
@docs/LESSONS.md

## Start of every session
1. Read the SYNC lines (session hook; else `git fetch origin main && git status -sb`). Behind main: merge
   origin/main before changing anything.
2. Tell the owner in one or two lines the next step from HANDOFF and its model and effort. Then work.
3. Before changing code in an area: grep docs/MAP.md, then grep docs/ARCHITECTURE.md for that area's section.

## Spend little (why: docs/EFFICIENCY.md)
- One task per chat, one model and effort per chat. Past ~150k tokens: finish the unit, /handoff, new chat.
- Grep, then read only the lines needed. Never read .godot/, *.import, *.uid, assets/ binaries (pictures only
  when judging art, small), or docs/research/gemini-blueprint-citations.md.
- docs/research/gemini-blueprint.md is ~20k tokens: grep its headings, read one section at a time.
- Edit, don't rewrite; no recaps; replies to the owner in a few lines.
- No subagents to explore. Delegate only mechanical work that reads far more than its brief.
- Checks: `tools/check.sh` (read the FAIL lines). One test file: `tools/run_godot.sh -s res://tests/runner.gd -- <name>`.

## Code rules (Godot and tools/lint_gd.py enforce them)
- Godot 4 syntax only, statically typed (an untyped declaration is an error). <= 200 lines a file, <= 40 a
  function, a `## purpose` line in the first 6 lines (it feeds docs/MAP.md: run `python3 tools/map.py`).
- `logic/` folders are pure: no nodes, scene tree, autoloads, input or await. View code never computes rules.
- Content is JSON read into read-only Def classes; changing numbers live in state objects; saves in GameState.
- No node lookups by path: `@export` or `%UniqueName`. No gameplay numbers in code. Player text = localization keys.
- Every rule and every fixed bug gets a test. A check counts only when its output was read.

## The owner's limits
- He decides scope, story, art direction, spending, models and releases; Claude advises with a recommended
  default, then logs his decision in docs/DECISIONS.md (dated, one line, never re-argued).
- $0 art budget: free tools, CC0 packs, his Gemini and Flow outputs. Every asset gets a manifest entry with its
  source and licence. Never buy, sign up for or publish anything on his behalf.
- docs/research/ is unverified Gemini output: ideas and design input, never facts.

## Branches
Work on the session branch and push it. `main` is the shared branch; merge into it only with the owner's
standing OK (pending: BRIEFING question 5).

## End of every session
Run /handoff (.claude/skills/handoff/SKILL.md).
