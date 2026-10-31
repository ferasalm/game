# Briefing for Feras (one file for you: newest report first, the last 5 kept; every chat updates it at /handoff)
Open it from any chat: `feras/BRIEFING.md` (C:\dev\game\feras\BRIEFING.md after a sync). Claude's own queue is
HANDOFF.md; this file is your view of it. "Open now" is rewritten at every /handoff; below it, reports newest first,
each headed by its date and time (GMT+3): Done | Still open | When | How | Your move vs mine | Checked.

## Open now (Sat 10-31 20:06)
| # | Open item | Status | Checked | Your move? | When |
|---|---|---|---|---|---|
| 1 | Row 3, M1 brief (real-time Rydan vs 2 guards, prison roof) | planned | - | start the next chat (prompt in HANDOFF) | Sun 11-01 |
| 2 | Row 4, M1 build + Android export + archive the turn-based fight | planned | - | no | Mon 11-02 |
| 3 | Row 6, bake Roya and a native-scale roof render | planned | - | no | after row 3 |
| 4 | Row 5, you play M1 on PC and phone | waiting on Feras (later) | - | yes | after row 4 passes its gates |
| 5 | Row 7, art batch (Bilqis v2, guard, props, icons) | queued | - | no | before Rodin credits end ~11-17 |
| 6 | Research prompts: 5 for Gemini Deep Research (feras/research-prompts.md) | waiting on Feras | written, not run | yes: paste them; 1 helps row 6, 2 helps row 5 | before those rows |
| 7 | CLAUDE.md rule from /insights: "pause or stop = halt, one-line status; answer a direct question first" | waiting on Feras | read in the report | yes: OK or no (at the 80-line cap, so a line must go) | any day |
| 8 | 22 skills never used add ~3k tokens a turn (/skill-doctor) | waiting on Feras | read | yes: turn off in /skills, or leave | any day |
| 9 | Row 20, audit leftovers (session_stats dates, lesson caps, Gameplay files, frame_score blank line) | not planned yet | listed | no | after row 5 |
| 10 | Worktrees row19-cleanup and row18c-gaps | planned | - | no | next chat, when their chats are closed |
| 11 | Rows 8-11: free image-to-3D, asset pipeline, Obscura, art-bible pass | parked | - | no | after row 5 |
| 12 | OpenRouter key expired, so Nemotron is off | waiting on Feras | 401 read | yes: a new key in opencode, or leave it off | any day |
| 13 | Bilqis's portraits: keep the Neon ones or overturn | waiting on Feras | - | yes | open since 10-27 |
| 14 | Art homework into inbox/: concept pictures, empty plates, icon art | waiting on Feras | - | yes | open since 10-24 |

## Sat 10-31 20:06: row 18, last system pass (Opus 5.5 high)
**Done (on main):**
- Check speed **done**. Full `check.sh`: ~14 min -> **7 min 23 s** (47% less). With tools/ unchanged, **2 min 20 s** (83% less): the 2 slow tests skip and it says `cached:`. CI always runs all.
- xr-salvage **done**: a review with one bad line now keeps its good lines. check-parallel **done**: tool tests side by side, seconds per step.
- Flaky test **done**: the watchdog test failed 2 runs in 6. Going serial did not cure it. Cause: the fake builder's git setup could outlast the test's 3 s. Fixed at the cause, no limit changed. Since then 3 of 3 whole runs and 16 of 16 under load.
- Cross-review keep or drop **done: kept**. 6 real bugs in 5 runs = 1.2 a run, rule was < 1. Close call: 4 bugs in code, 2 in tests. Counting code alone it is 0.8, which would drop it. I counted test bugs because they let broken code pass. It cost one wasted paid round before the parser fix, and I missed all 3 of its check-parallel finds myself.
- Research **done**: answered lines removed, 2 web lookups by agy in docs/research/art/ (Quaternius looks best for base bodies; marked unverified), 5 prompts in feras/research-prompts.md.
- Audits **done**: coach full, ops-review, /skill-doctor and /insights both work through `claude -p`. Of the 44 guard refusals, 35 were one rule (chained Bash in a worktree), already in CLAUDE.md, 5 were false counts.
**Still open:** items 6-10 above. **Not planned:** RTK output filter (it hides check output), a wrap-up status hook.
**My errors:** I cut a paid review round short and asked for a process kill, refused, so that child ran to its own timeout. My first fix for the flaky test was the wrong one. I also changed a 12-line limit that a test pins, then reverted it.
**When:** M1 brief Sun 11-01; the system pass is finished. **How:** row 3 (Gameplay, chat plan, Opus high).
**Your move:** start the next chat; say yes or no to items 7 and 8; paste research prompts 1 and 2 first. **Mine:** the rest.
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
- Worktrees **in progress**: 15 of 17 removed, branches kept. row18c-gaps is locked by its idle chat; row18-routing left an empty 8 KB folder.

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

