# HANDOFF (current state only; ONE queue for every chat; max 60 lines)
Last updated: 2026-11-01 (row 22 done: studio plugin, skills fallback taken), Sonnet 5.5.
Live state in one command: `bash tools/status.sh` (builders, branches not on main, worktrees, this queue, Open points).

## How this file works (Feras 2026-10-27; departments 10-28)
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
| 23 | pm plugin, one-call handoff, usage row, run scoreboard, helpers, status line (docs/briefs/row23-pm-handoff.md) | Ops | builder + chat (review) | agy, cf; Sonnet high | next: Sun 11-01, branch system-v3 | - |
| 24 | One home for every rule, tidy, integrity audit, row 20 leftovers, cleanup (docs/briefs/row24-one-home.md) | Ops | builder + chat (review) | agy, cf; Sonnet high | Mon 11-02 | 23 |
| 25 | Opus gate on system-v3: review, hook cutover to the studio plugin, proof runs, coach, merge to main, M1 prompt (docs/briefs/row25-opus-gate.md) | Ops | chat (review) | Opus high | Mon 11-02; always runs | 24 |
| 3 | M1 brief: real-time Rydan vs 2 guards on the prison roof, combat feel first (VISION M1, CANON 10-27, docs/playtest/2026-10-27.md); it rewrites ARCHITECTURE section 8 | Gameplay | chat (plan) | Opus high | Tue 11-03 | 25 |
| 4 | M1 build from that brief + the Android export (D17) + archive the turn-based battle code (Feras 10-28), players-eye-gate before Feras | Gameplay | builder | agy | after row 3 | 3 |
| 6 | Bake Roya (sprite-bake), native-scale render on the prison roof, review-player + review-feras | Art | chat (MCP) | Opus high | after row 3 | 3; free memory >= 3 GB |
| 5 | Feras plays M1 on PC and phone; notes -> fix-pass rows | QA | Feras | - | later: after row 4 | 4 |
| 7 | Art batch: Bilqis re-model (v2), guard, props (booth, floodlight, qamariya window, umbrella), icons; title = Flow Omni | Art | chat (MCP) | Opus high | queued; Rodin credits end ~11-17 | 6 |
| 8 | Free image-to-3D proof (rydan_style_v2 to a TRELLIS HF Space; never Blender generate_3d) -> 3d-model skill | Art | chat (MCP) | Opus medium | queued | 7 |
| 9 | Asset preparation pipeline (jpg -> png, sizes, import settings, manifest check) | Art | builder | cf | parked | 5 |
| 10 | Obscura proof: builders fetch web pages with the Obscura headless browser instead of Chrome (never --stealth); a tools/ wrapper + test | Ops | builder | cf | parked | 5 |
| 11 | Art bible 2D pass: drop the retired 3D runtime lines (fog, mist, sky, spatial shading, the "2150" title) the personas nearly copied; docs/design/art-bible.md | Art | builder | oc | parked | 5 |
Key: builders are free code bots (agy = Gemini Flash, cf = Cloudflare DeepSeek, oc = free text models); chat (MCP) = a
Claude chat that drives Blender, Flow or Rodin; M1 = the first playable real-time fight, on the prison roof.

## Open points
| Point | Owner | Since |
|---|---|---|
| Bilqis's portraits are now the Neon ones: keep or overturn (archive-cleanup, decisions-log); on hold until further notice (Feras 10-31) | Feras | 10-27 |
| Art homework into inbox/: concept pictures, an empty plate per scene (no characters, HUD or rain), icon art (row 7) | Feras | 10-24 |
| Row 25 gate: after the merge to main, run once `/plugin marketplace add C:/dev/game`, accept the trust dialog, enable studio@neon (a plugin loads only from the main checkout) | Feras | 11-01 |
| Cleanup (row 24, part f): .claude/worktrees/ empty row18-routing folder (in use 10-31; retry the delete) and b5_tests.log; base-xr-salvage local and remote; merged remote branches worktree-row12-*, row16-*, row17-*, row18-*, row18c-*, row19-* | Claude | 10-31 |

## This week (weekly limit resets Sat 16:00 GMT+3)
| Day | Plan |
|---|---|
| Sun 11-01 | Row 22 done; row 23 (Sonnet high, one paste). |
| Mon 11-02 | Row 24 (Sonnet high), then row 25 (Opus gate). Hard stop 23:59. |
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
Type `/model sonnet`, then `/effort high`, stay in auto mode, then paste this as one message (`/goal` first; it starts the work itself):
`/goal Row 23 is finished: every Done-when line of docs/briefs/row23-pm-handoff.md is shown true in this chat, or its fallback was taken and reported; nothing was pushed to main; /handoff has run on branch system-v3; and your last message holds the row 24 prompt ready to paste. Or stop after 40 turns with a status report. How: you are Sonnet high in auto mode. Read HANDOFF.md, then that brief and docs/briefs/row22-probe.md, and do row 23 only. Read-only in C:\dev\game; EnterWorktree before the first edit (D10), then git merge --ff-only origin/system-v3, and end with git push origin HEAD:system-v3. Row 22 is merged there: skills stayed in .claude/skills (plugin skills ignore skillOverrides and paths:); the plugin is plugins/studio; its 4 hooks stay wired in settings.json until row 25 (Feras 11-01), so ignore session-start's "plugin studio is not loaded" line; test plugin edits with claude --plugin-dir <worktree>/plugins/studio. Call the workers by the builders skill's Who does what table. Efficiency (Feras 11-01): launch-and-wait for a builder run goes to a fresh Haiku medium subagent with a short template brief and a one-line answer; diff review, confirming cross-review flags, fix rounds and merging stay in this chat; no new fork for work under ~10 calls; no polling, wait for notifications; one parallel batch per step, plain commands, no compound shell or backslashes; WebFetch only with a narrow prompt; run bash tools/check.sh once after the last edit and read the FAIL lines; do not re-read files already in this chat. A cf run merges with merge_run.sh <task> oc, and its cross-review gets the base origin/system-v3. Show each check's result in this chat, because the goal check reads only the chat. When stuck or refused, ask Feras with AskUserQuestion and a pick; never end a turn on a question.`
