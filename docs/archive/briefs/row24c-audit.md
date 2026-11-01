# Brief: row24c-audit (HANDOFF row 24, part c; read-only audit, one new doc)
You are in your own worktree on branch gemini/row24c-audit (made from origin/system-v4; the base is pushed). Follow GEMINI.md, including
<review_misses>. Load the minimal-change-engineer skill (the pipeline pastes it; our rules outrank its text).
Pattern: docs/briefs/TEMPLATE.md
Timebox: 45 min. First commit within 15 min, then small WIP commits: no commit for 25 min (IDLE_MIN) = NOWORK.

## Why
Feras 11-01: know the state of the game code before M1. No fixes here; every finding becomes an input line for row 3 (the M1 brief). Pillar: combat feel wins ties, so findings about the turn-based battle matter most.

## Read first
`python tools/res_graph.py --list unused` and `--list tests`; `grep -n "battle\|turn" docs/MAP.md` for the turn-based battle code; `.claude/rules/code.md` (the rules the audit measures against);
docs/ARCHITECTURE.md section 8 only. Read nothing else beyond the files a finding needs.

## What to build
Write docs/audits/2026-11-02-integrity.md (<= 200 lines), one section per item, each finding on one line `file:line | evidence | action (archive / move to JSON / key / fix test / leave)`:
1. Dead scenes and scripts: the tools/res_graph.py unused list, minus the allowlist; say which are runtime-loaded by a string path (grep proves it).
2. Exactly what row 4 archives from the turn-based battle: every file, scene, test, content JSON, localization key and autoload that belongs only to the turn-based battle (the real-time fight replaces it). List files that the real-time game still needs separately.
3. Files past the code rules: more than 200 lines (`wc -l`), functions over 40 lines (list the 10 longest with file:line), a .gd with no `## purpose` line in its first 6 lines.
4. Numbers in code that belong in content JSON: gameplay numbers (damage, hp, costs, timings) written as literals in features/ or core/ outside tests (`grep -nE`; top 15 with evidence).
5. Player text outside TextDB: string literals shown to the player (Label text, dialogue) not read through TextDB (`grep -n 'text = "'`; top 15).
6. Tests that only check a mock: tests whose assertions hold on a stub or a Dictionary literal and never touch the real Def or logic (top 10 with the assert line).
End with `## Top 10` : the ten most useful items for row 3 in priority order, one line each. A finding with no file:line and quoted evidence is not a finding: leave it out.

## Do NOT edit
D6 defaults, protected by tools/build_gate.py without being listed: existing tests, tools/, .github/, plugins/ (edits and
deletions; new test files are allowed) and every change under assets/ (incl. *.import). Keep this prose free of
backticks: every backticked token in this section is a forbidden path, and May edit does not lift it.
`features/`
`core/`
`content/`
`localization/`
`tests/`
`docs/WORKFLOW.md`
`HANDOFF.md`
`CLAUDE.md`

## May edit
`docs/audits/2026-11-02-integrity.md`

## Ripple
none: one new doc; parts a and b edit other files (part b moves the OLD files out of docs/audits/ and leaves this new one).

## Pre-mortem
1. Invented line numbers: every finding quotes the matched text from its grep. 2. A runtime-loaded file called dead: item 1 requires the string-path grep. 3. Running past the timebox: items 4-6 stop at their top counts.

## Tests
No test: a doc. Gate: `bash tools/check.sh --no-godot` stays green (doc_check, MAP current).

## Checklist
- file: docs/audits/2026-11-02-integrity.md
- has: docs/audits/2026-11-02-integrity.md :: ## Top 10

## Proof
`RUN_KIND=py`; `bash tools/check.sh --no-godot` raw last 15 lines; final message ends with
`Built-by: Gemini 3.8 Flash (agy)`.
