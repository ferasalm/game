# Briefing for Feras (one file for you: newest report first, the last 5 kept; every chat updates it at /handoff)
Open it from any chat: `feras/BRIEFING.md` (C:\dev\game\feras\BRIEFING.md after a sync). Claude's own queue is
HANDOFF.md; this file is your view of it. "Open now" is rewritten at every /handoff; below it, reports newest first,
each headed by its date and time (GMT+3): Done | Still open | When | How | Your move vs mine | Checked.

## Open now (Sat 10-31 21:50)
| # | Open item | Status | Checked | Your move? | When |
|---|---|---|---|---|---|
| 1 | Row 3, M1 brief (real-time Rydan vs 2 guards, prison roof) | planned | - | start the next chat (prompt in HANDOFF) | Sun 11-01 |
| 2 | Row 4, M1 build + Android export + archive the turn-based fight | planned | - | no | Mon 11-02 |
| 3 | Row 6, bake Roya and a native-scale roof render | planned | - | no | after row 3 |
| 4 | Row 5, you play M1 on PC and phone | waiting on Feras (later) | - | yes | after row 4 passes its gates |
| 5 | Row 7, art batch (Bilqis v2, guard, props, icons) | queued | - | no | before Rodin credits end ~11-17 |
| 6 | Research prompts: 5 for Gemini Deep Research (feras/research-prompts.md) | waiting on Feras | written, not run | yes: paste them; 1 helps row 6, 2 helps row 5 | before those rows |
| 7 | Cleanup Open point (empty row18-routing folder, b5_tests.log, remote base-xr-salvage) | planned | - | no | a later chat |
| 9 | Row 20, audit leftovers (session_stats dates, lesson caps, Gameplay files, frame_score blank line) | not planned yet | listed | no | after row 5 |
| 11 | Rows 8-11: free image-to-3D, asset pipeline, Obscura, art-bible pass | parked | - | no | after row 5 |
| 12 | OpenRouter key expired, so Nemotron is off | waiting on Feras | 401 read | yes: a new key in opencode, or leave it off | any day |
| 13 | Bilqis's portraits: keep the Neon ones or overturn | waiting on Feras | - | yes | open since 10-27 |
| 14 | Art homework into inbox/: concept pictures, empty plates, icon art | waiting on Feras | - | yes | open since 10-24 |

## Sat 10-31 21:50: your answers applied; correction to the 20:55 report (Opus 5.5)
**Correction:** the 20:55 report called items "waiting on Feras" that I had never asked you about. I had parked them. All were then asked with a pick and are closed below.

**Done (on main):**
- Context rule **done**: the 200-300k hand-off band and emergency mode's ~100k hand-off are retired. A chat finishes its task; only ~85% of the 5-hour window hands off. The hook no longer warns on context; its cache-read note stays, as information.
- New rule **done**: stuck or refused means ask you at once with a pick; "waiting on Feras" only for what you were asked in that chat. In CLAUDE.md, the handoff skill, DECISIONS and memory.
- One row part per chat **done**, as scope only, with no size limit.
- 4 and 6 **done**: both files copied to the main checkout with your OK, around the guard once.
- 8 **done**: 9 synced skills off for this repo only, ~2.3k tokens a turn. A fresh /skill-doctor shows them gone.
- 11 **done**: 9 persona agents and 4 unrouted global agents moved to `~/.claude/archive`, ~580 tokens a turn (estimate). Personas still work for builders and as skills.
- 12 **done**: Stop notification, 3 tests. I fired one by hand; I can't see your screen, so tell me if no balloon appeared.
- 13 **done**: RTK declined for the record. Score 9/10; the gap left is a project-aware plugin.

**Not planned:** 9 connectors, dropped on measure. Blender, hyper3d, Chrome and OpenRouter load on demand, so turning them off saves only their names. The 20.4k is real but is mostly app tools. My first-run proposal aimed at the wrong tools.

**Still open:** nothing from the coach audit. The cleanup Open point stays with Claude.

**When:** row 3 on Sun 11-01. **How:** Gameplay, chat (plan), Opus high. **Your move:** start the next chat with the HANDOFF prompt, or tell me to.

**Checked:** check.sh passed (582 tests) before the last merge; the non-Godot check passed after it; both read. Hook, persona and doc tests ran and were read. **Not checked:** the balloon on your screen; whether fewer tokens a turn holds across real chats; the app's origin check was gone around once with your OK and returns for the next merge of protected files (Help > Troubleshooting > Review Pinned Git Origins clears it).

