# Opus sign-off on row 25 (a dedicated chat, Opus high; Sonnet ran the gate on 2026-11-01)

Why: CLAUDE.md priority 1 says the gate needs Opus sign-off. Row 25 ran in a Sonnet high chat on Feras's call and was merged to `main` on his OK. This chat signs off or sends back what fails. Nothing here may be re-argued with Feras unless a check fails.

## Read first
- feras/BRIEFING.md, the 2026-11-01 20:10 row 25 section and any later entry (the follow-up chat added: agy lens, base_red fixes, token trim, coach 8/10, smoke card).
- `git log --oneline d4e43e5^..origin/main` (everything since the Sonnet gate began), and docs/archive/briefs/system-v3.md (Verification table).

## Steps (tiered, WORKFLOW Protocols: Review)
1. Fresh worktree from origin/main; `bash tools/check.sh` read to the end; `claude plugin validate --strict` on plugins/studio and plugins/pm.
2. Read the risky hunks yourself, no summary: `.claude/settings.json` (hooks: only pre_spend, review_gate, session-start and statusLine may remain), `plugins/studio/hooks/hooks.json`, `tools/handoff.sh`, `tools/sync_main.sh` (dirty guard), `tools/base_red.py`, `tools/build_pipeline.sh` (base_red call), `tools/merge_run.sh`, `tools/doc_check.py`, and the low-cost-pipeline skill (`.claude/skills/low-cost-pipeline/SKILL.md`, `opencode.json`).
3. Judge the lens results: the false flags in the BRIEFING were rejected on evidence; confirm 3 of them yourself, and confirm no real flag was dropped (DeepSeek max list, GLM list, Haiku list, agy list are in the report).
4. Judge the worker evidence in docs/runs.csv (rows row25-*): are the runs a fair proof of the low-cost pipeline (GLM max tests, DeepSeek low/high hand)? Say what would make the proof stronger.
5. Smoke result: the card "Smoke: skills once, worker call, pm:status" (task_62524e88) is Feras's to start; read its report if run. Skills must list once.
6. Run `/kaizen:coach` yourself (full interactive run) and set the score; the 11-01 score 8/10 came from a Haiku read-only audit.
7. Decide: SIGN OFF (log one line in docs/decisions-log.md), or list what to fix (fix it in a worktree, gate, merge).
8. /handoff with the 6-part report; the next prompt is the M1 brief (row 3).

## Rules
- Stuck or refused: ask Feras with AskUserQuestion, options with a pick. Never `/advisor` unasked. Never a Sonnet subagent.
