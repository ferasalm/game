# Decisions in force: tools and builders (not loaded at start; pointer in docs/DECISIONS.md)
Same line format as docs/DECISIONS.md. Log every new decision verbatim in docs/decisions-log.md too.

### Tools and builders
- 2026-10-31 | Two in-repo plugins: studio (skills, agents, hooks, Godot LSP) and pm (queue, week, report, handoff on HANDOFF.md, no new database); pre_spend, review_gate and session-start stay wired in .claude/settings.json so they fail closed | Feras/Claude
- 2026-10-31 | Worker calls stay under auto mode, no project allow list; a settings.json edit auto mode refuses goes to Feras, never around it | Feras
- 2026-10-31 | Routing OK with limits (builders skill, Who does what): agy builds, cf DeepSeek max reviews, Clef-flash pre-filters colour and character visible, review-player keeps text, Jev sorts errors; no reasoning = bulk text, quick questions, generate_patch, never review; Sonnet only at high, Haiku never orchestrates; only the efforts Feras names | Feras
- 2026-10-31 | Pipeline: commit before the first check, check in the foreground (backgrounded = killed at 5 min); `cf ... fast` needs a Pattern, fix passes at max | Claude
- 2026-10-31 | check.sh stays bash, no Rust: tool tests run side by side, the 2 slow toy tests skip when tools/ is unchanged since they passed, CI runs all | Feras
- 2026-10-30 | Cross-review: the other model family reviews every PASS run before Claude's gate via tools/cross_review.sh: gemini/* -> Cloudflare DeepSeek 1017 at max effort (nemotron :free only as a backup lens when cf fails twice, capped at 5 min (10-31), no answer = no lens; never a reader or sole reviewer); oc/* -> agy (--dangerously-skip-permissions --sandbox, empty box); no races; kept at 5 measured runs (10-31: 1.2 real bugs a run, drop line < 1) | Feras/Claude
- 2026-10-27 | Builders (D1): Godot code on agy + Cloudflare DeepSeek, <= 2 Godot runs machine-wide under a free-memory floor; text work + calibrated review lenses on opencode/OpenRouter :free (+1 run, no Godot); Claude's own reads: the cheapest calibrated reader (builders skill, Who does what); one builders skill (D2); research by everyone except Claude (D18) | Feras
- 2026-10-27 | Paid tools: free route first (WORKFLOW routes table); paid image APIs <= $1 with Feras's OK; a PreToolUse hook (tools/hooks/pre_spend.py) blocks paid generation without his "spend ok"; one docs/SPEND.md line per paid call | Feras
- 2026-10-30 | Cloudflare Workers AI: no $ cap (spend logged in cf_spend.csv); DeepSeek 1017 at reasoning_effort max with opencode's output cap 384k, its full output (builders.conf); GLM-5.3-flash on cf for bulk text after calibration; agy = gemini-3.8-flash-medium (10-31) | Feras
- 2026-10-30 | opencode v2.2.2 pinned beside v1.19.4, runs via lib.sh oc_run; rollback in builders.conf | Feras/Claude
- 2026-10-30 | Bandwidth (metered): no tracked file > 10 MB or > 2 MB outside assets/ (tools/test_file_sizes.py); renders and exports git-ignored; the cache-read hook only informs (25M, then +10M) | Feras
- 2026-10-27 | Hyper3D Rodin: ~50 credits, ~3 weeks left: use early, name the credit cost first, prove a free route (Blender stays) before access ends (D14); Flow = Nano Banana images, Omni video | Feras
- 2026-10-26 | Builder briefs: tests and assets Do NOT edit by default with a "May edit" list (D6); the gate rejects removed checks; strong player-visible tests | Feras
- 2026-10-23 | Builds: build_pipeline.sh + build_gate.py; Claude reads PASS runs only; the chat that started the run (the father or its child chat) merges it after Opus review (10-28) | Feras
- 2026-10-23 | Briefs: TEMPLATE, gate-tested Checklist; Haiku diff pass before Opus (design, renders); tools/slots.sh counts slots | Feras
- 2026-10-27 | ~/.claude tidy: unused agents and skills moved to ~/.claude/archive (MOVED.txt), never deleted (D7) | Feras
- 2026-10-25 | Story map: docs/story/rydan.twee <-> Twine via tools/twine_sync.py; Twine library in docs/story/twine (git-ignored) | Feras/Claude
- 2026-10-21 | Game skills: .agents/skills/ copied to .claude/skills/ (skillOverrides name-only works: < 20 tokens each, /skill-doctor 10-31) | Feras
- 2026-11-01 | Defaults between agy and cf (writer, reviewer) come from docs/runs.csv after a few more runs, not a hunch; cf DeepSeek at max is tried as a writer too, its effort (none, default, high, max) chosen per task by routing judgement; every worker's result is logged to docs/runs.csv when its run is merged | Feras