## Sat 10-31 20:55: coach audit finished (Opus 5.5)
**Done (on main):**
- Coach record **done**: the 10-31 run was partial, not full, and nobody had declined the optimization. `.claude/coach-history.md` now says so. All 8 checklists are read.
- heredoc_guard **done**: the Bash tool turns every doubled backslash into one, anywhere in a command. The guard missed 3 python forms and named the wrong cause. It now blocks a doubled backslash anywhere and every python heredoc form holding a backslash. 5 tests pass; a live probe was refused and a clean heredoc still ran.
- Your picks: 1 stale memories **done**; 2 DECISIONS skillOverrides line **done**; 3 three more name-only skills **done**; 5 Edit and Write denied on `*.import`, `*.uid` **done**.
- Deep CLAUDE.md optimization **done**, the first ever: 80 -> 76 lines, 6,972 -> 6,340 bytes. Only text that also lives elsewhere was cut, and no rule dropped. The list is in coach-history.

**Still open:**
- 4 and 6 **waiting on Feras**: applied in the worktree only, because the guard refuses a chat's edits to the main checkout. Both files are git-ignored, so a merge cannot carry them. The live log hook runs the main copy, so 6 has no effect until you copy it.
- 8 synced skills off (~2.3k tokens a turn), 9 connectors off, 10 one row part a chat, 11 archive agents (~750), 12 Stop hook **waiting on Feras**.
- 13 RTK, GDScript LSP, Context7 **not planned**. If you decline RTK yourself the score gains a point.
- Cleanup Open point (Claude) **carried**.

**When:** the copy, any day. The rest are yours to take or leave. **How:** Ops; both are HANDOFF Open points.

**Your move vs mine:** run these two commands; mine is row 3 on Sun 11-01 (start the next chat).
```
cp C:/dev/game/.claude/worktrees/blissful-meninsky-3a269f/.claude/settings.local.json C:/dev/game/.claude/settings.local.json
cp C:/dev/game/.claude/worktrees/blissful-meninsky-3a269f/.claude/hooks/track_usage.py C:/dev/game/.claude/hooks/track_usage.py
```

**Checked:** check.sh passed (582 tests); read before the merge. The hook tests and doc_check ran and were read. track_usage smoke on a throwaway home passed. **Not checked:** builder use of personas beyond briefs; 7,077 undated old tool calls; whether turning off synced skills affects your other projects; whether 20.4k MCP counts deferred tools; the backslash collapse on any other machine; review-feras did not run on this report. A hook fix cannot prove every future form is caught.

## Sat 10-31 20:06: row 18, last system pass (Opus 5.5 high)
**Done (on main):**
- Check speed **done**. Full `check.sh`: ~14 min -> **7 min 23 s** (47% less). With tools/ unchanged, **2 min 20 s** (83% less): the 2 slow tests skip and it says `cached:`. CI always runs all.
- xr-salvage **done**: a review with one bad line now keeps its good lines. check-parallel **done**: tool tests side by side, seconds per step.
- Flaky test **done**: the watchdog test failed 2 runs in 6. Going serial did not cure it. Cause: the fake builder's git setup could outlast the test's 3 s. Fixed at the cause, no limit changed. Since then 3 of 3 whole runs and 16 of 16 under load.
- Cross-review keep or drop **done: kept**. 6 real bugs in 5 runs = 1.2 a run, rule was < 1. Close call: 4 bugs in code, 2 in tests. Counting code alone it is 0.8, which would drop it. I counted test bugs because they let broken code pass. It cost one wasted paid round before the parser fix, and I missed all 3 of its check-parallel finds myself.
- Research **done**: answered lines removed, 2 web lookups by agy in docs/research/art/ (Quaternius looks best for base bodies; marked unverified), 5 prompts in feras/research-prompts.md.
- Audits **done**: coach full, ops-review, /skill-doctor and /insights both work through `claude -p`. Of the 44 guard refusals, 35 were one rule (chained Bash in a worktree), already in CLAUDE.md, 5 were false counts.
**Still open:** items 6 and 8-10 above. **Not planned:** RTK output filter (it hides check output), a wrap-up status hook.
**My errors:** I cut a paid review round short and asked for a process kill, refused, so that child ran to its own timeout. My first fix for the flaky test was the wrong one. I also changed a 12-line limit that a test pins, then reverted it.
**When:** M1 brief Sun 11-01; the system pass is finished. **How:** row 3 (Gameplay, chat plan, Opus high).
**Your move:** start the next chat; say yes or no to item 8; paste research prompts 1 and 2 first. **Mine:** the rest.
**Checked:** full `check.sh` all passed (582 Godot tests) and read, run twice; `test_tool_tests` 13 tests, 6 bad-case probes all caught; pipeline and py_runs repeated; check-parallel and xr-salvage cross-reviewed and read. Final check passed on the merged code; CI green on main (14e8957, 5 min 30 s). **Not run:** review-feras (no render, only this report and the prompts). `merge_run.sh` itself: the 3 runs merged by hand first so the fixes went in together, then one full check. Licences: Quaternius read, Kenney's page gave nothing to grep, so it stays unverified.

