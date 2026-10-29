---
name: handoff
description: End-of-session wrap-up for the game repo. Runs the checks, logs the owner's decisions, curates LESSONS, adds a USAGE row, updates its rows of the HANDOFF.md queue, commits and pushes. Use when the user types /handoff, says "wrap up", or the chat passes ~250k context at a unit boundary (get_usage; the 200k hook line only means finish the unit).
---

# Handoff (game)

HANDOFF, DECISIONS and LESSONS load at every session start, so every line costs tokens in every future chat.

1. **Check.** `tools/check.sh` must end with "all checks passed"; read and fix any FAIL lines first.
   New or moved files: `git add` them, then `python tools/map.py` (the docs check fails on a stale map).
2. **Decisions.** Each decision the owner made this session: one dated line appended to docs/decisions-log.md
   (`- YYYY-MM-DD | decision | why | by`), with his words where short; never delete or reword a log line. Then
   update docs/DECISIONS.md (the loaded rules in force): edit or add the one line the decision changes.
3. **Lessons.** Anything that cost real time (an error, a wrong guess, nearly asking the owner for something you
   could do): symptom -> cause -> fix, dated, verified only. Merge with similar entries; fix or delete wrong ones.
   Max 100 lines: condense back to ~70 when it gets there (owner, 2026-10-22).
4. **Usage.** One row in docs/USAGE.md: date, model (name and raw ID from `get_session` when available), effort,
   each merged run with its Opus fixes and cross-review hits (cost per verified merge, Feras 10-28), any hook/get_usage mismatch,
   task, share of the 5-hour window used if the owner told you (`/usage`), result.
5. **HANDOFF.md**, max 60 lines: one `## Queue` table (# | Task | Dept | Lane | Who | Status | Blocked by), then Open points
   (Point | Owner | Since), This week, Parked and context (Feras 2026-10-27: no per-chat tracks). A /handoff updates its own rows,
   removes its done rows, adds rows for work it found (Dept = a label from the docs/WORKFLOW.md Routing table; lane
   builder with agy/cf/oc by default; `chat (taste|MCP|review|plan)` with Opus and its effort; `Feras`) and the Last
   updated line; tools/doc_check.py checks every row. Then run
   `bash tools/status.sh` and archive the side sessions it started whose work is on main.
   Lean check (Feras 10-28): every non-Opus output merged this session was reviewed tiered (WORKFLOW Protocols:
   Review: gates, a Haiku pass on big diffs, Opus on the list and risky hunks); anything sent to Feras carried a
   review stamp (tools/hooks/review_stamp.py). Name any task an Opus chat did that a cheaper worker could have.
6. **Commit and push.** `tools/check.sh` again, commit (one message saying what changed), `git push -u origin
   <branch>`. Merge into `main` only if the owner gave his standing OK (DECISIONS); then `git push origin HEAD:main`.
   After a push to main, `gh run list --branch main --limit 1`: a red CI run is fixed before the chat ends
   (2026-10-27: main stayed red for 5 pushes because a Windows-only tool test ran on the Linux runner).
   Then sync Feras's checkout (D10, 10-29) with one PowerShell call (the worktree guard refuses `git -C`, and
   PowerShell has no bash on PATH): `Set-Location C:\dev\game; $s = git status --porcelain; if ($s) { "DIRTY: $s" }
   else { & "C:\Program Files\Git\bin\bash.exe" tools/sync_main.sh 2>&1 | Select-Object -Last 3 }`; last line SYNC
   PASS; DIRTY: leave it and name it in the report.
7. **Report.** A department child chat (docs/WORKFLOW.md, Start here) ends with a report of 15 lines or fewer for the
   father (a subagent runs no /handoff: the father writes its row): commits on main, what failed, questions for Feras. The father (or a chat Feras drives) tells the owner in
   five short parts (Feras 10-29): Done (where: branch or main) | Still open | When (a calendar day) | How (the queue
   row: Dept, lane, who) | Your move vs mine | Checked and not checked (each check run and read; what was not run,
   and why). Every HANDOFF Open point is closed (its line removed, said in Done) or carried (its owner still right);
   anything agreed this chat but not done becomes an Open point (point | owner | since; max 10, doc_check). The same report goes at the top of
   feras/BRIEFING.md (his one file; keep the last 5) and the chat names that file. When the plan for the next 3 days changed, update those days' calendar
   events (feras.almekhlaf@gmail.com, all-day, "Your moves today:" lists). New ideas go to docs/ideas.md, not the queue.
