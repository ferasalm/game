# Next chat: Row 3, Opus high (the M1 brief)

Paste from HANDOFF.md ("Prompt for the next chat"): `/model opus`, `/effort high`, auto mode, then the one-line pointer.

## Where it stands (2026-11-01)
- System rows 22-25 are done on `system-v4` and merged to `main` only if the row 25 report says so (check `git rev-list --left-right --count origin/main...origin/system-v4`; `0 0` = merged).
- The pipeline for builders is the `low-cost-pipeline` skill (head Sonnet + GLM-5.3 max critic, middle GLM max tests, hand DeepSeek low/high/max or agy medium). Models live in `opencode.json`.
- Row 25 held (Open points): coach score, fresh-chat smoke, real CI for `handoff.sh --main`, the rest of the token trim.

## Do
1. Read docs/VISION.md M1, docs/CANON.md (10-27 real-time), docs/playtest/2026-10-27.md and docs/audits/2026-11-02-integrity.md Top 10.
2. Ask Feras the design questions with AskUserQuestion (2-3 options, one bold, a pick).
3. Write the M1 brief (docs/briefs/TEMPLATE.md), rewrite docs/ARCHITECTURE.md section 8, add red tests first. Then row 4 builds it.

## Rules
- Stuck or refused: ask Feras with AskUserQuestion, options with a pick. Never `/advisor` unasked. A Sonnet subagent only at `high` (Feras 11-02).
