# Brief: row26-s12-parts (cf DeepSeek high; Python only, RUN_KIND=py)
You are in your own worktree on branch oc/row26-s12-parts (made from origin/row26-s12-base; the base is pushed). Follow GEMINI.md, including
<review_misses>. Load the builders skill.
Pattern: tools/base_red.py, tools/build_gate.py
Timebox: 40 min (<= 45). First commit within 15 min, then small WIP commits.

## Why
Feras 11-02: one model may run several times at once (three DeepSeek max, two agy, two GLM) to finish sooner, as long as the parts complement each other and never conflict. Two checks make that safe: one before launch (the briefs), one before merge (the finished branches). Pillar served: none directly (faster, safer builds).

## Read first
tools/test_parts_plan.py (the red tests, read-only: they define every output), tools/base_red.py (how a brief's `## Tests` section is read), tools/build_gate.py functions section_paths and breaches (reuse the parsing of backticked paths, folders ending in `/`, globs).

## What to build
`tools/parts_plan.py` (<= 150 lines, functions <= 40 lines, docstring first):
1. `parts_plan.py BRIEF...`: for each brief read `## May edit` (backticked paths; the word `none` means no paths), `## Do NOT edit` (backticked paths only) and `## Tests` (every path ending in .py, .gd or .sh before ` ::`). Part name = the brief's file stem. Exit 1 and print one line per problem, naming both parts and the path:
   - two parts' May edit overlap: the same path, a folder (ends in `/`) and a path inside it, or a glob that matches the other's path; EXCEPT generated or union files shared on purpose: `docs/MAP.md`, `docs/DOCMAP.md`, `docs/runs.csv`, `docs/doc_graph_allow.txt`;
   - a part's May edit hits a path another part lists in its Tests or its Do NOT edit;
   - two parts name the same test file.
   No problem: print `OK <n> parts` then the line `order: <stems in argument order>`; exit 0.
2. `parts_plan.py --branches B1 B2 ...` (cwd = a git checkout): for every pair run `git merge-tree --write-tree --name-only B1 B2` (no checkout is touched); a pair that exits non-zero is a conflict: print `conflict: B1 B2 <file>` per conflicting file (the file names the command prints after the tree id). All clean: `no conflicts, <n> branches`; any conflict: exit 1.
Pass every path and ref as an argument list, never through a shell string.

## Do NOT edit
D6 defaults, protected by tools/build_gate.py without being listed. Keep this prose free of backticks outside May edit.

## May edit
none

## Ripple
none: a new stand-alone tool; the skill and the head call it. docs/MAP.md and DOCMAP.md refresh themselves.

## Pre-mortem
- A brief with no May edit section: treat as no paths, never a traceback.
- git merge-tree output differs by version: read the file names after the first line, and test on this git (2.56).
- The dry run must leave the checkout clean: tested.

## Tests
- tools/test_parts_plan.py :: every test (red on the base)

## Checklist
- file: tools/parts_plan.py
- test: tools/test_parts_plan.py :: test_two_parts_editing_the_same_file_conflict

## Proof
`bash tools/check.sh --no-godot` raw last 15 lines; final message ends with `Built-by: DeepSeek V4.1 Flash high (opencode)`.
