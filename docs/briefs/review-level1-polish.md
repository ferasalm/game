# Brief: review-level1-polish (review only; <= 60 lines)
You are in your own worktree (made from origin/main). Follow AGENTS.md. Load the code-reviewer mindset of the
godot-gameplay-scripter skill. You REVIEW; you change no file in the repo.

## Why
agy built gemini/level1-polish (gate PASS). A second model (you) checks it against its brief before Feras playtests main tonight.

## Read first
The brief: docs/briefs/level1-polish.md.
The diff: `git fetch origin; git diff origin/main...gemini/level1-polish -- . ':!*.uid' ':!docs/MAP.md'`
(read it per path; skip *.png and *.glb).

## What to check
1. Per brief: each "What to build" step and each Checklist line is present in the merged diff. List misses.
2. Nothing from main was dropped or reverted; no duplicate JSON keys or CSV rows.
3. Line by line: core/content_db.gd (registry), any core/ file, any test whose assertions were removed or weakened.
4. Code rules (CLAUDE.md): typed GDScript, no node lookups by path, no gameplay numbers in code, player text as
   localization keys, logic/ folders pure.

## Output
WRITE C:/dev/game-wt/level1-polish.review.md, at most 15 lines:
first line `REVIEW PASS` or `REVIEW MISSES <n>`; then one line per miss: `<path>:<line> <what is wrong>`; serious
issues first. Nothing else.

## Do NOT edit
`*`
(No file inside the repo may change. Write only the review file outside the repo.)

## Tests
None.

## Checklist
- file: docs/briefs/level1-polish.md

## Proof
The appended lines; final message ends with `Built-by: <model> (opencode)`.
