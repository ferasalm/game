# Brief P2b: art routes, player's-eye gate, department skills, role cards (Sonnet main, Opus advisor)
Written by Opus 5.5, 2026-10-27, for package P2 of docs/audits/2026-10-27-process-audit-plan.md. Starts after
P2a is merged. It uses P2a's calibration winners (docs/research/calibration-2026-10.md) for every reader and lens.
This brief is the whole job.

## Rules for this chat
Same as P2a:
- `/advisor opus`; at most 3 fix rounds per step, then the checklist line goes open with its reason.
- Grep, then read the named lines.
- Haiku gets the mechanical reading and writing, through the briefs below.
- Milestone-only reports; hand off at ~100k work tokens.
- Never run git in C:\dev\game; merge only with check.sh green.
Use your own judgment only where a step says "decide". Anything else that is unclear goes to the advisor.

## Step 1: transcript extraction (Haiku H2; feeds P2.2 and P2.3)
H2 brief (Explore, calibrated model and effort, verbatim):
> Search the transcript files C:\Users\AUC\.claude\projects\C--dev-game\*.jsonl with the Grep tool only
> (output_mode content, -C 3, head_limit 60 per pattern). Do not Read whole files.
> Patterns:
> (1) `javascript_tool` near `flow` or `labs.google`;
> (2) `DataTransfer|dispatchEvent|file_upload|Download media`;
> (3) `rodin_create_uploads|rodin_generate|rodin_wait|rodin_generate_rigging|rodin_get_result|rewrite_glb`;
> (4) `bake_sprites.tscn|sprite_sheet.py`.
> Output at most 90 lines in four blocks: FLOW (the exact JavaScript that uploaded a reference image and the one
> that downloaded the result, verbatim, plus the click order); RODIN (the call order with the arguments that
> worked for Rydan, including quality/mesh settings and the rig type); BAKE (the exact commands); FAILED (routes that
> were tried and failed, one line each). Copy code verbatim; if a snippet is cut off, write TRUNCATED. No advice.

## Step 2: art skills (P2.2, P2.3, P2.4)
Each skill gets SKILL.md (<= 80 lines), lessons.md (seeded from LESSONS §5 lines on its route) and
research-queue.md. Frontmatter carries `paths:` where it helps (art skills: `assets/**`, `tools/art/**`).

- **flow-media**: H2's FLOW block.
  - Claude in Chrome only. The built-in pane cannot download or reach localhost; receiver.py failed.
  - Load all the Chrome tools in one ToolSearch call.
  - Ratios 1:1, 16:9, 9:16, 4:3, 3:4. Nano Banana for images, Omni for video.
  - Steps: "Download media" → 2K → ~/Downloads → inbox/ → assets/ + a manifest entry (template from
    assets/manifest.json).
  - Before any paid image tool: Flow first (D21).
  - Verify at first real use: mark the checklist line "verified at first use" unless Feras is at his PC and asks
    for a test image now.
- **3d-model**: H2's RODIN block.
  - Credit rules: name the cost; one approved hero asset before a batch; SPEND.md line (create
    docs/SPEND.md if missing).
  - About 50 credits expire around 2026-11-17, so the batch priorities from plan section 12 go here.
  - Free route stub: TRELLIS / Hunyuan3D / TripoSR on Hugging Face Spaces, unverified; Blender MCP
    search_assets/import_asset from CC0 libraries; Rigify, then ModelRig retarget. To prove before access ends
    (an art-chat task).
  - Fix docs/archive/design-3d/characters-3d.md:92 (it cites the deleted tools/shot_models.gd).
  - Do not spend credits in this chat.
- **sprite-bake**:
  - Move the batch to `tools/art/bake_all.sh`. Its source is in docs/audits/2026-10-27-process-audit-plan.md,
    "Saved from the temp scratchpad".
  - Arguments: `<out dir> <ids,comma> [states] [frame px] [ortho m] [colours]`.
  - The repo root comes from `git rev-parse --show-toplevel`, never /c/dev/game.
  - `timeout` and `< /dev/null` stay; one Godot at a time.
  - tools/art/sprite_sheet.py gets an optional colours argument: 0 = full colour, the new default (decide the
    argument position so old calls keep working). This is the Hades bar: no 256-colour cap unless asked.
  - Add tools/art/test_sprite_sheet.py: generated tiny PNG frames in a temp dir; assert frame count, sheet size,
    jsonl rows, and colours preserved when colours=0.
  - Verify: one real bake of rydan, idle state only, into your scratchpad, never assets/. Read 1 frame at
    640x360 to confirm it is in colour.
  - The skill states the open M1 question (fps × frame px × sheet memory on phones). It does not decide it.

