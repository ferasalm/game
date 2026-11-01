# HANDOFF (current state only; ONE queue for every chat; max 60 lines)
Last updated: 2026-11-01 (outside audit of system-v4: stale rules, row 25 brief, base_red launch check), Opus 5.5.
Live state in one command: `bash tools/status.sh` (builders, branches not on main, worktrees, this queue, Open points).

## How this file works (Feras 2026-10-27; departments 10-28; Rank 1 11-01)
- One queue, top row first. A chat edits its own rows (Status, Blocked by) and adds rows for new work it finds.
- Dept: a label (B, Feras 10-28): the skills, persona and reviewer the chat loads (docs/WORKFLOW.md Departments). Long,
  taste, MCP or builder-waiting rows go to an Opus child chat (it writes its own row; Status "child open: <branch>").
- Lane: who does the work inside it: builder (agy, cf, oc) by default; chat = the Opus or Sonnet high chat itself, only for
  taste, MCP (Blender, Flow, Rodin), review or plan, said in brackets; Feras = his move. tools/doc_check.py checks every row.
- Open points: agreed but not done, with its owner; every /handoff closes or carries each line (max 10, doc_check).
- Builders (D1): <= 2 Godot runs + 1 free text run (slots.sh). Briefs: docs/briefs/TEMPLATE.md. Balance band: start
  gear 82.7-89% wins; arc_arm needs an upside.

## Queue
| # | Task (brief or doc) | Dept | Lane | Who | Status | Blocked by |
|---|---|---|---|---|---|---|
| 25 | Opus gate on system-v4: review, hook cutover to the studio plugin, proof runs, coach, merge to main, M1 prompt (docs/briefs/row25-opus-gate.md) | Ops | chat (review) | Opus high | Mon 11-02; always runs | - |
| 26 | Writer trial (Feras 11-01): one real brief to agy medium and cf at max (and default or high), results in docs/runs.csv; merge_run.sh logs each merged worker's findings and fix passes (test first) | Ops | builder + chat (review) | agy, cf; Sonnet high | with row 4's first builds | 25 |
| 3 | M1 brief: real-time Rydan vs 2 guards on the prison roof, combat feel first (VISION M1, CANON 10-27, docs/playtest/2026-10-27.md); it rewrites ARCHITECTURE section 8 | Gameplay | chat (plan) | Opus high | Tue 11-03 | 25 |
| 4 | M1 build from that brief + the Android export (D17) + archive the turn-based battle code (Feras 10-28), players-eye-gate before Feras | Gameplay | builder | agy | after row 3 | 3 |
| 6 | Bake Roya (sprite-bake), native-scale render on the prison roof, review-player + review-feras | Art | chat (MCP) | Opus high | after row 3 | 3; free memory >= 3 GB |
| 5 | Feras plays M1 on PC and phone; notes -> fix-pass rows | QA | Feras | - | later: after row 4 | 4 |
| 7 | Art batch: Bilqis re-model (v2), guard, props (booth, floodlight, qamariya window, umbrella), icons; title = Flow Omni | Art | chat (MCP) | Opus high | queued; Rodin credits end ~11-17 | 6 |
| 8 | Free image-to-3D proof (rydan_style_v2 to a TRELLIS HF Space; never Blender generate_3d) -> 3d-model skill | Art | chat (MCP) | Opus medium | queued | 7 |
| 9 | Asset preparation pipeline (jpg -> png, sizes, import settings, manifest check) | Art | builder | cf | parked | 5 |
| 10 | Obscura proof: builders fetch web pages with the Obscura headless browser instead of Chrome (never --stealth); a tools/ wrapper + test | Ops | builder | cf | parked | 5 |
| 11 | Art bible 2D pass: drop the retired 3D runtime lines (fog, mist, sky, spatial shading, the "2150" title) the personas nearly copied; docs/design/art-bible.md | Art | builder | oc | parked | 5 |
Key: builders are near-free bots (agy = Gemini 3.8 Flash, cf = Cloudflare DeepSeek V4.1 Flash max|none, oc = OpenRouter free lenses); chat (MCP) = a
Claude chat that drives Blender, Flow or Rodin; M1 = the first playable real-time fight, on the prison roof.

