# HANDOFF (current state only; ONE queue for every chat; max 60 lines)
Last updated: 2026-10-31 (row 18c, d done), Opus 5.5.
Live state in one command: `bash tools/status.sh` (builders, branches not on main, worktrees, this queue, Open points).

## How this file works (Feras 2026-10-27; departments 10-28)
- One queue, top row first. A chat edits its own rows (Status, Blocked by) and adds rows for new work it finds.
- Dept: a label (B, Feras 10-28): the skills, persona and reviewer the chat loads (docs/WORKFLOW.md Departments). Long,
  taste, MCP or builder-waiting rows go to an Opus child chat (it writes its own row; Status "child open: <branch>").
- Lane: who does the work inside it: builder (agy, cf, oc) by default; chat = the Opus chat itself, only for taste, MCP
  (Blender, Flow, Rodin), review or plan, said in brackets; Feras = his move. tools/doc_check.py checks every row.
- Open points: agreed but not done, with its owner; every /handoff closes or carries each line (max 10, doc_check).
- Builders (D1): <= 2 Godot runs + 1 free text run (slots.sh). Briefs: docs/briefs/TEMPLATE.md. Balance band: start
  gear 82.7-89% wins; arc_arm needs an upside.

## Queue
| # | Task (brief or doc) | Dept | Lane | Who | Status | Blocked by |
|---|---|---|---|---|---|---|
| 19 | Cleanup chat: DECISIONS for the routing OK and pipeline rules, CLAUDE.md, memory | Ops | chat (review) | Opus high | Sat 10-31 after 16:00 | - |
| 18 | System pass before M1: (a), (b) done; (c) done 10-31: map refresh, commit-first, foreground check, [DONE] detection, slots spend, agy medium's first gated build, GLM, Clef, Jev (models.md); (d) routing OKed with limits; left: ops-review | Ops | builder | agy, cf; Opus gates | Sun 11-01 | 19 |
| 3 | M1 brief: real-time Rydan vs 2 guards on the prison roof, combat feel first (VISION M1, CANON 10-27, docs/playtest/2026-10-27.md); it rewrites ARCHITECTURE section 8 | Gameplay | chat (plan) | Opus high | later: after row 18 + routing OK (Feras 10-30) | - |
| 4 | M1 build from that brief + the Android export (D17) + archive the turn-based battle code (Feras 10-28), players-eye-gate before Feras | Gameplay | builder | agy | later: after row 18 + routing OK (Feras 10-30) | 3 |
| 6 | Bake Roya (sprite-bake), native-scale render on the prison roof, review-player + review-feras | Art | chat (MCP) | Opus high | later: after row 18 + routing OK (Feras 10-30) | 3; free memory >= 3 GB |
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
| cross_review.py rejects a whole review on one line with no `->`: keep the valid lines | Claude | 10-31 |
| OK on the vision (docs/VISION.md) | Feras | 10-27 |
| Bilqis's portraits are now the Neon ones: keep or overturn (archive-cleanup, decisions-log) | Feras | 10-27 |
| Old worktree folders (coach-cleanup, row12-*, row16-process, ...): check each is merged, then clean up (ccd clean_up_worktrees) | Claude | 10-30 |
| Cross-review keep or drop: 3 of 5 measured live runs (row16-docs INVALID; frame-score format INVALID, findings real); decide at 5 (< 1 real bug a run = drop) | Claude | 10-29 |
| Art homework into inbox/: concept pictures, an empty plate per scene (no characters, HUD or rain), icon art (row 7) | Feras | 10-24 |

## This week (Claude Pro weekly limit: ~90% used Thu 10-29, resets Sat 10-31 13:00 UTC = 16:00 Feras's time (GMT+3); on his calendar)
| Day | Plan |
|---|---|
| Sat 10-31 | Limit resets 16:00: cleanup chat (row 19). |
| Sun 11-01 | /kaizen:coach (ops-review); then M1 brief (row 3). |
| Mon 11-02 | M1 build (row 4) overnight from Sun; play day moves to when M1 passes its gates. |

## Parked and context (resume only through a queue row)
- How we work, for Feras: docs/HOW_WE_WORK.md (the loop diagram, roles, cost rules, the week).
- On main: features/neon/neon_game.tscn (start flow -> Roya cold open -> prison roof -> turn-based map fight -> cable
  line). M1 replaces the turn-based fight (CANON 10-27, real-time). Renders: tools/shot_neon_game.tscn.
- Archive done 10-27: hero code id rydan (save v7), res_graph + guard checks; restore from tag pre-cleanup.
- inbox/retired/ (Feras 10-27) = material he retired: never a reference or source. Story bible: inbox/docs/Neon_Glitch_Story_Bible_Final.docx.
- RPG + menus: after M1, reskin to the new look (the old menu mockups and renders are retired).
- Retired 3D (D20): tag 3d-archive, branch archive/3d, lookup only; old builder branches gemini/*, oc/* kept, worktrees gone.

## Prompt for the next chat
`Continue ferasalm/game on main, Opus high, after 16:00. Read HANDOFF.md. Do row 19 only; /handoff.`
