# Briefing for Feras (one file for you: newest report first, the last 5 kept; every chat updates it at /handoff)
Open it from any chat: `feras/BRIEFING.md` (C:\dev\game\feras\BRIEFING.md after a sync). Claude's own queue is
HANDOFF.md; this file is your view of it. "Open now" is rewritten at every /handoff; below it, reports newest first,
each headed by its date and time (GMT+3): Done | Still open | When | How | Your move vs mine | Checked.

## Open now (Sat 10-31 10:00)
| # | Open item | Status | Checked | Your move? | When |
|---|---|---|---|---|---|
| 1 | Row 19, cleanup chat: DECISIONS, CLAUDE.md, memory | planned | - | start it | Sat 10-31 after 16:00 |
| 2 | Ops-review: the 6 department research queues are not sent | in progress | session_stats.py | maybe (a Deep Research prompt) | Sun 11-01 |
| 3 | Row 3, M1 brief (real-time Rydan vs 2 guards, prison roof) | planned | - | no | Sun 11-01 |
| 4 | Row 4, M1 build + Android export + archive the turn-based fight | planned | - | no | Mon 11-02 |
| 5 | Row 6, bake Roya and a native-scale roof render | planned | - | no | after row 3 |
| 6 | Row 5, you play M1 on PC and phone | waiting on Feras (later) | - | yes | after row 4 passes its gates |
| 7 | Row 7, art batch (Bilqis v2, guard, props, icons) | queued | - | no | before Rodin credits end ~11-17 |
| 8 | Rows 8-11: free image-to-3D, asset pipeline, Obscura, art-bible pass | parked | - | no | not planned yet (after row 5) |
| 9 | cross_review.py throws away a whole review on one line with no `->` | planned | seen twice on frame-score | no | next Ops chat |
| 10 | Cross-review keep or drop: 3 of 5 measured runs | in progress | - | no | at 5 runs |
| 11 | Nemotron 3.5 Super VL review: 3 tries hung on the packet, cause not found | not planned | tiny prompt works | no | only if you want it |
| 12 | OK on the vision (docs/VISION.md) | waiting on Feras | - | yes | open since 10-27 |
| 13 | Bilqis's portraits: keep the Neon ones or overturn | waiting on Feras | - | yes | open since 10-27 |
| 14 | Art homework into inbox/: concept pictures, empty plates, icon art | waiting on Feras | - | yes | open since 10-24 |
| 15 | Clean up old worktree folders (check each is merged first) | not planned yet | - | no | no date |

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

## 2026-10-30 (Fri, early): your row 17 follow-ups (Opus 5.5 high), closed
**Done (on main):**
- Bandwidth: git already sends only changes (a sync is KBs; CI runs on GitHub, not your line). The 109 MB is old
  binaries uploaded once. New check: no tracked file > 10 MB, or > 2 MB outside assets/. The bigger cost is AI
  traffic (this chat sent ~60 MB of context), so short fresh chats matter most.
- Cloudflare: no $ cap (spend still logged). DeepSeek 1017 at max effort for reviews and builds, opencode's hidden
  output cap raised to 384k, DeepSeek's full output (that 32k cap broke "high"). Max vs low on the same review: same key bug, less noise, 443 s, ~$0.08.
- Nemotron: backup lens only; Cloudflare DeepSeek now cross-reviews agy runs. agy stays high: proven it's
  Gemini 3.8 Flash's top level (agy refuses max). Cache hook: informs at 25M, never asks for an early wrap-up.
- Kaizen coach session: its commit (ef1b284) is on main; its local-only changes (settings.local.json, memory, the
  usage hook) don't touch git, so no conflict. Its "persona check exits 0 on drift" finding was a misread: that FAIL
  line is the test's own planted case (real drift check passes); now silenced so it can't mislead again.
**Still open:** row 18 calibrations (GLM-5.3-flash on Cloudflare, Clef-flash, Jev), planned Sat 10-31 16:00, then your routing
OK (waiting on Feras after it); the first DeepSeek build at max effort is unwatched until then (planned with row 4); the
coach-cleanup worktree is removed after the kaizen CLI session ends (planned, next chat).
High effort was also measured: a valid review but 900 s, slower than max.
**Later the same night (Feras):** routing OK waits for all of row 18 (waiting on Feras then); M1 moves after the system pass (planned: row 18 Sat, M1 brief Sun at the earliest); opencode v2 upgrade planned in row 18 with a rollback; coach branch deleted (done), old worktree folders checked and cleaned next chat (planned).
**Next chat prompt** (Opus high, after Sat 16:00): "Continue ferasalm/game on main. Read HANDOFF.md. Take the top queue row for your lane; /handoff."
**Checked:** tests (pipeline 12, cross-review 6, token hook 13, file sizes 2, personas 4) and check.sh --no-godot, read.

## 2026-10-30 (Thu night): row 17 models, builders, licences, diagram (Opus 5.5 high), closed
**Done (on main):**
- DeepSeek 1017 fixed (done). Access works on every route. Your long builds never hit the bug because each agent step
  is short. A one-shot review is one long answer: Cloudflare's default "high" thinking filled the whole 32k output
  budget, hidden, with no text (3 of 3 replays). `reasoning_effort: low` fixed it: a valid review in 195 s, ~$0.04.
- The opencode free "hang" (done): opencode's free usage limit is spent ("Free usage limit reached"), and opencode
  hides it (no text, exit 0). Runs now log it and stop at once as "NOWORK quota: rerun on cf", with a test.
- GLM-5.3 (Cloudflare) calibrated (done): same score as nemotron and DeepSeek-low (1 of 2 planted bugs), 3x slower.
  GLM-5.3-flash: Cloudflare answers; opencode free timed out on the spent quota (calibration planned with row 18).
- Your AI-search list (done, partly checked): Clef-flash is real (9B vision yes/no model, ~free). Jev, Clairic, bge-m3:
  agy says real, unchecked. The AA scores are not trustworthy: AA shows DeepSeek V4.1 Flash as "Unknown"; agy wrote 32.
- Licences (done): 13 of 15 rows verified; 2 dead links removed (GDQuest 2D RPG, Quaternius cyberpunk). 3 of 3 spot-checks right.
- Diagram v2 (done): the whole system on one page, your moves in orange:
  https://github.com/ferasalm/game/blob/main/docs/HOW_WE_WORK.md
**Still open:** model routing proposal (waiting on Feras); cross-review keep/drop (in progress: 1 of 5 runs measured);
row 18 Clef + Jev calibration (planned after your OK).
**When:** your OK any day; row 3 M1 brief Sat 10-31 after 16:00 (unchanged).
**How:** row 18 = Ops, builder agy. **Your move:** read the Routing table in .claude/skills/builders/models.md and OK or
change it; subscribing to OpenCode Go is not needed (Cloudflare covers it for cents). **Mine:** M1 brief Saturday.
**Checked:** both test suites (build pipeline 12, cross-review 5) and check.sh --no-godot run and read; the diagram renders
on GitHub; 3 AA + 3 licence facts re-read. Not run: the Godot checks (only docs and Python tools changed; 1.5 GB free memory).
My mistake (fixed): I edited a pipeline script while two runs were using it, so both crashed; I re-gated them, nothing lost.
