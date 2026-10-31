# Coach history (kaizen:coach; committed; entries older than 30 days move to coach-history-archive.md)
Last coach run: 2026-10-31, score 9/10 (7 at the report; Stop hook wired, RTK declined by Feras; the gap left is a project-aware plugin), scope full: all 8 checklists across two runs (row 18 read 3 and part of hooks; the finishing run read the other 5), plus usage log, /insights, /skill-doctor, ops-review
Last deep CLAUDE.md optimization: 2026-10-31, first ever (Feras picked it). An earlier line here said "declined": false, nobody had; it was not put to him before the 10-31 report.

## 2026-10-31 (finishing run: 8 checklists, Phase 4 report in chat; Feras: "Quick wins + optimize")
Score 7/10 (=): fails Stop hook, RTK (not installed, not declined by Feras), project-aware plugin. No regressions (no .bak), no orphan hooks.
- Done (no pick needed): heredoc_guard. Cause: the Bash tool collapses every doubled backslash to one anywhere in a command (probed); the old
  regex missed `python <<X` and `python -I - <<X`, and its message named the wrong cause. Now blocks a doubled backslash anywhere and every
  python heredoc form with a backslash. Single backslashes in python heredocs stay blocked though they arrive intact: a check is not weakened.
- Done (Feras): 1 three stale memories; 2 the DECISIONS skillOverrides line (name-only works); 3 ui-designer, ui-finish-gate-reviewer, market-player
  name-only; 5 Edit/Write deny on *.import and *.uid.
- Done (Feras OK to go around the guard once): 4 drop `Bash(python -)` from settings.local.json; 6 track_usage.py logs file paths, cap 8000/6000; both copied to the main checkout.
- Feras's correction: "waiting on Feras" had parked 4 and 6 and 8-12 without asking. All were then asked with a pick and closed. Rule, duty 3 + CLAUDE.md status line + handoff skill.
- Done (Feras): 7 deep optimization: CLAUDE.md 80 -> 76 lines, 6972 -> 6340 bytes; notes 26877 -> 26247 before this entry's log lines. Cut only
  what lives elsewhere: VISION check (duty 1), Ripple prompt (hook, duty 2), queue and brief rules (HANDOFF, doc_check, test_template), run caps
  and no races (DECISIONS), persona line (WORKFLOW), one-file test (code.md), python name (LESSONS), worker list (WORKFLOW step 3). Scale line moved
  after duty 7. No rule dropped. Self-update skipped (no Context7). Rule file stays at .claude/rules/ root: build_pipeline pastes that path.
- Rules audit: code.md scored 9/10: scoped, directives only; overlap with CLAUDE.md kept because builders read only code.md.
- Done (Feras): 8 nine synced skills off through project skillOverrides (this repo only; a fresh /skill-doctor shows them gone, ~2.3k tokens a turn); 12 Stop
  notification (tools/hooks/stop_notify.py + test); 10 a chat holds one part of a queue row; 11 nine persona agents and 4 unrouted global agents to ~/.claude/archive (~580 tokens a turn).
- Dropped on measure: 9 connectors. The first prompt was 88,392 tokens, so the 20.4k MCP is real, but Blender, hyper3d, Chrome and OpenRouter are deferred (names only): the 20.4k is
  mostly app tools. The first-run proposal aimed at the wrong tools.
- Done (Feras): the 200-300k hand-off band and emergency's ~100k hand-off retired: "hitting 200k is not an excuse to stop working". Context never warns; the cache-read note stays, as information.
- Declined by Feras: 13 RTK. Not planned: GDScript LSP (none found in the marketplaces), Context7.
- Corrections: "never used" is 23 skills, not 22 (13 synced, 8 project, 2 plugin), ~3.3k tokens, of which project ~350. Of the 8 project skills, 4 are named
  in real briefs (godot-gameplay-scripter 30, narrative-designer 2, ui-designer 2, game-audio-engineer 1), 4 in none (godot-shader-developer,
  blender-addon-engineer, ui-finish-gate-reviewer, market-player): routed in WORKFLOW, kept for work not yet reached.

## 2026-10-31 (partial run, row 18; first called "full", which was false)
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
