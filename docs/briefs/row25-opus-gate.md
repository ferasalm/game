# Row 25: Opus gate on system-v3 (chat brief; plan and verification table: docs/briefs/system-v3.md)
Department: Ops. Model: Opus high. Skills: builders, ops-review. Persona: none. This row always runs, Mon 11-02.
Goal: Opus signs off on what Sonnet built, or sends back what fails; then main gets it and the system is the one we work with from now on.
Read: docs/briefs/system-v3.md, this file, the reports of rows 22-24 in feras/BRIEFING.md on `system-v3`, docs/briefs/row22-probe.md. Grep for the rest.
May edit: anything the fixes need. Commit and merge: yes, after the gate.

## Steps (tiered, WORKFLOW Protocols: Review)
1. `git merge --ff-only origin/system-v3` in a fresh worktree, then merge origin/main. Full `bash tools/check.sh`, read it. `claude plugin validate --strict` on both plugins.
2. Tier 2: Haiku medium lists misses in the whole diff against the 3 briefs' Done lines, and tests removed or weakened. You read that list.
3. Read the risky hunks yourself: `.claude/settings.json`, hook wiring, tools/hooks, handoff.sh, build_pipeline, build_gate, doc_check, sync_personas, anything no test reaches.
4. Prove the new door: one real small builder run from the delegation table, start to gate, not a stub. One fresh Sonnet high chat smoke: skills list once, one worker call, `/pm:status`.
5. Prove the fail-closed gates: pre_spend blocks with `studio` disabled; session-start warns.
6. `/kaizen:coach`: score, and the plugin gap closed. Add to .claude/coach-history.md.
7. Print the verification table, before against measured, with `python tools/session_stats.py`, and docs/runs.csv for quality. A worse quality trend blocks the merge: fix or ask Feras with a pick.
8. review-feras on the report. Merge to main, CI green, sync_main.sh. Archive `system-v3` briefs to docs/archive/briefs/.
9. HANDOFF: rows 22-25 gone, row 3 on top, Prompt for the next chat. Calendar for the next 3 days. /handoff.

## Stop rules
A failure that can't be fixed by the hard stop: leave main as it is, merge only the parts that pass alone (each row's commits are separate), tell Feras what is held and why, and M1 still starts Tue 11-03. Same step failed twice: ask Feras before using the advisor.

## Done when
All steps read and passed, or what is held is named; main green; Feras has the table, the 5-part report and the M1 prompt.

## Carried from row 22 (Feras 11-01)
Cutover: remove heredoc_guard, token_handoff, stop_notify and instructions-loaded from .claude/settings.json (plugins/studio/hooks/hooks.json holds them; tools/test_plugins.py checks the split), add extraKnownMarketplaces neon (path C:/dev/game) and enabledPlugins studio@neon (ask Feras with the exact diff if auto mode refuses), then Feras runs /plugin marketplace add C:/dev/game once and accepts the trust dialog. Proof: a fresh worktree chat on main shows no "plugin studio is not loaded" line, and studio:review-code runs. Skills stayed in .claude/skills (row 22 probe c, d): a fresh session started inside a worktree lists each skill once (row 22 check); row 24 checks whether a chat opened from C:/dev/game then entering a worktree lists them twice.