## Sat 10-31 04:40: builder roles, row 18 parts (b) and (c) (Opus 5.5 high)
(a) opencode v2 **done** 10-30. (b) config **done**. (c) calibrations **in progress**. (d) your routing OK **waiting on Feras**.
**Measured (same 16-field Def task, one sample each, Cloudflare):**
| Model | Time | Tokens out | Result |
|---|---|---|---|
| DeepSeek, no reasoning, bare prompt | 6.7 s | 1.5k | 3 real flaws |
| DeepSeek, no reasoning, rules + repo examples | 12 s | 2.6k | 1 flaw left, flagged the house pattern itself |
| DeepSeek, max, bare prompt | 167 s | 28.3k | typing right, JSON flaw kept |
| GLM-5.3-flash, default, bare prompt | 813 s | 44k | not reviewed |
**Done (on main):** agy on medium; `cf_build.sh <task> <brief> <base> fast` (no reasoning, any failed check moves to max); `Pattern:`
lines in briefs paste real repo files into the prompt; task skills from .claude/skills reach builders too; Sonnet only at high, Haiku
never orchestrates; tools/cf_probe.py and tools/session_stats.py; a JSON trap in the code rules.
**Your table:** DeepSeek's two roles adopted. Gemini gets discovery and stays the main Godot builder (the only one with clean gated
runs; DeepSeek has a BREACH on record). GLM's CLI role left out: scripts run check, gate and merge, so no model is needed there. GLM's
vision role waits on real frames. Its "fast TTFT" did not hold on code: first text at 763 s.
**Real speed gain:** huge per call, less per build, because Godot checks take the same time. One real build measures it.
**My errors:** ran DeepSeek at default and low unasked; assumed GLM-5.3-flash had effort levels; 4 calls crashed on my log path bug.
~$0.2 on cf (estimate; 4 crashed calls unlogged). The `low` run, unasked, was the only one with context to catch the JSON trap: one sample.
**Quality trend (session_stats):** failed calls are not rising (1.9%, then 0.9% on 10-30). Calls per user turn went ~11 -> ~33, guard refusals
4 -> 44 a day, most chats pass 200k. Logic mistakes are not measured. Whether the model itself changed: unknown.
**Non-reasoning tests, Sat 06:40 (one sample each):** sorting 8/8 in 0.44 s; code question right in 0.56 s (clumsy one-liner); diagnosed patch right
in 1.0 s; real Python build: correct code in ~1 min, gate PASS, cross-review 0 findings, merged. End to end it took 57 min: checks ~11 min each on this
PC, plus a max fix pass over a stale map that idled 25 min. Hazard: on Cloudflare a reply stops silently at the literal text `[DONE]`.
Cross-review at non-reasoning: not tested, by my choice: builder time is free, a review costs ~$0.08, and it would muddy the keep-or-drop count.
**When / How:** row 18(c) rest, Sat 10-31 16:00 (Ops, builders agy and cf, Opus gates). **Your move:** restart the PC before then; routing OK Sun.
**Checked:** check.sh without Godot, pipeline tests (15), cf_probe and session_stats tests, a real `fast` build, cross-review. **Not run:** Godot tests
(no Godot file changed; memory under the floor), review-feras (weekly limit at 96%).

## Fri 10-30 03:45: opencode v2, row 18 part (a) (Opus 5.5)
Row 18 has four parts: (a) move opencode to v2 [**done**, below]; (b) write its config in v2's own format [planned,
Sat]; (c) calibrate the cheap models [planned, Sat-Sun]; (d) your routing OK [waiting on you, Sun]. Items 1-4 above say what each holds.
**(a) Done (on main):** your exe (opencode 2.2.2, validly signed by Anomaly Innovations, opencode's maker) is installed next to
v1 at ~/.local/opt/opencode-2.2.2 and pinned (auto-update off). Builders and cross-review now run it. I tested it in a throwaway repo first. Five v2 breaks found, all fixed with tests:
1. `run` used a shared background service, which ignored each run's config, hid quota errors and outlived timeouts. Fix: `--standalone`.
2. The log level must be lowercase.
3. A new `execute` tool let the read-only reviewer run commands and fetch a web page. Fix: denied.
4. The 384k output-cap variable is gone. Fix: set on the model instead.
5. v2 converts any database it opens. Fix: v2 gets its own data dir.
No hangs: an "ask" (reading .env) is auto-rejected, outside-folder reads are denied, and pipes run. A spent free quota
now exits 1 (v1 exited 0). Every call stays under run_limited. No plugins to port.
**Side effect:** an early test converted v1's default data dir (~/.local/share/opencode, interactive use only, no keys).
v1 can't read it now; v2 can. The pipeline's v1 data (oc-cli) still works. A backup is in C:\Users\AUC\oc-v1-backup-2026-10-30.
**Rollback:** one line: `OC_BIN=opencode OC_MAJOR=1` (tools/builders.conf).
**Not confirmed:** that "max" effort reaches DeepSeek on Cloudflare. The config carries it, and a one-word test
used 0 thinking tokens on v1 and v2 alike. That is planned for row 18(c), along with the native v2 config, 18(b).
**When / How:** row 18 (b)-(d), Sat 10-31 16:00, once the weekly limit resets (Ops, builder agy, Opus gates). **Your move:** none for (a).
**Checked:** check.sh without Godot (no Godot file changed), the pipeline (12) and cross-review (6) tests, live
v2 probes. **Not run:** Godot tests, a real builder run on v2 (planned: the first 18(b) run).
