# Briefing for Feras (one file for you: newest report first, the last 5 kept; every chat updates it at /handoff)
Open it from any chat: `feras/BRIEFING.md` (C:\dev\game\feras\BRIEFING.md after a sync). Claude's own queue is
HANDOFF.md; this file is your view of it. "Open now" is rewritten at every /handoff; below it, reports newest first,
each headed by its date and time (GMT+3): Done | Still open | When | How | Your move vs mine | Checked.

## Open now (Thu 11-05 06:30)
| # | Open item | Status | Checked | Your move? | When |
|---|---|---|---|---|---|
| 1 | What-we-have pipeline: docs/briefs/row28-pipeline-v3-plan.md | g, d done (11-05); next c, b (tests: docs/briefs/row28-locked-tests/), a, e (meter); i, h, j; f after Feras's research; then row 4 | - | no | g, d done (11-05); next c, b (tests: docs/briefs/row28-locked-tests/), a, e (meter); i, h, j; f after Feras's research; then row 4 |
| 2 | M1 build in 6 waves from docs/briefs/m1-plan.md (9 part brie | ready: wave 1 (m1-defs) on agy; nv/OpenRouter lanes after row 28 | - | no | ready: wave 1 (m1-defs) on agy; nv/OpenRouter lanes after row 28 |
| 3 | Bake Roya (sprite-bake), native-scale render on the prison r | ready | - | no | ready |
| 4 | Feras plays M1 on PC and phone; notes -> fix-pass rows | later: after row 4 | - | yes | later: after row 4 |
| 5 | Art batch: Bilqis re-model (v2), guard, props (booth, floodl | queued; Rodin credits end ~11-17 | - | no | queued; Rodin credits end ~11-17 |
| 6 | Free image-to-3D proof (rydan_style_v2 to a TRELLIS HF Space | queued | - | no | queued |
| 7 | Asset preparation pipeline (jpg -> png, sizes, import settin | parked | - | no | parked |
| 8 | Obscura proof: SET UP 11-03 (Obscura 0.2.5 in the main check | parked | - | no | parked |
| 9 | Art bible 2D pass: drop the retired 3D runtime lines (fog, m | parked | - | no | parked |
| 10 | Bilqis's portraits are now the Neon ones: keep or overturn ( | open | - | yes | 10-27 |
| 11 | OpenRouter key in oc-v2 ($3 limit, valid 30 days, free smoke | open | - | yes | 11-04 |
| 12 | Art homework into inbox/: concept pictures, an empty plate p | open | - | yes | 10-24 |
| 13 | After merging row 26 to main: `python tools/plugin_prune.py` | open | - | no | 11-02 |
| 14 | Revisit LSP for review-code after row 4 (M1 built): rerun th | open | - | no | 11-02 |
| 15 | Doc graph cleanup (row 27 shipped `tools/doc_graph.py`, DOCM | open | - | no | 11-01 |
| 16 | Row 20 leftovers, no row yet (row 24 is done; specs too vagu | open | - | no | 11-01 |
| 17 | Ops review due (13 sessions): first Ops chat after row 28 b, | open | - | no | 11-05 |

## Thu 11-05 06:30: Dia's feedback checked, routing fixes and row 28 part d merged (Opus 5.5 xhigh, one chat)
- Done (main): Dia's 11 claims checked in docs/audits/2026-11-05-dia-review.md (8 true, 2 true with a wrong fix or cause, 1 roughly true); your four picks are logged (decisions-log 11-05) and built. Following pick 2, Cerebras and Groq left the allowlist: your 11-04 "Cerebras stays the 3rd hop" line is struck, and the $4.85 credit idles until part f. Also fixed: routing.md (retired Clef-flash and GLM-5.3 max, red tests given to a builder), copied reviewer maps in WORKFLOW and models.md, review agents at effort low against your 11-04 xhigh rule, opencode's bare default (uncalibrated Inkling, now DeepSeek). New check: test_routing_docs.py. Part d's redo reviewed by Opus and merged.
- Still open (planned): row 28 c, b, then a (revised: paid ids carry rates, the paid hop runs only with PAID_OK), e (now the cost meter), then i, h, j, f, then M1. Reviewer rollback test: on the first Godot agy run (M1 wave 1). Paid DeepSeek smoke on OpenRouter: at part a, needing your per-run OK then. Build-time data: after c and b (5 runs of kaizen_report). Ops review: first Ops chat after b and c (Open point).
- When: row 28 c and b start when you open the next chat (planned Fri 11-06; `pwsh tools\next_chat.ps1`, Opus high).
- How: row 28, Ops, chat (plan), Opus high; agy builds c, b, a, e.
- Your move: nothing waiting on you from this chat; note that review agents at xhigh use more Claude usage per review than at low. Mine: row 28 in order.
- Checked: full check.sh green (582 Godot tests and every tool test; the first run was red on 2 doc_graph lines, fixed); a Haiku review-code (xhigh) pass on the code diff (2 fixes, 2 tests added, 2 points kept with reasons); review-feras on this report (7 notes applied); CI is watched by handoff.sh on this push (result in the chat). Not checked: no builder or paid call ran.

## Wed 11-04 17:40: row 28 night run stopped on a red CI, part d reverted (opusplan, high; the executing model said it was Sonnet 5.5)
- Done (main): part d (the nv_build.sh login preflight) was built and green locally, but main CI failed `MAP.md current` because I committed by hand with the map made before `git add`: reverted at once (4c86be6, CI green). Red tests for parts c and b are written and saved in docs/briefs/row28-locked-tests/, briefs b and c name their exact interfaces. A later handoff commit also went red on MAP.md (a stray log file was listed in it); fixed in the final push.
- Still open: parts d (redo), c, b, a, e of row 28; none built tonight. Part b's `tools/cn_holidays.txt` dates are from memory and unverified (the brief says so).
- When: row 28 next chat, any day (`pwsh tools\next_chat.ps1`); its prompt starts with the d redo.
- How: row 28, Ops, chat (plan), Opus high, then builders c and b in parallel.
- Your move (waiting on Feras): none: the oc-v2 OpenRouter login is done (Feras, 18:30; $3 limit, valid 30 days, renew about 12-04; a free-model smoke call passed). Mine: redo d, then c, b, a, e. Two small fixes are proposed: check.sh warns on untracked files (map.py reads only `git ls-files --cached`), and next_chat.ps1 clears CLAUDE_CODE_CHILD_SESSION (it made this chat's transcript saving off; no usage measure for this chat).
- Checked: Python tests for d (8 new, 6 and 15 old) and check.sh --no-godot green locally; CI of the revert green; not checked: Godot (memory 1.7 GB, below the 2 GB floor; main CI runs it), no builder or paid call ran.

## Wed 11-04 02:30: Cloudflare cleanup done, pipeline v3 queued (Opus 5.5, same chat)
- Done (main): Cloudflare removed from opencode (CLI and desktop share these): the 2 user env vars (yours had not saved), the stored key in opencode's database, both auth.json entries (backups *.bak-20261104). Cerebras kept as the capped fallback; OpenRouter $13 bought, so 1000 free requests a day. Row 28 written: docs/briefs/row28-pipeline-v3-plan.md holds your 11-04 decisions; row 26 closed into it.
- Still open: BLOCKER, the pipeline's opencode folder (oc-v2) has only the OpenRouter key, so nv builds would fail to log in (my smoke tests used the background service, which reads the other folder).
- When: row 28 next chat (planned Wed 11-04 or Thu 11-05); row 4 wave 1 can run on agy meanwhile.
- How: row 28, Ops, chat (plan), Opus high.
- Your move (waiting on Feras): restart the OpenCode desktop app and terminals; log NVIDIA, Cerebras, Groq and Google into oc-v2 (PowerShell line in the plan, section Found). Mine: nothing pending.
- Checked: `auth list --standalone` shows no Cloudflare; doc_check; not checked: a real pipeline build on NVIDIA (blocked by the logins).

## Wed 11-04 01:35: sync, worktree cleanup, Cloudflare retired (Opus 5.5, auto effort, one chat)
- Done (main): main synced (SYNC PASS); 16 finished worktrees removed (branches kept); no unmerged branch held work main lacks. cf lane retired: free `nv` lane (tools/nv_build.sh) = DeepSeek V4.1 Flash on NVIDIA NIM, provider refusals fall back NVIDIA > Zen free > Cerebras > OpenRouter :free; reviews on NVIDIA GLM-5.3-flash; cf_probe, cf_audit, the cf-agents MCP gone (nv_audit.sh does one-shot text); tools/free_providers.txt + a test fail any paid model slug; docs, skills and M1 briefs updated; decision, SPEND line, lesson logged. Calendar: today's event lists your Cloudflare moves.
- Still open: Open point (f), NVIDIA is slow (DeepSeek 439 s on a toy task): watch the first nv builds (planned: row 4 wave 1). Zen free is spent today (the chain skips it in 2 s). Cerebras lists a paid price; on a no-card key it refuses rather than bills.
- When: row 4 wave 1 next chat (Wed 11-04).
- How: row 4, Gameplay, builder lane, nv + agy, Opus high head.
- Your move vs mine: yours (waiting on Feras): ask Cloudflare billing for a waiver of the $32.29, downgrade Workers Paid, delete the API token and the CLOUDFLARE_API_TOKEN and CLOUDFLARE_ACCOUNT_ID user env vars. Mine: nothing pending.
- Checked: live tool-use proof on NVIDIA DeepSeek and GLM, Cerebras and OpenRouter (wrote, ran, committed); every changed tool test run alone (all pass); branch CI full suite green (582 Godot tests). Not checked locally: the full check.sh (killed by Claude Code at 716 MB free; CI ran it instead).

## Tue 11-03 00:30: row 26 review, follow-ups, Obscura (Sonnet 5.5 high, one chat; the prompt said Opus, it ran on Sonnet)
**Done** (on main after this handoff): the optional review of pipeline v2 is finished and SIGNED OFF with fixes. (1) The 5-minute quiet kill was cutting fix passes that had made no commit of their own; fixed with a test. (2) Its real cause: 4 of 6 quiet kills were builders waiting on their own foreground `check.sh`, which prints nothing until a step ends (not "opencode does not exit"); `check.sh` now beats a heartbeat file and the watchdog counts it. (3) `runs.csv`: `cost` is `?` instead of a hard-coded 0, idle minutes are summed over every kill, two 25-minute idle rows corrected. (4) P6 proven: a seeded off-by-one behind 5 green tests was caught by the GLM cross-review (about $0.02). (5) Stale pointers and two stale doc lines fixed. (6) Obscura is set up: `tools/obscura.sh <url> [text|markdown|links]` (never --stealth, http(s) only, timeout), tested, binaries git-ignored, routing row added.
**Still open**: Cloudflare billing vs `usd_est` is parked until you say (the dashboard bot-checks headless browsers before any login, --stealth is banned, the API token is inference-only). Later: read `kaizen_report` after the next 5 cf runs, then QUIET_SEC; P6 on a Godot run; agy cost is unmetered; the GLM-vs-DeepSeek A/B and the model personalities rest on one data point each.
**When**: nothing is waiting on a day; the next chat is your worktree sync, then row 4 (M1 build, wave 1; row 3, the M1 brief, landed from another chat).
**How**: HANDOFF queue row 26 (Ops, builder + chat) is done except the writer trial with row 4's first builds; row 10 (Obscura proof, Ops, cf) is parked behind row 5 with the wrapper already built.
**Your move vs mine**: yours: sync your recent worktrees, then start row 4. Mine: nothing queued from this chat.
**Checked and not checked**: full `bash tools/check.sh` passed three times (582 tests), the new tests were also run against the old scripts and failed there (so they test something); the Obscura wrapper ran once on the real binary (example.com, dash.cloudflare.com) and 6 stub tests pass. Not checked: the Cloudflare bill, a Godot P6 run, Obscura on a JS-heavy page (the row 10 proof).
