# Decisions in force: the rules most tasks need (full history: docs/decisions-log.md)
Line format and update rule: docs/decisions-log.md header. Game content: docs/CANON.md, read before any content work.
D1-D22 = the process audit plan (docs/archive/audits/2026-10-27-*).
Read before the work, not at start: docs/decisions-tools.md (builders, models, paid tools, pipeline, assets tooling);
docs/decisions-process.md (how chats, reviews, hand-offs and notes run; changing the process). Same line format.

### Scope
- 2026-10-27 | Neon Glitch = the whole game: 2D isometric action RPG, real-time Hades-like combat, linear story (not a roguelite); docs/VISION.md holds pillars (combat feel wins ties), objectives, roadmap: free 20-30 min demo first, then premium; PC (Steam) leads, Android kept alive from M1 (D17), iOS later; Feras plays gated builds twice a week | Feras
- 2026-10-26 | Old 3D game retired, archived on branch archive/3d + tag 3d-archive; lookup only (D20); reuse what fits (docs/archive/3d-reuse.md) | Feras
- 2026-10-31 | System v3 comes before M1 (docs/archive/briefs/system-v3.md): rows 22-25 on branch system-v4 (system-v3 until row 24), main untouched until the Opus gate; hard stop Mon 11-02, M1 brief Tue 11-03; the 4 non-safety hooks leave settings.json at the row 25 gate (Feras 11-01) | Feras
- 2026-11-02 | M1 combat = Hades feel + Sekiro parry: move, dash, 3-hit combo, parry with posture and a dash-counter; special and cast later; soft aim; floating stick + buttons; baton + rifle guards; spec docs/design/m1-fight.md, plan docs/briefs/m1-plan.md (CANON has the rules) | Feras
### Process
- 2026-10-26 | Look gate: no system work on a scene until Feras OKs its render from the play camera; player's-eye gate (eye_gate) before any build reaches him, apart from check.sh (D5); shared code never names one game mode (layer lint) | Feras
- 2026-10-21 | Ask Feras 2-4 multiple-choice questions, recommended first; big asks: plan mode (Opus xhigh), narrow audits by calibrated readers, then orchestrate; free models get text work and lenses only after calibration vs Haiku (D11) | Feras
- 2026-10-21 | Runs stop only for owner questions, logins, CAPTCHAs, downloads, spending | Feras/Claude
- 2026-10-31 | Finish the task at hand: context size never stops, shortens or hands off work (the 200-300k band and emergency's ~100k are retired); /handoff when the task is done or at ~85% of the 5-hour window; a chat holds one part of a queue row; rules that degrade work get replaced | Feras
- 2026-10-31 | The system plan (row 21: a simple working system, a project-aware plugin) comes before M1; plan at Opus xhigh in his CLI session, execute at Sonnet high | Feras
- 2026-10-31 | Stuck or refused -> ask Feras at once, options with a pick; "waiting on Feras" only for what he was asked in that chat | Feras
- 2026-11-04 | What-we-have pipeline (row 28): agy builds most; GLM-5.3-flash designs levels, technical art (Feras keeps art direction), dialogue and narrative (review-canon gates it); DeepSeek 1017 debugs, balances, optimizes and owns accuracy-critical mechanics; the head writes red tests (may consult other families in isolated chats the builder never sees); paid OpenRouter = $3/month hard cap + Feras's OK per run; NIM only overnight; Haiku medium default, xhigh max, routine reads to agy flash-low | Feras
- 2026-11-01 | Workers (Rank 1): Haiku 5.5 subagents launch and wait (effort superseded 11-04: medium default, xhigh max), a fork only for a noisy chunk needing the chat's context, a Sonnet subagent only at `high` (Feras 11-02: unbanned to save Opus usage); agy and nv take all they can do as well; stuck twice -> ask Feras for /advisor opus; the whole workflow lives in ONE skill folder, .claude/skills/low-cost-pipeline (head = any Claude at high, scripts as foremen, reviewer = another model family, CAP_NV 3; Feras 11-02) | Feras
- 2026-10-23 | Emergency mode (50% of the 5-hour window): one director chat, builders on backups; builders never merge or push to main (D3) | Feras
- 2026-10-29 | No chat edits in C:\dev\game: worktrees only; the main checkout is for Feras's play and builder launches (D10); one exception: after merging to main, a chat runs `bash tools/sync_main.sh` there when it has no local changes (10-29) | Feras
- 2026-10-19 | Merge checked work into main at each session's end (standing OK) | Feras
- 2026-10-19 | Blueprint and docs/research = design input only, never facts; WSL2 rule and 120-line cap rejected | Claude
### Engine and code
- 2026-10-27 | Godot 4.7.2 pinned; typed GDScript; Windows first, exes git-ignored; Mobile renderer + touch controls + Android CI export from M1 (D17) | Feras/Claude
- 2026-10-19 | Min target: Dell Latitude 5520 (16 GB) at 60 FPS, and Feras's phone (D17) | Claude
- 2026-10-22 | Content = read-only Def classes from JSON; runtime state separate; folders per feature, logic/ pure; saves: GameState (versioned), 3 slots; code rules: .claude/rules/code.md | Claude/Feras
- 2026-10-19 | Combat logic: integers, fixed 60 ticks/s, deterministic, returns events | Claude
- 2026-10-21 | Player text: localization/<feature>.csv via the TextDB autoload, not Godot CSV import | Claude
