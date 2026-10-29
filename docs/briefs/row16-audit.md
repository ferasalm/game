# Brief: row16-audit (HANDOFF row 16, Ops; a read-only audit written to one report file)
You are in your own worktree on branch oc/row16-audit (made from origin/main). Follow GEMINI.md, including
<review_misses>. Load the minimal-change-engineer skill (our rules outrank its text).
Timebox: 30 min. First commit within 15 min, then small WIP commits: no commit for 25 min (IDLE_MIN) = NOWORK.

## Why
Feras (10-29): the always-loaded docs cost tokens in every chat; find duplicate and superseded rules once (a one-off,
no tool) and audit CLAUDE.md. Pillar served (docs/VISION.md): a small game finished fast (cheaper chats).

## Read first
CLAUDE.md, HANDOFF.md, docs/DECISIONS.md, docs/LESSONS.md, docs/WORKFLOW.md, .claude/rules/code.md,
.claude/skills/handoff/SKILL.md, .claude/skills/builders/SKILL.md, tools/doc_check.py (the caps).

## What to build
One file, docs/audits/2026-10-29-doc-dupes.md (<= 90 lines), three sections:
1. "Duplicates": each line `file:line | file:line | same rule in short | keep where (the more specific home)`.
   A duplicate = the same rule stated twice; a pointer line ("see X") is not a duplicate.
2. "Superseded": each line `file:line | the newer line file:line | why it is stale`. Dates in the lines decide.
3. "CLAUDE.md audit": at most 10 findings scored on: actionable (a reader can obey it), concise (no line a tool
   already enforces repeated in full), current (no stale rule), placed (detail that belongs in WORKFLOW or a skill).
   Each finding: `CLAUDE.md:line | problem | the fix in under 20 words`. Respect the caps: CLAUDE.md <= 80 lines,
   the four loaded files <= 27 KB.
Quote line numbers exactly; never guess; if unsure, leave the line out. Do not edit any other file.

## Do NOT edit
`CLAUDE.md`
`HANDOFF.md`
`docs/DECISIONS.md`
`docs/LESSONS.md`
`docs/WORKFLOW.md`
`.claude/`

## May edit
none

## Ripple
none: one new report file; Opus applies the true findings itself.

## Pre-mortem
none: read-only audit; Opus verifies each line number before any edit.

## Tests
none: report only; check.sh --no-godot.

## Checklist
- file: docs/audits/2026-10-29-doc-dupes.md

## Proof
`bash tools/check.sh --no-godot` raw last 15 lines; final message ends with `Built-by: <model> (opencode)`.
