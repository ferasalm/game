# Coach history (kaizen:coach; committed; entries older than 30 days move to coach-history-archive.md)
Last coach run: 2026-10-31, score 7/10, scope full (checklists, usage log, /insights, /skill-doctor, ops-review)
Last deep CLAUDE.md optimization: never (declined for now 10-31: at its cap, 78/80 lines, only one line added)

## 2026-10-31 (full run, row 18)
Setup is strong on enforcement (5 hooks, deny rules, doc caps, tests); the gap is what the setup costs per turn and Claude's habits.
- Done: skip of the 2 slow toy tests; flaky time-limited tests run alone; 44 guard refusals read: 35 were one rule (worktree isolation on
  chained Bash), 5 false positives of session_stats; the rule was already in CLAUDE.md, 16 on 10-31 against 44.
- Proposed: 22 skills never invoked add ~3k tokens a turn (13 claude.ai synced, 8 project, 1 plugin; /skill-doctor): turn off in /skills. Waiting on Feras.
- Done (Feras OK 10-31): CLAUDE.md duty 7, "pause or stop = halt tools, one-line status; answer a direct question first" (/insights:
  the main source of frustration).
- Proposed: RTK output filter: not planned (a filter on check output fights "a check counts only when its output was read").
- Proposed: Stop hook for status tags: not planned (the handoff status rule covers it; revisit if overstated reports recur).
- Open: row 20 (session_stats dates and regex, builders lessons cap, Gameplay queue and lessons files, doc_check byte warning).

## 2026-10-31 (first run; tools/session_stats.py added, it replaces the thin coach log for trends)
Measured, 10-21 to 10-31 (dated by last write): failed calls flat or lower (1.9% -> 0.9% on 10-30), guard refusals up (4 -> 44 a
day), calls per user turn up (~11 -> ~33), most chats past 200k context. Failed calls miss logic mistakes such as out-of-scope runs.
- Done: session_stats.py + test, in the ops-review step; `.claude/coach-history.md` started.
- Proposed: session start costs ~87k before any work (system tools 41k, MCP 20k, prompt 10k, memory 9k, skills 7k): turn off Blender,
  hyper3d and Chrome connectors in Ops and code chats. Waiting on Feras.
- Proposed: one task per chat is broken by most chats (over 200k): a chat holds one queue row part. Waiting on Feras.
- Proposed: smoke call before any batch and a stated run list (memory run-only-what-was-asked): done for Claude.
- Stale: 12 worktrees with nothing beyond main, one (row12-cross-review) with uncommitted changes: Open point, Claude.
