---
name: emergency-efficiency
description: Low-budget mode for the game repo when the Claude limit is tight. Claude only plans and directs; builders (agy, Cloudflare DeepSeek, Inkling, OpenRouter :free) build, merge, test and review on backup-protected branches. Use when the owner says "emergency efficiency", the 5-hour window passes 50%, or a chat starts with little limit left.
---

# Emergency efficiency (Feras, 2026-10-23)
Why: 4 Claude chats at 160-530k context used 50% of the 5-hour window in 30 minutes. Each turn re-reads the whole
context, so long chats and relays between chats are the cost. Rules here override EFFICIENCY.md where they differ.

## 1. Claude's budget
- ONE Claude chat at a time (the director), no Claude side sessions; at most 2 Haiku subagents, and only for jobs
  that read more than about 20k tokens. Everything else goes to builders.
- Hand off at 150k context or 80% of the 5-hour window, whichever comes first (/handoff, then a fresh chat).
- Claude never reads diffs, logs, test output or whole files. It reads: the first line of `../game-wt/<task>.result`,
  the reviewer's `review.md` (at most 30 lines), `bash tools/slots.sh`, and greps of what it must decide.
- One tool batch per step, background waits, no polling, no "still waiting" turns. Answers to Feras: a few lines.

## 2. Builder routing (check `bash tools/slots.sh` first: agy 2, cf 2, oc 1)
| Job | Builder | Why |
|---|---|---|
| Godot code with tests, UI with renders, merges, test runs | agy (Gemini 3.8 Flash; plenty of quota) | strongest at Godot, free |
| Code or scenes when agy is full; review of an agy branch | Cloudflare DeepSeek (`tools/cf_build.sh`; ~$9 left, log in ../game-wt/cf_spend.csv) | 16/16 on the model test, cheap |
| Docs, content JSON, research summaries | opencode Inkling :free | failed two code builds on 2026-10-23 |
| One-shot questions | OpenRouter :free via the MCP (`:free` slugs only) | no slot needed |
| Art, playtests, deep research | Feras (Google Flow, Gemini, ChatGPT summaries) | ask him with 2-4 options |
Every brief: docs/briefs/TEMPLATE.md, <= 60 lines, names one game-dev skill, a Do NOT edit list and a `## Checklist`.

## 3. Branch redundancy (builders may merge, test and review; nothing can be lost)
1. Before a merge round: `git push origin origin/main:refs/heads/backup/main-<YYYYMMDD-HHMM>` (a backup of main).
2. Builders build on `gemini/<task>` or `oc/<task>` (tools/build_pipeline.sh, base `origin/main`).
3. A merger run (agy, a merge brief) merges the PASS branches into `integration/<round>`, runs check.sh (2 test
   slots machine-wide), and writes `review.md`: per branch the gate verdict, checklist misses and test count.
4. A reviewer run on another model (DeepSeek reviews agy's work, agy reviews DeepSeek's) compares the diff with
   each brief and appends PASS or the misses to `review.md`.
5. Claude reads `review.md` only. All PASS: `git push origin integration/<round>:main` (a fast-forward). Any miss:
   a fix brief to the builder. Something broke after a merge: reset main to the backup branch, then re-brief.
6. Sensitive paths (core/save, core/game_state.gd, content registries, tools/check.sh, CLAUDE.md, docs/DECISIONS.md)
   change only in a brief that names them, and the reviewer checks them line by line. Delete backups older than
   a week.

## 4. Sync
- `main` is the only shared branch. Every worktree merges `origin/main` before work and pushes merged work to main.
- Local `main` goes stale (it caused a false BREACH): use `origin/main` as every base; `git fetch` first.
- Remove a worktree and its branch after the merge (tools/merge_run.sh does it).

## 5. Feras in the loop
Playtest milestones on `main` in the editor, screenshots to inbox/, Flow art with a manifest entry, Gemini deep
research summarized before Claude reads it. Each request: 2-4 options, a recommended first one, plain words.
