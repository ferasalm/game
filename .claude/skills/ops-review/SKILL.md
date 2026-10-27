---
name: ops-review
description: Every-5-sessions review of how we work: usage trend vs the P1 baseline, lessons, doc warnings, research prompts, idle sessions, one department upgrade. Manual only; run when Feras says "ops-review" or after 5 sessions.
context: fork
agent: Explore
disable-model-invocation: true
---
# Ops review (read-only fork; every 5 sessions)
You are the Explore agent: read and report, write nothing. The parent applies the changes. Output one 15-line report at the end.
Skip yourself (one line "nothing changed") when fewer than 5 sessions passed or no commit landed since the last review.

## Steps
1. **Usage trend.** docs/USAGE.md rows since the last ops-review against the P1 baseline row (start /context cost, window % of
   the last 3 sessions, .result verdict counts, 25-notes-per-build). Also `get_usage` if the parent supplies it. Say better / same / worse per number.
2. **Lessons.** docs/LESSONS.md (max 100 lines; condense back to ~70): list lines to promote (recurring, now a rule or a lint)
   and lines to archive (fixed by a tool, or about retired things). The department lessons.md files (`.claude/skills/*/lessons.md`) too.
3. **Doc warnings.** Run `python tools/doc_check.py`; list each warning with the file it names.
4. **Skill use.** grep transcripts `C:\Users\AUC\.claude\projects\C--dev-game\*.jsonl` for `"skill":"<name>"`: list skills never used
   since the last review (candidates to retire) and briefs that skipped a skill they should have named.
5. **Research prompts (plan section 16).** For each `research-queue.md` under `.claude/skills/*/` with 3 or more questions, or
   any answered since: write one prompt per question. Big question: a Gemini Deep Research prompt for Feras to run. Small lookup:
   opencode + OpenRouter :free or agy. Code or tool question: Cloudflare DeepSeek. **Never Claude.** Results go to
   docs/research/<department>/<date>-<topic>.md, marked unverified; the calibrated reader (Haiku, effort high) digests each to <= 30 lines.
6. **Idle sessions.** `mcp__ccd_session_mgmt__list_sessions`: list sessions idle for days with no open PR (archive candidates;
   the parent asks Feras before archiving).
7. **Department upgrade (one, in rotation).** Order: gameplay, art, ui, market, builders, ops. Pick the next after the one in the
   last report; list 3 concrete upgrades to its skill/card (lessons promoted, a tool added, a failing check made a gate).
8. **Calibration recheck** when docs/research/calibration-2026-10.md names a trigger (OpenRouter free list changed, or the first review).

## Report (<= 15 lines)
trend (3 lines) | lessons to promote/archive | doc_check warnings | unused skills | research prompts written | sessions to archive |
the department upgraded and the 3 changes | what Feras must decide (batched multiple-choice, recommended first).