## Sat 10-31 18:45: row 19 and your open items (Opus 5.5 high)
**Your questions:** `cf` = yes: DeepSeek V4.1 Flash 1017 on Cloudflare (`@cf/deepseek-ai/deepseek-v4.1-flash-1017`) at max; `cf fast` = the same
model with no reasoning. **Rust: no.** check.sh's own work is ~2 s. Of ~14 min, 11-12 min is Python tests that start bash and git thousands of
times, one test at a time, on 8 cores (484 s in one file). Rust would need a rewrite of the whole pipeline to touch that. Sizes are from old logs, one run each.
**Done (on main):**
- Row 19 **done** but CLAUDE.md: routing, Claude model rules, pipeline rules, today's decisions in DECISIONS and the log; one stale memory line fixed.
- Vision **done**: your OK logged, Art clock line updated, Open point closed.
- Nemotron **done**: every call capped at 5 min, tested; the run goes on without it. The capped probe found the OpenRouter key expired (401 in 1.3 s).
  The frame-score backup lens died on that same error. It does not prove the older hang: a tiny prompt had answered earlier that day.
- Worktrees **in progress**: row18c-gaps and row19-cleanup are now removed too, branches kept. row18-routing left an empty 8 KB folder (cleanup Open point).

**In progress:** 2 agy runs, launched ~18:20, gated in the next chat: xr-salvage (item 9) and check-parallel. The skip for game builds comes after them.
**Moved to the next chat (planned):** research prompts, keep-or-drop, CLAUDE.md, every audit. This chat reached the 250k band; a fresh chat is cheaper for those. /skill-doctor and /insights
are not in this app's skill list: tried there first, else you run them in a `claude` terminal.
**My error:** I sized this chat's reading badly: the plan alone took it from 108k to 219k, so the audits slipped a day.
**When:** Sun 11-01, then M1 brief the same day. I recommend this be the last system pass: no game work since 10-27.
**How:** row 18 (Ops, chat review, Opus high). **Your move:** start the next chat; renew the OpenRouter key if you want Nemotron. **Mine:** the rest.
**Checked:** `check.sh --no-godot` all passed, read; test_cross_review_sh 7 tests including the new cap test; the 401 read from the raw reply. **Not run:** Godot checks (no game code changed), review-feras (no render, only this report), the before-and-after check timing (needs the 2 runs merged). The speed figures are from old logs, and the ~4 min target is an estimate.

## Sat 10-31 10:00: row 18 parts (c) and (d) (Opus 5.5 high)
**Done (on main):**
- Part (c) pipeline gaps, each with a test: the map refreshes before each check; builders are told to commit before their first check and keep it in the foreground; a check moved to the background is killed after 5 min and its work checked; fork failures are named in the result; cf_probe flags a cut stream; slots counts token lines ($0.24 this month + 25 runs with no token count).
- Why the fast builder never committed: the build died at its first check (fork failure at ~600 MB free, before any commit); fix pass 1 then polled its own background check until the 25-min kill.
- [DONE]: direct cf streams are cut at none and at max (max returned nothing); opencode builds are not hit (fast and max whole reply).
- agy medium's first gated build (frame-score, Python): PASS, no fix pass, two own commits. Reviews then found real edge cases; one agy fix pass, PASS, merged.
- Part (c) calibrations (`.claude/skills/builders/models.md`): Clef-flash 12/12 vs review-player on colour and character visible, 3/6 on text; GLM-5.3-flash 11/12 and 2/6; Jev exists, needs no key, 8/8 on easy error lines.
- Review head to head on that diff: cf max best (but rejected on format), Haiku medium and low good, GLM real but few, DeepSeek no-reasoning weak.
- Part (d): you OKed the routing with limits; logged; `generate_patch` now runs with no reasoning. PC restart Open point closed; routing Open point closed.

**Still open:** the items in Open now. Nemotron 3.5 Super VL: no result (not planned). DECISIONS, CLAUDE.md and memory are left to the cleanup chat, as you said.
**When:** cleanup Sat 10-31 after 16:00; ops-review and M1 brief Sun 11-01; M1 build Mon 11-02.
**How:** row 19 (Ops, chat, Opus high), then row 18's ops-review, then row 3.
**Your move vs mine:** yours: start the cleanup chat after 16:00. Mine: everything else on the list above with "no" under Your move.
**Checked:** `check.sh --no-godot` all passed on the merged code; CI on main went red once (my new tests needed a git identity the runner lacks), fixed, green on 747d2b8; pipeline 19 tests, slots 13, cf_probe stream 3, cf_mcp ok; every review input run against the fixed scorer. Godot checks not run: no game code changed. Samples are small: 6 frames, 8 easy lines, 1 diff. Cross-review reads INVALID (format); I read its findings myself. The new background kill is tested on a stub only, no real builder has hit it.
