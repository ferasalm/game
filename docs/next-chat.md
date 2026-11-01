# Next chat: Row 25, Opus high (the gate on system-v4)

Pasted from HANDOFF.md ("Prompt for the next chat"): `/model opus`, `/effort high`, auto mode, then the one-line pointer. Facts below were checked on 2026-11-01 by Haiku 5.5; re-check the commands before acting on them.

## Where it stands
- `system-v4` is at 4f99ce6 and its CI run 41292772433 passed on that commit. `main` is untouched.
- Done since the row 24 push (1c1c604, 102e4c3, 4f99ce6): the audit fixes to stale rules and plugin claims; `tools/base_red.py` (refuses a launch whose base holds a red tool test the brief's Tests section does not name; replayed on row 24's base); `handoff.sh` (refuses a push to main without `--main`; its CI wait reads the pushed commit); `sync_main.sh` (switches to main before pulling); `merge_run.sh --keep`; `cross_review.sh` (first branch found wins); the six-part report; Clef-flash and output-cap model fixes.
- Both plugins already load from `C:/dev/game/plugins`. The 4 non-safety hooks (heredoc_guard, token_handoff, stop_notify, instructions-loaded) therefore run twice until the cutover in step 3.
- Not finished: the token trim (the CLAUDE.md lines need Feras's OK), the full reviewer sweep, the sync_main.sh test, and the real-CI run of `handoff.sh --main`.
- Check first: `git rev-list --left-right --count origin/main...origin/system-v4` must print `0 N` (system-v4 contains main).

## Do first
1. Ask Feras with AskUserQuestion, one question per call:
   a. Approve trimming the CLAUDE.md lines listed in docs/audits/2026-11-01-token-bleed.md (about 0.6 KB)? Recommended: yes, each line keeps a pointer to its docs/DECISIONS.md line. Do not edit CLAUDE.md before this answer.
   b. How to run the reviewer sweep? Recommended: a cf-only sweep of rules, tools and calibration logs (about $0.03 a pass, almost no Claude tokens). Seven Opus reviewers cost far more and were cancelled for budget.
2. Read docs/briefs/row25-opus-gate.md and run its steps, tiered (WORKFLOW Protocols: Review). Work in a fresh worktree from origin/system-v4; where the brief says system-v3, read system-v4.
3. Cutover, as the last commit before the merge: remove heredoc_guard, token_handoff, stop_notify and instructions-loaded from `.claude/settings.json`; keep the safety hooks there. Then read `tools/test_plugins.py` and make it fail if those 4 come back to settings.json (check what it asserts today first).
4. Test the sync_main.sh branch switch. No test exists yet; grep tools/ first, then write it red and make it pass.
5. Real CI for `handoff.sh --main`: it pushes to main, which the standing OK in docs/DECISIONS.md allows at session end. If you test before that point, use the HANDOFF_CI stub on a throwaway branch.
6. Re-run the calibration and pipeline sweeps across all of tools/ with cf only. This chat's cf outputs sit in a session scratchpad, not the repo; their fixes are in 4f99ce6.
7. `/handoff`, then the 6-part report into feras/BRIEFING.md, then the M1 brief prompt for row 3 as your last message.

## Rules
- Stuck or refused: ask Feras with AskUserQuestion, options with a pick. Never `/advisor` unasked. Never a Sonnet subagent.
- Builders are cf and agy: judge their `.result` and gate output, not their summary.
