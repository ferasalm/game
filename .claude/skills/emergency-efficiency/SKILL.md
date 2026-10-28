---
name: emergency-efficiency
description: Low-budget mode when the Claude limit is tight (owner says "emergency efficiency", the 5-hour window passes 50%, or a chat starts low). A delta on the builders skill.
---
# Emergency efficiency: delta on the builders skill (D3; Feras 2026-10-23)
Everything in `.claude/skills/builders/SKILL.md` applies; this only tightens it.

## Claude's budget
- ONE director chat, no Claude side sessions. At most 2 Haiku subagents, only for jobs that read > ~20k tokens.
  This overrides the normal routing (docs/WORKFLOW.md, Start here step 3: Opus child chats and subagents, as many
  as needed; Feras 10-28) while the 5-hour window is past 50%: open no new child chats (let running ones finish their
  unit and /handoff); Haiku subagents only when a job reads > ~20k tokens, until the window resets.
- Hand off at ~100k work tokens or 80% of the 5-hour window, whichever comes first (/handoff, fresh chat).
- Claude reads: the first line of `../game-wt/<task>.result`, `bash tools/slots.sh`, greps of what it must decide,
  and the calibrated lens output (<= 15 lines). Never diffs, logs, test output or whole files.
- One tool batch per step, background waits, no polling. Answers to Feras: a few lines.

## Who does what
- Builders build (caps and models: tools/builders.conf); Claude plans, briefs (TEMPLATE, <= 60 lines) and merges.
- Reviews by the calibrated lens (docs/research/calibration-2026-10.md): the free route first, Haiku low second.
- Builders NEVER merge or push to main. Claude merges with `tools/merge_run.sh` after reading a PASS.

## Safety
- Before a merge round: `git push origin origin/main:refs/heads/backup/main-<YYYYMMDD-HHMM>`; delete backups > 1 week old.
- Sensitive paths (core/save, core/game_state.gd, content registries, tools/check.sh, CLAUDE.md, docs/DECISIONS.md)
  change only in a brief that names them; the lens reads them line by line.
- Local `main` goes stale: every base is `origin/main` after a `git fetch`.
- Art, playtests and deep research go to Feras (Flow, Gemini) with 2-4 options, recommended first.
