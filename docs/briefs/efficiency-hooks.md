# Chat brief: efficiency fixes 1-5 as hooks and checks (Feras's number-one priority, 2026-10-27)
HANDOFF queue row 1. Archive cleanup merged 10-27 (d9c1735): start now. Lanes (Feras 10-27, one Opus chat at a time):
items 1-2 are Python hooks + tests -> Cloudflare DeepSeek builds (builders skill, TEMPLATE brief, May edit tools/hooks/
and the new tools/test_*.py only); the Opus chat wires them in .claude/settings.json (it also wires the pre_spend money
guard, so no builder edits it), briefs, reviews and does 3-5 (small doc edits).
Done already by the sync-board chat (10-27): the queue lane check (doc_check), tools/status.sh, /handoff archives
merged side sessions; the stale-slot cause (no pid line) was fixed in P1. Principle: every rule that
held was a tool (pre_spend, doc_check, CI); every rule that broke was prose -> each fix is a hook or check + a test
that fails on one bad case. Keep always-loaded notes under tools/doc_check.py caps.

1. Token hand-off (D4): PostToolUse hook in tools/hooks/, wired in .claude/settings.json. No bytes ratio needed:
   each main-chain `assistant` line of the transcript JSONL carries `message.usage`; input + cache_read +
   cache_creation of the last one == get_usage tokensUsed (measured 97,333 = 97,333). Work tokens ~= last total -
   first total (get_usage Messages also counts the opening brief, ~3k). Fallback without usage: user+assistant bytes
   / 5.7. Throttle: state per session_id in the temp dir, parse only after +40 KB growth, read the file's last 512 KB.
   additionalContext at 80k ("finish the unit") and 100k ("stop and /handoff"), each once, then every +10k.
2. Reviews before Feras: scope in one line (game renders and builds need review-player + review-feras; Flow concept
   pictures in a live taste round are exempt). PreToolUse hook on SendUserFile and Artifact: a render (inbox/ except
   inbox/flow/ and "inbox/Neon Glitch concept art/", .bake/, eye_gate contact.png, clip.mp4, f########.png) needs a
   stamp by sha256 in .check/reviews/ written by a review_stamp tool after both reviews; a test that every
   tools/shot_*.gd output path is caught.
3. content/art/refs.json: character id -> approved reference path + date + CANON line. Roya
   inbox/flow/roya_style_v3_2k.jpg, Rydan rydan_style_v2_2k.jpg, Bilqis bilqis_style_v2_2k.jpg (concept:
   inbox/Neon Glitch concept art/Bilqis.jpg). Test: every ModelDef with a Rodin scene has an entry (inbox/ is
   git-ignored: schema only). 3d-model + flow-media skills take references only from refs.json.
4. One reading rule (CLAUDE.md + WORKFLOW): Claude reads small targeted excerpts itself; Haiku only for reads over
   ~20k tokens or across many files.
5. Ripple + pre-mortem get trigger moments: pre_spend hook message and the TEMPLATE require a Ripple and a Pre-mortem
   line (test_template). CLAUDE.md -> two lists: "Enforced by a tool" (tool name) and <= 5 judgment duties, each with
   its trigger. Update DECISIONS D4 + D21 lines and LESSONS; check.sh; merge; /handoff; 5-line summary to Feras.

## Added 2026-10-28 (Feras: runs after M1; decisions-log 10-28, from the outside review of Gemini's studio design)
6. One lean rule (DECISIONS "The lean process"): CLAUDE.md, WORKFLOW, the handoff skill and the memory note
   model-routing-feras say the same; grep out every line that contradicts it. First prove whether an Agent-tool
   subagent can use the advisor (one scoped Sonnet subagent); if not, "Sonnet with /advisor opus" means a child chat.
   Opus review is tiered so it never reads needlessly: gates (check.sh, build_gate) first, a Haiku diff pass on big
   diffs, then Opus on the summary and the risky hunks; Opus signs off on whatever reaches Feras.
7. WORKFLOW Start here step 3 becomes a table, one row each: the father itself, builder, Haiku reader, review-* agent,
   Opus child chat; columns: when, rough cost, who reviews.
8. Departments as labels (B): retire the dept-* subagent mode in WORKFLOW, HANDOFF and CLAUDE.md; move
   .claude/agents/dept-*.md to ~/.claude/archive (D7, MOVED.txt); doc_check.py and its tests stop requiring them.
9. One routing table replaces the lanes and departments tables: request -> Dept -> skills -> persona -> lane ->
   reviewer. Personas (.agents/skills): game-designer, narrative-designer, technical-artist, level-designer,
   game-audio-engineer, godot-gameplay-scripter, godot-shader-developer, blender-addon-engineer, ui-designer, and
   ui-finish-gate-reviewer as the UI review before Feras. Every brief names its persona; our rules outrank persona
   text (they are engine-agnostic: FMOD/Wwise, C#; ours is typed GDScript): one line in GEMINI.md and TEMPLATE.
Ripple: doc_check.py + tests, tools/status.sh (Dept column), review-feras, the handoff skill, memory notes.
