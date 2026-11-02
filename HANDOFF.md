# HANDOFF (current state only; ONE queue for every chat; max 60 lines)
Last updated: 2026-11-03 (row 26 Opus-style review done with fixes; Obscura set up; Cloudflare billing parked), Sonnet 5.5 high.
Live state in one command: `bash tools/status.sh` (builders, branches not on main, worktrees, this queue, Open points).

Queue rules (one queue, top row first; Dept, Lane, Open points, builder caps, balance band): docs/queue-rules.md.

## Queue
| # | Task (brief or doc) | Dept | Lane | Who | Status | Blocked by |
|---|---|---|---|---|---|---|
| 3 | M1 brief: real-time Rydan vs 2 guards on the prison roof, combat feel first (VISION M1, CANON 10-27, docs/playtest/2026-10-27.md); it rewrites ARCHITECTURE section 8 | Gameplay | chat (plan) | Opus high | Tue 11-03 | - |
| 26 | Low-cost pipeline v2 (Feras 11-01/02), BUILT and measured in one chat: plan docs/briefs/row26-pipeline-v2-plan.md; the whole workflow lives in .claude/skills/low-cost-pipeline/ (changelog.md holds every result and cost, runs.csv the scoreboard, `python tools/kaizen_report.py` reads it). Left: the writer trial on row 4's first real builds (agy vs cf, with real cost); the review is done (11-03) | Ops | builder + chat (review) | Sonnet high or Opus high (opusplan), cf, agy | built 11-02; trial with row 4's first builds | - |
| 27 | Plan the language server (LSP) for the reviewer agents: probe, verdict, then a brief for Sonnet high (docs/briefs/row27-lsp-reviewers-plan.md) | Ops | chat (plan) | Opus high | queued: dedicated chat | - |
| 4 | M1 build from that brief + the Android export (D17) + archive the turn-based battle code (Feras 10-28), players-eye-gate before Feras | Gameplay | builder | agy | after row 3 | 3 |
| 6 | Bake Roya (sprite-bake), native-scale render on the prison roof, review-player + review-feras | Art | chat (MCP) | Opus high | after row 3 | 3; free memory >= 2 GB |
| 5 | Feras plays M1 on PC and phone; notes -> fix-pass rows | QA | Feras | - | later: after row 4 | 4 |
| 7 | Art batch: Bilqis re-model (v2), guard, props (booth, floodlight, qamariya window, umbrella), icons; title = Flow Omni | Art | chat (MCP) | Opus high | queued; Rodin credits end ~11-17 | 6 |
| 8 | Free image-to-3D proof (rydan_style_v2 to a TRELLIS HF Space; never Blender generate_3d) -> 3d-model skill | Art | chat (MCP) | Opus medium | queued | 7 |
| 9 | Asset preparation pipeline (jpg -> png, sizes, import settings, manifest check) | Art | builder | cf | parked | 5 |
| 10 | Obscura proof: SET UP 11-03 (Obscura 0.2.5 in the main checkout's Obscura folder, git-ignored; tools/obscura.sh + test_obscura.py, routing row). Left: one real builder run fetches a page with it and we judge it against Chrome on a JS-heavy page; no login pages | Ops | builder | cf | parked | 5 |
| 11 | Art bible 2D pass: drop the retired 3D runtime lines (fog, mist, sky, spatial shading, the "2150" title) the personas nearly copied; docs/design/art-bible.md | Art | builder | oc | parked | 5 |
Key: builders are near-free bots (agy = Gemini 3.8 Flash, cf = Cloudflare DeepSeek V4.1 Flash max|none, oc = OpenRouter free lenses); chat (MCP) = a
Claude chat that drives Blender, Flow or Rodin; M1 = the first playable real-time fight, on the prison roof.

## Open points
| Point | Owner | Since |
|---|---|---|
| Bilqis's portraits are now the Neon ones: keep or overturn (archive-cleanup, decisions-log); on hold until further notice (Feras 10-31) | Feras | 10-27 |
| Art homework into inbox/: concept pictures, an empty plate per scene (no characters, HUD or rain), icon art (row 7) | Feras | 10-24 |
| Row 26 review follow-ups DONE 11-02 (decisions-log, changelog.md): watchdog fix, check.sh heartbeat (the real cause of the 5-min kills), runs.csv `?` for cost and summed idle, P6 proven, docs fixed. Still open: (a) usd_est vs Cloudflare's real bill: IGNORED until Feras says (11-03: the dashboard blocks headless browsers with a bot check before any login, --stealth is banned, the API token is inference-only); (b) after the next 5 cf runs read `python tools/kaizen_report.py` for idle (quiet kills should now mean hung or finished), then QUIET_SEC; (c) P6 on a Godot run; (d) agy cost is unmetered; (e) the A/B and model personalities are n=1 | Claude, Feras (a) | 11-02 |
| After merging row 26 to main: `python tools/plugin_prune.py` (dry run, then --apply) once the finished worktrees are removed; 6 kaizen entries remain for live worktrees | Claude | 11-02 |
| Doc graph cleanup (row 27 shipped `tools/doc_graph.py`, DOCMAP.md, check.sh gate): 220 baselined dangling pairs in docs/doc_graph_allow.txt (most are example paths in .agents/archive personas), 30 orphans and 240 overlap lines to merge or delete; bare file names (`models.md`) do not count as references yet | Claude | 11-01 |
| Row 20 leftovers, no row yet (row 24 is done; specs too vague to brief): session_stats dates by entry and a tighter GUARD regex, Gameplay lessons.md + research-queue.md, frame_score blank-line slot; row 3 input: docs/audits/2026-11-02-integrity.md Top 10 (its item 5, test_action_def, is a false positive) | Claude | 11-01 |

## This week (weekly limit resets Sat 16:00 GMT+3)
| Day | Plan |
|---|---|
| Sun 11-01 | Rows 22-25 done on system-v4 (row 25 by Sonnet high; held items in Open points). |
| Mon 11-02 | Row 25 signed off by Opus; the M1 brief early if time allows. |
| Tue 11-03 | M1 brief (row 3); M1 build (row 4) overnight into Wed 11-04 at the earliest; play day moves to when M1 passes its gates. |

## Parked and context
docs/context.md (what is on main, the 3D archive, inbox/retired/ never a source); resume only through a queue row.

## Prompt for the next chat
Start with `claude --model opusplan -w <name>` (a chat started in its own worktree lists skills once), `/effort high`, stay in auto mode, then paste this as one message (Opus: no `/goal`):
`Row 3, Gameplay, Opus high: write the M1 brief; read docs/next-chat.md first and do what it says.` (Feras starts first with a sync chat for his recent worktrees; the row 26 review is done.) (A separate Opus high chat: `Row 27, Ops, Opus high: plan the LSP for the reviewer agents; read docs/briefs/row27-lsp-reviewers-plan.md first and do what it says.`)
