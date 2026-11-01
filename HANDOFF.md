# HANDOFF (current state only; ONE queue for every chat; max 60 lines)
Last updated: 2026-11-01 (row 25 gate run by Sonnet high without Opus sign-off, merged to main on Feras's OK; held items in Open points), Sonnet 5.5.
Live state in one command: `bash tools/status.sh` (builders, branches not on main, worktrees, this queue, Open points).

Queue rules (one queue, top row first; Dept, Lane, Open points, builder caps, balance band): docs/queue-rules.md.

## Queue
| # | Task (brief or doc) | Dept | Lane | Who | Status | Blocked by |
|---|---|---|---|---|---|---|
| 3 | M1 brief: real-time Rydan vs 2 guards on the prison roof, combat feel first (VISION M1, CANON 10-27, docs/playtest/2026-10-27.md); it rewrites ARCHITECTURE section 8 | Gameplay | chat (plan) | Opus high | Tue 11-03 | - |
| 26 | Writer trial (Feras 11-01): one real brief to agy medium and cf at max (and default or high), results in docs/runs.csv; merge_run.sh logs each merged worker's findings and fix passes (test first). Row 25 proved the low-cost-pipeline skill on one small run | Ops | builder + chat (review) | agy, cf; Sonnet high | with row 4's first builds | - |
| 4 | M1 build from that brief + the Android export (D17) + archive the turn-based battle code (Feras 10-28), players-eye-gate before Feras | Gameplay | builder | agy | after row 3 | 3 |
| 6 | Bake Roya (sprite-bake), native-scale render on the prison roof, review-player + review-feras | Art | chat (MCP) | Opus high | after row 3 | 3; free memory >= 2 GB |
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
| Opus sign-off on row 25 (Sonnet ran the gate): a dedicated Opus high chat, prompt in docs/opus-signoff.md; it also runs the full interactive /kaizen:coach (11-01 score 8/10 came from a Haiku audit) | Claude | 11-01 |
| Studio and pm plugins: confirm once in C:\dev\game that `claude plugin list` shows studio@neon and pm@neon enabled (the smoke chat loaded both from a worktree off main) | Feras | 11-01 |
| Status line wired in .claude/settings.json (row 23 e); its real stdin JSON is not dumped yet: in the first fresh chat open `.check/statusline_raw.json` and confirm the field names (docs-based today) | Claude | 11-01 |
| Row 20 leftovers, no row yet (row 24 is done; specs too vague to brief): session_stats dates by entry and a tighter GUARD regex, Gameplay lessons.md + research-queue.md, frame_score blank-line slot; row 3 input: docs/audits/2026-11-02-integrity.md Top 10 (its item 5, test_action_def, is a false positive) | Claude | 11-01 |

## This week (weekly limit resets Sat 16:00 GMT+3)
| Day | Plan |
|---|---|
| Sun 11-01 | Rows 22-25 done on system-v4 (row 25 by Sonnet high; held items in Open points). |
| Mon 11-02 | Opus sign-off chat on row 25 (docs/opus-signoff.md), then the M1 brief early if time allows. |
| Tue 11-03 | M1 brief (row 3); M1 build (row 4) overnight into Wed 11-04 at the earliest; play day moves to when M1 passes its gates. |

## Parked and context
docs/context.md (what is on main, the 3D archive, inbox/retired/ never a source); resume only through a queue row.

## Prompt for the next chat
Type `/model opus`, then `/effort high`, stay in auto mode, then paste this as one message (Opus: no `/goal`):
`Row 25 sign-off, Ops, Opus high: read docs/opus-signoff.md first and do what it says.` (After it: `Row 3, Gameplay, Opus high: write the M1 brief; read docs/next-chat.md first and do what it says.`)
