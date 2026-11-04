# HANDOFF (current state only; ONE queue for every chat; max 60 lines)
Last updated: 2026-11-04 (Cloudflare retired: free nv lane + fallback chain; worktrees cleaned), Opus 5.5.
Live state in one command: `bash tools/status.sh` (builders, branches not on main, worktrees, this queue, Open points).

Queue rules (one queue, top row first; Dept, Lane, Open points, builder caps, balance band): docs/queue-rules.md.

## Queue
| # | Task (brief or doc) | Dept | Lane | Who | Status | Blocked by |
|---|---|---|---|---|---|---|
| 28 | What-we-have pipeline (roles decided 11-04): docs/briefs/row28-pipeline-v3-plan.md | Ops | chat (plan) | Opus high | ready: next chat = verify live, brief a-j, build g (oc-v2 logins: NVIDIA, Cerebras, Google; Groq dropped) | - |
| 4 | M1 build in 6 waves from docs/briefs/m1-plan.md (9 part briefs, spec docs/design/m1-fight.md, types m1-fight-api.md): per wave the red tests first (scope run, the head reads every test), then the parts; wave 6 archives the turn-based code (D17 Android export in CI alongside); players-eye-gate before Feras | Gameplay | builder | nv DeepSeek/GLM, agy | ready: wave 1 (m1-defs) on agy; nv/OpenRouter lanes after row 28 | - |
| 6 | Bake Roya (sprite-bake), native-scale render on the prison roof, review-player + review-feras | Art | chat (MCP) | Opus high | ready | free memory >= 2 GB |
| 5 | Feras plays M1 on PC and phone; notes -> fix-pass rows | QA | Feras | - | later: after row 4 | 4 |
| 7 | Art batch: Bilqis re-model (v2), guard, props (booth, floodlight, qamariya window, umbrella), icons; title = Flow Omni | Art | chat (MCP) | Opus high | queued; Rodin credits end ~11-17 | 6 |
| 8 | Free image-to-3D proof (rydan_style_v2 to a TRELLIS HF Space; never Blender generate_3d) -> 3d-model skill | Art | chat (MCP) | Opus medium | queued | 7 |
| 9 | Asset preparation pipeline (jpg -> png, sizes, import settings, manifest check) | Art | builder | nv | parked | 5 |
| 10 | Obscura proof: SET UP 11-03 (Obscura 0.2.5 in the main checkout's Obscura folder, git-ignored; tools/obscura.sh + test_obscura.py, routing row). Left: one real builder run fetches a page with it and we judge it against Chrome on a JS-heavy page; no login pages | Ops | builder | nv | parked | 5 |
| 11 | Art bible 2D pass: drop the retired 3D runtime lines (fog, mist, sky, spatial shading, the "2150" title) the personas nearly copied; docs/design/art-bible.md | Art | builder | oc | parked | 5 |
Key: builders are near-free bots (agy = Gemini 3.8 Flash, nv = DeepSeek V4.1 Flash on NVIDIA NIM, free, falling back NVIDIA > Zen > Cerebras > OpenRouter :free, oc = OpenRouter free lenses); chat (MCP) = a
Claude chat that drives Blender, Flow or Rodin; M1 = the first playable real-time fight, on the prison roof.

## Open points
| Point | Owner | Since |
|---|---|---|
| Bilqis's portraits are now the Neon ones: keep or overturn (archive-cleanup, decisions-log); on hold until further notice (Feras 10-31) | Feras | 10-27 |
| Art homework into inbox/: concept pictures, an empty plate per scene (no characters, HUD or rain), icon art (row 7) | Feras | 10-24 |
| After merging row 26 to main: `python tools/plugin_prune.py` (dry run, then --apply) once the finished worktrees are removed; 6 kaizen entries remain for live worktrees | Claude | 11-02 |
| Revisit LSP for review-code after row 4 (M1 built): rerun the recipe in docs/audits/2026-11-02-lsp-reviewers.md on 3 fresh diffs; DO only if grep missed a caller of a name declared in 2+ files (verdict now: DON'T DO) | Claude | 11-02 |
| Doc graph cleanup (row 27 shipped `tools/doc_graph.py`, DOCMAP.md, check.sh gate): 220 baselined dangling pairs in docs/doc_graph_allow.txt (most are example paths in .agents/archive personas), 30 orphans and 240 overlap lines to merge or delete; bare file names (`models.md`) do not count as references yet | Claude | 11-01 |
| Row 20 leftovers, no row yet (row 24 is done; specs too vague to brief): session_stats dates by entry and a tighter GUARD regex, Gameplay lessons.md + research-queue.md, frame_score blank-line slot; row 3 input: docs/audits/2026-11-02-integrity.md Top 10 (its item 5, test_action_def, is a false positive) | Claude | 11-01 |

## This week (weekly limit resets Sat 16:00 GMT+3)
| Day | Plan |
|---|---|
| Sun 11-01 | Rows 22-25 done on system-v4 (row 25 by Sonnet high; held items in Open points). |
| Mon 11-02 | Row 25 signed off by Opus; the M1 brief early if time allows. |
| Tue 11-03 | M1 brief done (11-02, row 3); M1 build (row 4) from wave 1; play day moves to when M1 passes its gates. |

## Parked and context
docs/context.md (what is on main, the 3D archive, inbox/retired/ never a source); resume only through a queue row.

## Prompt for the next chat
Start with `claude --model opusplan -w <name>` (a chat started in its own worktree lists skills once), `/effort high`, stay in auto mode, then paste this as one message (Opus: no `/goal`):
`Row 28, Ops, Opus high: the what-we-have pipeline. Read docs/briefs/row28-pipeline-v3-plan.md first (its What-we-have and AA data sections win over older lines). In plan mode: check oc-v2 auth list, verify every "Check live" item, ask me edge cases with AskUserQuestion, then write part briefs a-j. Then exit plan mode and build part g (skills reset to the earliest git versions + one shared overlay), re-enter plan mode to review the diff, run check.sh, merge and /handoff.` (Before it, Feras: log NVIDIA, Cerebras and Google into the oc-v2 opencode folder; Groq dropped.)
