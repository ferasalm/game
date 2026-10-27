---
name: handoff
description: End-of-session wrap-up for the game repo. Runs the checks, logs the owner's decisions, curates LESSONS, adds a USAGE row, updates its own track's section of HANDOFF.md, commits and pushes. Use when the user types /handoff, says "wrap up", or the chat passes ~100k work tokens (get_usage Messages).
---

# Handoff (game)

HANDOFF, DECISIONS and LESSONS load at every session start, so every line costs tokens in every future chat.

1. **Check.** `tools/check.sh` must end with "all checks passed"; read and fix any FAIL lines first.
   New or moved files: `python3 tools/map.py` (the docs check fails on a stale map).
2. **Decisions.** Each decision the owner made this session: one dated line appended to docs/decisions-log.md
   (`- YYYY-MM-DD | decision | why | by`), with his words where short; never delete or reword a log line. Then
   update docs/DECISIONS.md (the loaded rules in force): edit or add the one line the decision changes.
3. **Lessons.** Anything that cost real time (an error, a wrong guess, nearly asking the owner for something you
   could do): symptom -> cause -> fix, dated, verified only. Merge with similar entries; fix or delete wrong ones.
   Max 100 lines: condense back to ~70 when it gets there (owner, 2026-10-22).
4. **Usage.** One row in docs/USAGE.md: date, model (name and raw ID from `get_session` when available), effort,
   task, share of the 5-hour window used if the owner told you (`/usage`), result.
5. **HANDOFF.md**, max 60 lines. It has a header (Last updated: session, model), then one `## Track: <name>` section per track, each with its owner session, status, waiting on the owner, next steps (each with `Model:` and `Effort:`) and a one-line paste-ready prompt. A /handoff edits only its own track's section plus the Last updated line, never another track's section.
6. **Commit and push.** `tools/check.sh` again, commit (one message saying what changed), `git push -u origin
   <branch>`. Merge into `main` only if the owner gave his standing OK (DECISIONS); then `git push origin HEAD:main`.
   After a push to main, `gh run list --branch main --limit 1`: a red CI run is fixed before the chat ends
   (2026-10-27: main stayed red for 5 pushes because a Windows-only tool test ran on the Linux runner).
7. **Tell the owner** in a few lines: what was done, where it is (branch, main or not), the next step with its
   model and effort, and whether to start a new chat.
