# Decisions in force: process, tools, engine, scope (full history: docs/decisions-log.md)
Each line: date of the deciding entry | the rule as it stands today | by. Update a line when a later decision changes
it; log every new decision verbatim in docs/decisions-log.md too. Game content (world, story, heroes, combat, art,
UI): docs/CANON.md, read before any content work. D1-D22 = the process audit plan (docs/audits/2026-10-27-*).

### Scope
- 2026-10-27 | Neon Glitch = the whole game: 2D isometric action RPG, real-time Hades-like combat, linear story (not a roguelite); docs/VISION.md holds pillars (combat feel wins ties), objectives, roadmap: free 20-30 min demo first, then premium; PC (Steam) leads, Android kept alive from M1 (D17), iOS later; Feras plays gated builds twice a week | Feras
- 2026-10-26 | Old 3D game retired, archived on branch archive/3d + tag 3d-archive; lookup only (D20); reuse what fits (docs/archive/3d-reuse.md) | Feras
- 2026-10-27 | Process audit P1 -> P2 -> P0 -> P3 -> P4 runs before game work (D12); repo public until before the first public demo, then private (D16) | Feras
### Process
- 2026-10-26 | Look gate: no system work on a scene until Feras OKs its render from the play camera; player's-eye gate (eye_gate) before any build reaches him, apart from check.sh (D5); shared code never names one game mode (layer lint) | Feras
- 2026-10-27 | Claude is Feras's advisor (D21): checks requests against VISION, warns with a better default, maps ripples (docs/design/systems-map.md, a Ripple section in every spec), logs his repeated notes (docs/feras-notes.md), review-feras before anything reaches him; the Opus standard (D22) is in CLAUDE.md | Feras
- 2026-10-26 | Kaizen: Claude plans strategically, keeps VISION current, upgrades one tool, check, skill or doc each session | Feras
- 2026-10-27 | Departments = skills + a 4-lens review panel; ops-review every 5 sessions (D8); a Market and player department with success checks per milestone (D19); lesson lifecycle: add, promote to a check, or archive after 30 days (D9) | Feras
- 2026-10-21 | Ask Feras 2-4 multiple-choice questions, recommended first; big asks: plan mode (Opus xhigh), narrow audits by calibrated readers, then orchestrate; free models get text work and lenses only after calibration vs Haiku (D11) | Feras
- 2026-10-21 | Runs stop only for owner questions, logins, CAPTCHAs, downloads, spending | Feras/Claude
- 2026-10-27 | Hand off at ~100k work tokens (get_usage Messages) (D4); milestone-only reports; HANDOFF = one queue, each row names its lane (builder by default), one Opus chat at a time (10-27) | Feras
- 2026-10-23 | Emergency mode (50% of the 5-hour window): one director chat, builders on backups; builders never merge or push to main (D3) | Feras
- 2026-10-22 | Always-loaded notes <= 27 KB; caps in tools/doc_check.py (warns at 75%); one task, model, effort per chat | Feras
- 2026-10-27 | No chat edits in C:\dev\game: worktrees only; the main checkout is for Feras's play and builder launches (D10) | Feras
- 2026-10-19 | Merge checked work into main at each session's end (standing OK) | Feras
- 2026-10-22 | Log: never reword; struck (~~...~~) lines go to docs/decisions-archive.md | Claude
- 2026-10-19 | Blueprint and docs/research = design input only, never facts; WSL2 rule and 120-line cap rejected | Claude
### Tools and builders
- 2026-10-27 | Builders (D1): Godot code on agy + Cloudflare DeepSeek, <= 2 Godot runs machine-wide under a free-memory floor; text work + calibrated review lenses on opencode/OpenRouter :free (+1 run, no Godot); Claude's own reads: the cheapest calibrated reader (Haiku high today); one builders skill (D2); research by everyone except Claude (D18) | Feras
- 2026-10-27 | Paid tools: free route first (WORKFLOW routes table); paid image APIs <= $1 with Feras's OK; a PreToolUse hook (tools/pre_spend.py) blocks paid generation without his "spend ok"; one docs/SPEND.md line per paid call | Feras
- 2026-10-27 | Hyper3D Rodin: ~50 credits, ~3 weeks left: use early, name the credit cost first, prove a free route (Blender stays) before access ends (D14); Flow = Nano Banana images, Omni video | Feras
- 2026-10-26 | Builder briefs: tests and assets Do NOT edit by default with a "May edit" list (D6); the gate rejects removed checks; strong player-visible tests | Feras
- 2026-10-23 | Builds: build_pipeline.sh + build_gate.py; Claude reads PASS runs only; merge chats on Sonnet | Feras
- 2026-10-23 | Briefs: TEMPLATE, gate-tested Checklist; Haiku diff pass before Opus (design, renders); tools/slots.sh counts slots | Feras
- 2026-10-27 | ~/.claude tidy: unused agents and skills moved to ~/.claude/archive (MOVED.txt), never deleted (D7) | Feras
- 2026-10-25 | Story map: docs/story/rydan.twee <-> Twine via tools/twine_sync.py; Twine library in docs/story/twine (git-ignored) | Feras/Claude
- 2026-10-21 | Game skills: .agents/skills/ copied to .claude/skills/ (skillOverrides name-only set, NOT taking effect 10-27: unverified) | Feras
### Engine and code
- 2026-10-27 | Godot 4.7.2 pinned; typed GDScript; Windows first, exes git-ignored; Mobile renderer + touch controls + Android CI export from M1 (D17) | Feras/Claude
- 2026-10-19 | Min target: Dell Latitude 5520 (16 GB) at 60 FPS, and Feras's phone (D17) | Claude
- 2026-10-22 | Content = read-only Def classes from JSON; runtime state separate; folders per feature, logic/ pure; saves: GameState (versioned), 3 slots; code rules: .claude/rules/code.md | Claude/Feras
- 2026-10-19 | Combat logic: integers, fixed 60 ticks/s, deterministic, returns events | Claude
- 2026-10-21 | Player text: localization/<feature>.csv via the TextDB autoload, not Godot CSV import | Claude
