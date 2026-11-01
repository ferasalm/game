# Brief: row24b-archive (HANDOFF row 24, part b)
You are in your own worktree on branch oc/row24b-archive (made from origin/system-v4; the base is pushed). Follow GEMINI.md, including
<review_misses>. Load the minimal-change-engineer skill (the pipeline pastes it; our rules outrank its text).
Pattern: docs/MAP.md
Timebox: 30 min. First commit within 15 min, then small WIP commits: no commit for 25 min (IDLE_MIN) = NOWORK.

## Why
Feras 11-01: the repo holds only what is live. Finished briefs and old audits move to docs/archive/ so greps and reads stay small. Pillar: process.

## Read first
`ls docs/briefs docs/audits`; `grep -rn "docs/briefs/\|docs/audits/" tools plugins .claude CLAUDE.md HANDOFF.md docs/design docs/*.md`. Read nothing else.

## What to build
1. `git mv` every file in docs/briefs/ into docs/archive/briefs/ EXCEPT these (they stay): TEMPLATE.md, system-v3.md, row24-one-home.md, row24a-one-home-docs.md, row24b-archive.md,
   row24c-audit.md, row25-opus-gate.md, neon-cold-open.md, neon-roof.md (game code comments cite these two), archive-cleanup.md and the folder archive-cleanup/ (HANDOFF cites them).
2. `git mv` every file in docs/audits/ into docs/archive/audits/ (the folder may later hold 2026-11-02-integrity.md: do not touch or create it).
3. Fix every citing path in live files to the new location, path text only: plugins/studio/README.md (row22-probe.md), plugins/studio/agents/review-player.md (the 2026-10-26 retro),
   .claude/skills/builders/lessons.md (cross-review.md), docs/DECISIONS.md line 4 (`docs/audits/2026-10-27-*` -> `docs/archive/audits/2026-10-27-*`), docs/design/level-1.md (the brief it cites; grep).
   Never touch docs/decisions-log.md or docs/decisions-archive.md (history stays as written).
4. `python tools/map.py` (regenerates docs/MAP.md). Then `bash tools/check.sh --no-godot` and fix only what you broke.

## Do NOT edit
D6 defaults, protected by tools/build_gate.py without being listed: existing tests, tools/, .github/, plugins/ (edits and
deletions; new test files are allowed) and every change under assets/ (incl. *.import). Keep this prose free of
backticks: every backticked token in this section is a forbidden path, and May edit does not lift it.
`features/`
`core/`
`content/`
`.agents/skills/`
`.claude/rules/code.md`
`.claude/settings.json`
`docs/decisions-log.md`
`docs/decisions-archive.md`
`docs/WORKFLOW.md`
`CLAUDE.md`
`HANDOFF.md`

## May edit
`docs/briefs/`
`docs/audits/`
`docs/archive/`
`docs/MAP.md`
`docs/DECISIONS.md`
`docs/design/level-1.md`
`plugins/studio/README.md`
`plugins/studio/agents/review-player.md`
`.claude/skills/builders/lessons.md`

## Ripple
docs/MAP.md is generated (step 4). Code comments in features/neon cite neon-cold-open.md and neon-roof.md: those stay. tools/test_prompt_check.py cites system-v3.md: stays. Parts a and c run beside this one and edit other files only.

## Pre-mortem
1. A moved file was read by a tool: step 1's keep list plus the check. 2. A broken citation: the step 3 grep, rerun after the moves. 3. Check red on MAP.md: step 4.

## Tests
No new test: `bash tools/check.sh --no-godot` (doc_check, map --check) is the gate. Player-visible: none (docs only).

## Checklist
- file: docs/archive/briefs/row22-probe.md
- file: docs/archive/audits/2026-10-27-process-audit.md

## Proof
`RUN_KIND=py`; `ls docs/briefs docs/audits`; `bash tools/check.sh --no-godot` raw last 15 lines; final message ends with
`Built-by: DeepSeek (opencode)`.
