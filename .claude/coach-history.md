# Coach history (kaizen:coach; committed; entries older than 30 days move to coach-history-archive.md)
Last coach run: 2026-10-31, score 7/10, scope health (logs only, weekly limit at 94%)
Last deep CLAUDE.md optimization: never (not run: suggest after the weekly reset)

## 2026-10-31 (first run; tools/session_stats.py added, it replaces the thin coach log for trends)
Measured, 10-21 to 10-31 (dated by last write): failed calls flat or lower (1.9% -> 0.9% on 10-30), guard refusals up (4 -> 44 a
day), calls per user turn up (~11 -> ~33), most chats past 200k context. Failed calls miss logic mistakes such as out-of-scope runs.
- Done: session_stats.py + test, in the ops-review step; `.claude/coach-history.md` started.
- Proposed: session start costs ~87k before any work (system tools 41k, MCP 20k, prompt 10k, memory 9k, skills 7k): turn off Blender,
  hyper3d and Chrome connectors in Ops and code chats. Waiting on Feras.
- Proposed: one task per chat is broken by most chats (over 200k): a chat holds one queue row part. Waiting on Feras.
- Proposed: smoke call before any batch and a stated run list (memory run-only-what-was-asked): done for Claude.
- Proposed: 44 guard refusals on 10-30 cost a call each: read which guard, then fix the commonest cause. Planned: next ops-review.
- Stale: 12 worktrees with nothing beyond main, one (row12-cross-review) with uncommitted changes: Open point, Claude.
