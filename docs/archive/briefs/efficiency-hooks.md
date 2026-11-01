# Chat brief: efficiency fixes 1-5 as hooks and checks (Feras's number-one priority, 2026-10-27)
Status 10-28 (part 3, confident-mcclintock): DONE 9: oc run personas-tailor merged after a Haiku pass and an Opus read of
each persona (fixed: 3D shader types and fog/mist lines, Rodin credits + spend ok, normal maps models-only, split quotes,
render .tscn names); UI reviewer back to ui-finish-gate-reviewer + review-player; sync_personas + test_personas green.
ROW 1 CLOSED.
Status 10-28 (part 2, dazzling-shannon): DONE 4-8 + item 6's stamp step (aaabb88, 30288f0 on main): CLAUDE.md
"Enforced by a tool" + 5 judgment duties with triggers; WORKFLOW step 3 worker table, one Routing table, tiered review,
Sonnet subagent + advisor (probed: it has `advisor`, ~67k start); dept-* agents archived; doc_check checks personas and
reviewers. LEFT: 9. Branch claude/dazzling-shannon-8d05cc holds tools/sync_personas.py + test_personas.py (red) and
docs/briefs/personas-tailor.md; oc run personas-tailor launched from that branch. Next chat: read the .result first line;
PASS -> Haiku diff pass vs the brief, Opus reads each persona (canon quoted, stack right, no generic craft), fix or
rerun, merge the run into the session branch, run sync_personas.py, set the UI reviewer in WORKFLOW Routing back to
ui-finish-gate-reviewer + review-player, check.sh, merge to main, close row 1. FAIL/NOWORK -> fix the brief, rerun.
Status 10-28 (part 1, determined-hertz): DONE 1, 2 (cf run + 5 review fixes; wired via tools/hooks/run.sh), 3, 10
(generate_3d guard; pre_spend question + archive/removal asks in Waiting on Feras; status.sh's old branches: oc/interact-
focus, oc/souq-place, claude/recursing-mirzakhani-6cd00a, worktree-agent-a7a39e37..., -a4cf40c0...: kept, D7). NEXT: 4, 5,
then 6-8 (docs + doc_check), then 9: Claude writes tools/sync_personas.py (source frontmatter -> .claude/skills copy
verbatim; .claude/agents/<name>.md = name + description + source body) and tools/test_personas.py (drift; no Unity,
Unreal, FMOD, Wwise or C#; names Godot 4.7.2 + code.md; an "Adapted from" line; an Output template and Reviewer section),
red on the base; then one oc run (pipeline, May edit .agents/skills/<10>/SKILL.md); a Haiku pass, then Opus per persona.
Item 6 also: only the gate's BLOCKED message tells a chat to run tools/hooks/review_stamp.py after review-player +
review-feras: add that step to the players-eye-gate skill flow.
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
3. tools/art/refs.json: character id -> approved reference path + date + CANON line. Roya
   inbox/flow/roya_style_v3_2k.jpg, Rydan rydan_style_v2_2k.jpg, Bilqis bilqis_style_v2_2k.jpg (concept:
   inbox/Neon Glitch concept art/Bilqis.jpg). Test: every ModelDef with a Rodin scene has an entry (inbox/ is
   git-ignored: schema only). 3d-model + flow-media skills take references only from refs.json.
4. One reading rule (CLAUDE.md + WORKFLOW): Claude reads small targeted excerpts itself; Haiku only for reads over
   ~20k tokens or across many files.
5. Ripple + pre-mortem get trigger moments: pre_spend hook message and the TEMPLATE require a Ripple and a Pre-mortem
   line (test_template). CLAUDE.md -> two lists: "Enforced by a tool" (tool name) and <= 5 judgment duties, each with
   its trigger. Update DECISIONS D4 + D21 lines and LESSONS; check.sh; merge; /handoff; 5-line summary to Feras.

## Added 2026-10-28 (Feras: systems first, before M1; decisions-log 10-28, from the outside review of Gemini's studio design)
6. One lean rule (DECISIONS "The lean process"): CLAUDE.md, WORKFLOW, the handoff skill and the memory note
   model-routing-feras say the same; grep out every line that contradicts it. First prove whether an Agent-tool
   subagent can use the advisor (one scoped Sonnet subagent); if not, "Sonnet with /advisor opus" means a child chat.
   Opus review is tiered so it never reads needlessly: gates (check.sh, build_gate) first, a Haiku diff pass on big
   diffs, then Opus on the summary and the risky hunks; Opus signs off on whatever reaches Feras.
   Feras 10-28: fix both, not just note them: the advisor result goes into WORKFLOW (Model routing) and the memory
   note; the review tiers go into WORKFLOW (Protocols: Review), review-code and the handoff skill, with a check
   wherever one can hold (e.g. nothing reaches Feras without the review stamp of item 2).
7. WORKFLOW Start here step 3 becomes a table, one row each: the father itself, builder, Haiku reader, review-* agent,
   Opus child chat; columns: when, rough cost, who reviews.
8. Departments as labels (B): retire the dept-* subagent mode in WORKFLOW, HANDOFF and CLAUDE.md; move
   .claude/agents/dept-*.md to ~/.claude/archive (D7, MOVED.txt); doc_check.py and its tests stop requiring them.
9. One routing table replaces the lanes and departments tables: request -> Dept -> skills -> persona -> lane ->
   reviewer. Personas (.agents/skills): game-designer, narrative-designer, technical-artist, level-designer,
   game-audio-engineer, godot-gameplay-scripter, godot-shader-developer, blender-addon-engineer, ui-designer, and
   ui-finish-gate-reviewer as the UI review before Feras. Every brief names its persona; our rules outrank persona
   text (they are engine-agnostic: FMOD/Wwise, C#; ours is typed GDScript): one line in GEMINI.md and TEMPLATE.
   Tailor the 10 personas (Feras 10-28: "not generic"): one source each in .agents/skills/<name>/SKILL.md, rewritten
   for Neon Glitch: drop other engines and tools (Unity, Unreal, FMOD/Wwise, C#); add our stack and rules (Godot 4.7.2
   typed GDScript, .claude/rules/code.md, logic/ pure, integer 60-tick deterministic combat, Def classes from JSON,
   TextDB, Mobile renderer + Android, 2D isometric, combat feel wins ties), the CANON, VISION and art-bible lines
   it needs, the builder limits (May edit, tests read-only, Proof), its own output template and its reviewer.
   Drafts: oc (free text lane), Opus reviews each. A tools/ sync script writes the .claude/skills and .claude/agents
   copies (ui-designer and ui-finish-gate-reviewer too) from that source; a test fails on drift; keep AGENCY-LICENSE
   and an "adapted from" line in each file.
Ripple: doc_check.py + tests, tools/status.sh (Dept column), review-feras, the handoff skill, memory notes.
10. Hanging work (Feras 10-28: "finish whatever is urgent and/or hanging"), first: items 1-2 were already built by
   cf on oc/efficiency-hooks-build (red tests + DeepSeek brief by claude/friendly-gagarin-0fb38d): read its gate
   result, review-code, wire the hooks in .claude/settings.json, merge. Then tools/status.sh: archive the finished
   sessions, remove worktrees with nothing beyond main (nervous-boyd-0e8591 has uncommitted changes: look first),
   list the old oc/* and worktree-agent-* branches for Feras. The pre_spend matcher misses mcp__blender__generate_3d
   (may cost a credit; "never Blender generate_3d"): add it with a test. Find what "the pre_spend question" (Waiting
   on Feras) asks and put it to him in one batched question set with any others.