## Step 3: player's-eye gate (P2.5)
- `tools/eye_gate.sh <wrapper.tscn> <seconds> <out dir>`:
  - a non-headless `--write-movie <out>/f.png --fixed-fps 30 --quit-after <seconds*30>` run of a render wrapper
    (tools/shot_neon_game.tscn);
  - then ffmpeg `-nostdin` makes a 4x4 contact sheet and an mp4, with timeouts;
  - it never writes into C:/dev/game/inbox from a worktree. Fix tools/shot_neon_game.gd:5 (it hard-codes that path)
    to use the checkout's own inbox/ (P2.10).
- `tools/eye_metrics.py` with `tools/test_eye_metrics.py`. **Build this one with DeepSeek** through
  tools/build_pipeline.sh: it is a new isolated file with a clear spec, the least risky builder task here.
  - Write the TEMPLATE brief yourself, with Do NOT edit (everything else) and May edit (none).
  - Spec, for each sprite clip in content/neon/sprites.json:
    - frames, fps (frames/seconds) and frame px;
    - per sheet PNG: unique colour count, and whether alpha exists;
    - the smallest `font_size` in features/**/*.tscn and *.tres.
  - It prints `METRIC <name> <value> <PASS|WARN> <bar>`, with bars from docs/design/acceptance.md (fps >= 24,
    colours > 256, font >= 18 px at 720p).
  - It always exits 0: it is a report, not a check.sh gate.
- `docs/design/acceptance.md` (<= 50 lines), drafted by Haiku H3 and edited by you; Feras edits it later.
- The players-eye-gate skill (<= 60 lines):
  1. eye_gate.sh, then eye_metrics.py;
  2. the calibrated player lens reads 4-6 frames at 640x360 and the contact sheet against acceptance.md;
  3. Opus confirms the misses;
  4. only then does a build reach Feras.
- Verify: one eye_gate run of shot_neon_game. Expect today's build to WARN on fps and colours: that proves the gate
  sees the problems Feras saw.

H3 brief (verbatim):
> Read docs/audits/2026-10-26-overnight-retro.md sections B and C, docs/feras-notes.md, and the "Appendix: Hades
> digest" section of docs/audits/2026-10-27-process-audit-plan.md. Write nothing. Output a draft acceptance list of
> at most 45 lines, grouped as: Colour, Motion, Light, Hit feedback (VFX+SFX), UI legibility, Portraits and
> framing, World logic (walk mask, doors, occluders), Story text, Fun (the core action unprompted within ~30 s).
> One line per item: `id | what a player must see | how to check it (metric / frame / playtest)`. Use numbers only
> where the sources give them; otherwise write "bar: Feras sets".

## Step 4: department skills and role cards (P2.6, P2.9)
- **ops-review** (frontmatter `context: fork`, `agent: Explore`, manual only). Body (<= 60 lines), every 5 sessions:
  - usage trend (USAGE.md, get_usage) against the P1 baseline;
  - promote or archive lessons;
  - doc_check warnings;
  - research prompts from the department queues (plan section 16: Feras's Gemini Deep Research, free models,
    agy, DeepSeek; never Claude);
  - archive idle sessions;
  - one department upgrade in rotation;
  - a 15-line report.
- **market-player** (<= 60 lines):
  - a market brief template (audience, comparables with price, scope and reviews, hook, platforms, price model,
    budget line);
  - success checks per milestone: persona walkthrough, outside playtest with a 5-question survey and telemetry,
    store and wishlist signals;
  - it drafts, and Feras publishes.
- **Role cards (Haiku H4, 4 parallel runs, one card each).** Each card goes to `.agents/skills/<card>/SKILL.md`,
  at most 60 lines, sections: Role, Our rules (from .claude/rules/code.md if it exists, else CLAUDE.md "Code
  rules"), Known failure modes (from LESSONS §4 and the review_misses in GEMINI.md), Checks before done. Cards and
  their sources:
  - gameplay-card: godot-gameplay-scripter + minimal-change-engineer.
  - art-card: technical-artist + godot-shader-developer + image-prompt-engineer.
  - ui-card: ui-designer + ui-finish-gate-reviewer.
  - market-card: from ~/.claude/agents: Business Strategist, Product Manager, UX Researcher, Behavioral Nudge Engine,
    Persona Walkthrough Specialist, Feedback Synthesizer. Read them before P3 archives ~/.claude. P3's prompt must
    keep these six.
- **Retire:** `git mv` the plan's section-9 retire list from .agents/skills to .agents/archive/. Keep
  blender-addon-engineer. Grep briefs and tools for each name first, and repoint any live reference to its card.

## Done
- Checklist lines P2.2-P2.6, P2.8 (rest), P2.9 and P2.10 are ticked with commits; open lines have their reasons.
- check.sh is green and the work is merged to main.
- HANDOFF Efficiency holds P0's prompt: "P0 VISION: an interview with Feras, then docs/VISION.md, the 25 notes
  re-triaged, docs/research/hades-digest.md from the plan appendix. Model: Opus. Effort: high."
- A USAGE row, then /handoff.
