# Brief: prompt-check (HANDOFF row 22, step 2: also the smoke test of the agy lane, the cf max lane and the fork)
You are in your own worktree on branch gemini/prompt-check (made from origin/system-v3). Follow GEMINI.md, including
<review_misses>. Load the minimal-change-engineer skill (build_pipeline.sh pastes it; our rules outrank its text).
Timebox: 30 min. First commit within 15 min, then small WIP commits: no commit for 25 min (IDLE_MIN) = NOWORK.
This is a Python-only run (RUN_KIND=py): change no Godot file; the check is `bash tools/check.sh --no-godot`.

## Why
Feras 10-31: every worker prompt passes one lint before it is sent, so a missing Done line or a Sonnet prompt without
/goal is caught by a tool, not by Opus reading. Pillar: process (fewer wasted worker runs and refusals).

## Read first
tools/test_prompt_check.py (the tests to make green; read it all), docs/briefs/TEMPLATE.md (the brief headings),
docs/WORKFLOW.md lines 40-50 (the department brief). Read nothing else.

## What to build
1. New file tools/prompt_check.py (Python 3, standard library only, <= 150 lines, a docstring first line saying what
   it is). `check(text, kind) -> list[str]` returns one miss message per problem; an empty list = clean.
2. kind "brief": a line `## <Heading>` for each of Why, Read first, What to build, Do NOT edit, May edit, Ripple,
   Pre-mortem, Tests, Checklist, Proof; and at most 80 lines (the message names 80).
3. kind "oneshot": each of Goal, Inputs, Do NOT, Output contract, Done, Stop rules present as a label at the START of
   a line, after optional markdown marks (#, -, *, spaces), followed by `:`, `**`, or the end of the line.
   "Goal: x", "**Goal**: x" and "## Goal" all count; a label in the middle of a sentence does not.
4. kind "chat": the labels Department, Queue row, Model, Skills, Persona, Goal, Context, Lane plan, May edit,
   Do NOT edit, Commit and merge, Done when, Report, each written `Label:` anywhere in the text (or as a heading).
   A Sonnet prompt = text starts with `/goal`, or a `Model:` line naming Sonnet. A Sonnet prompt must start with
   `/goal` (message names /goal), be under 4000 characters (message names 4000), and hold a turn cap: a number
   followed by "turn" or "turns", or the words "turn cap" (message names "turn cap"). A text that starts with `/goal`
   skips the department labels (its department brief lives in the file it points to).
5. CLI: `python tools/prompt_check.py <file> --kind brief|oneshot|chat`. Clean: print `ok <file> (<kind>)`, exit 0.
   Any miss: print one line `MISS <file>: <message>` per miss, exit 1. Unknown kind or unreadable file: print the
   reason to stderr, exit 2. Read the file as UTF-8.

## Do NOT edit
D6 defaults, protected by tools/build_gate.py without being listed: existing tests, tools/, .github/ (edits and
deletions; new test files are allowed) and every change under assets/ (incl. *.import). Keep this prose free of
backticks: every backticked token in this section is a forbidden path, and May edit does not lift it.
`tools/test_prompt_check.py`
`docs/briefs/`
`.claude/`
`GEMINI.md`

## May edit
`tools/prompt_check.py`
`docs/MAP.md`

## Ripple
none: a new stand-alone tool; nothing imports it yet. docs/MAP.md: `git add tools/prompt_check.py`, then `python tools/map.py`.

## Pre-mortem
1. A label inside a sentence passes as present -> start-of-line rule for oneshot (tested).
2. A Sonnet prompt over the cap or without a turn cap passes -> each has its own message (tested).
3. The tool exits 0 on a crash -> unreadable file and unknown kind exit 2, misses exit 1 (tested).

## Tests
tools/test_prompt_check.py, red on the base, read-only: `python tools/test_prompt_check.py` must print
"test_prompt_check: 15 tests passed". Player-visible: none (tools).

## Checklist
- file: tools/prompt_check.py
- has: tools/prompt_check.py :: def check

## Proof
`bash tools/check.sh --no-godot` raw last 15 lines; final message ends with `Built-by: Gemini 3.8 Flash (agy)`
(opencode: `Built-by: <model> (opencode)`).