## Open points
| Point | Owner | Since |
|---|---|---|
| Bilqis's portraits are now the Neon ones: keep or overturn (archive-cleanup, decisions-log); on hold until further notice (Feras 10-31) | Feras | 10-27 |
| Art homework into inbox/: concept pictures, an empty plate per scene (no characters, HUD or rain), icon art (row 7) | Feras | 10-24 |
| Token trim not done: ~4.9 KB of always-loaded text to move or merge, listed in docs/audits/2026-11-01-token-bleed.md; its CLAUDE.md lines need Feras's OK | Claude | 11-01 |
| Status line wired in .claude/settings.json (row 23 e); its real stdin JSON is not dumped yet: in the first fresh chat open `.check/statusline_raw.json` and confirm the field names (docs-based today) | Claude | 11-01 |
| Row 20 leftovers parked in row 24 (specs too vague to brief): session_stats dates by entry and a tighter GUARD regex, Gameplay lessons.md + research-queue.md, frame_score blank-line slot; row 3 input: docs/audits/2026-11-02-integrity.md Top 10 (its item 5, test_action_def, is a false positive) | Claude | 11-01 |

## This week (weekly limit resets Sat 16:00 GMT+3)
| Day | Plan |
|---|---|
| Sun 11-01 | Rows 22, 23 and 24 done on system-v4. |
| Mon 11-02 | Row 25 (Opus gate). Hard stop 23:59. |
| Tue 11-03 | M1 brief (row 3); M1 build (row 4) overnight into Wed 11-04 at the earliest; play day moves to when M1 passes its gates. |

## Parked and context (resume only through a queue row)
- How we work, for Feras: docs/HOW_WE_WORK.md (the loop diagram, roles, cost rules, the week).
- On main: features/neon/neon_game.tscn (start flow -> Roya cold open -> prison roof -> turn-based map fight -> cable
  line). M1 replaces the turn-based fight (CANON 10-27, real-time). Renders: tools/shot_neon_game.tscn.
- Archive done 10-27: hero code id rydan (save v7), res_graph + guard checks; restore from tag pre-cleanup.
- inbox/retired/ (Feras 10-27) = material he retired: never a reference or source. Story bible: inbox/docs/Neon_Glitch_Story_Bible_Final.docx.
- RPG + menus: after M1, reskin to the new look (the old menu mockups and renders are retired).
- Retired 3D (D20): tag 3d-archive, branch archive/3d, lookup only; old builder branches gemini/*, oc/* kept, worktrees gone.

## Prompt for the next chat
Type `/model opus`, then `/effort high`, stay in auto mode, then paste this as one message (Opus: no `/goal`):
`Row 25, Ops, Opus high: the gate on the system rebuild. Read docs/briefs/row25-opus-gate.md and docs/briefs/system-v3.md (the plan keeps the branch's old name: read system-v3 there as system-v4). Fresh worktree from origin/system-v4 (git worktree add, then EnterWorktree path), merge origin/main, run bash tools/check.sh and read it, then follow the brief's steps tiered (WORKFLOW Protocols: Review), risky hunks yourself. Row 24 left you: docs/audits/2026-11-02-integrity.md (input for row 3; its item 5 is a false positive), GLM-5.3-flash calibrated 9/10 and ON for bulk text digests (models.md), WORKFLOW 13.9 KB with one worker table in the builders skill, doc_check fails on a second worker table and warns on bytes, a Read(**/inbox/retired/**) deny rule added to settings.json, 77 briefs and audits archived, and Feras's 11-01 wish to try cf at max as a writer and log every merged worker is row 26. Builders ran as cf fast (FAIL by the sibling red test), agy (PASS) and agy (BREACH); docs/runs.csv holds them. An outside audit then added tools/base_red.py (a launch on a base with a red tool test the brief does not name is refused), logged Rank 1 in decisions-log from Feras's commit, and updated the row 25 brief: both plugins already load, so the 4 non-safety hooks run twice until your cutover. Workers: builders SKILL.md Who does what; no advisor unasked. End: merge to main, CI green, sync_main.sh, /handoff, and your last message holds the M1 brief prompt (row 3, Opus high). When stuck or refused, ask Feras with AskUserQuestion and a pick.`
