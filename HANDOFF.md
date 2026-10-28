# HANDOFF (current state only; ONE queue for every chat; max 60 lines)
Last updated: 2026-10-28 (row 1 closed: item 9, the 10 personas tailored to Neon Glitch, on main), Opus 5.5.
Live state in one command: `bash tools/status.sh` (builders, branches not on main, worktrees, this queue, Feras's list).

## How this file works (Feras 2026-10-27; departments 10-28)
- One queue, top row first. A chat edits its own rows (Status, Blocked by) and adds rows for new work it finds.
- Dept: a label (B, Feras 10-28): the skills, persona and reviewer the chat loads (docs/WORKFLOW.md Departments). Long,
  taste, MCP or builder-waiting rows go to an Opus child chat (it writes its own row; Status "child open: <branch>").
- Lane: who does the work inside it: builder (agy, cf, oc) by default; chat = the Opus chat itself, only for taste, MCP
  (Blender, Flow, Rodin), review or plan, said in brackets; Feras = his move. tools/doc_check.py checks every row.
- Systems first (Feras 10-28): row 1 and anything urgent or hanging, then M1 (rows 3-6).
- Builders (D1): <= 2 Godot runs + 1 free text run (slots.sh). Briefs: docs/briefs/TEMPLATE.md. Balance band: start
  gear 82.7-89% wins; arc_arm needs an upside.

## Queue
| # | Task (brief or doc) | Dept | Lane | Who | Status | Blocked by |
|---|---|---|---|---|---|---|
| 3 | M1 brief: real-time Rydan vs 2 guards on the prison roof (VISION M1, CANON 10-27, docs/playtest/2026-10-27.md); it rewrites ARCHITECTURE section 8 | Gameplay | chat (plan) | Opus high | queued | - |
| 4 | M1 build from that brief + the Android export (D17) + archive the turn-based battle code (Feras 10-28), players-eye-gate before Feras | Gameplay | builder | agy | queued | 3 |
| 6 | Bake Roya (sprite-bake), native-scale render on the prison roof, review-player + review-feras | Art | chat (MCP) | Opus high | queued: runs while agy builds row 4 | 3; free memory >= 3 GB |
| 5 | Feras plays M1 on PC and phone; notes -> fix-pass rows | QA | Feras | - | queued | 4 |
| 7 | Art batch: Bilqis re-model (v2), guard, props (booth, floodlight, qamariya window, umbrella), icons; title = Flow Omni | Art | chat (MCP) | Opus high | queued; Rodin credits end ~11-17 | 6 |
| 8 | Free image-to-3D proof (rydan_style_v2 to a TRELLIS HF Space; never Blender generate_3d) -> 3d-model skill | Art | chat (MCP) | Opus medium | queued | 7 |
| 9 | Asset preparation pipeline (jpg -> png, sizes, import settings, manifest check) | Art | builder | cf | parked | 5 |
| 10 | Obscura proof: builders fetch web pages with the Obscura headless browser instead of Chrome (never --stealth); a tools/ wrapper + test | Ops | builder | cf | parked | 5 |
Key: builders are free code bots (agy = Gemini Flash, cf = Cloudflare DeepSeek, oc = free text models); chat (MCP) = a
Claude chat that drives Blender, Flow or Rodin; M1 = the first playable real-time fight, on the prison roof.

## Waiting on Feras
| What | Since | Where |
|---|---|---|
| Play M1 on PC and phone, send notes | Fri 10-30 | row 5 |
| OK on the vision | 10-27 | docs/VISION.md |
| Bilqis's portraits are now the Neon ones (overturn?) | 10-27 | archive-cleanup, decisions-log |
| More concept pictures + an empty plate per scene (no characters, HUD or rain) | 10-24 | inbox/ |
| Icon art | 10-27 | row 7 |

## This week (Claude Pro weekly limit: 72% used Wed 10-28, resets Sat 10-31 13:00 UTC = 09:00 New York: ~8% a day; on Feras's calendar)
| Day | Plan |
|---|---|
| Wed 10-28 | Row 1 part 2 (items 4-9): Feras starts its card, answers its questions; Feras OKs docs/VISION.md. |
| Thu 10-29 | Row 1 closes; row 3 M1 brief (Feras answers its feel questions); row 4 agy builds overnight. |
| Fri 10-30 | Row 4 review + eye gate if the weekly limit allows (else Sat); Feras: concept pictures, plates, icons, Bilqis call. |
| Sat 10-31 | Limit resets 09:00 New York: row 6 Roya bake; play day 1 (row 5) once row 4 passed the eye gate. |
| Sun-Mon | Fix passes from his notes; rows 7-8; play day 2. |

## Parked and context (resume only through a queue row)
- On main: features/neon/neon_game.tscn (start flow -> Roya cold open -> prison roof -> turn-based map fight -> cable
  line). M1 replaces the turn-based fight (CANON 10-27, real-time). Renders: tools/shot_neon_game.tscn.
- Archive done 10-27: hero code id rydan (save v7), res_graph + guard checks; restore from tag pre-cleanup.
- inbox/retired/ (Feras 10-27) = material he retired: never a reference or source. Story bible: inbox/Neon_Glitch_Story_Bible_Final.docx.
- RPG + menus: after M1, reskin to the new look (the old menu mockups and renders are retired).
- Retired 3D (D20): tag 3d-archive, branch archive/3d, lookup only; old builder branches gemini/*, oc/* kept, worktrees gone.

`Continue ferasalm/game on main. Read HANDOFF.md. Take the top queue row for your lane; /handoff.`
