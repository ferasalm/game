# Decisions (append-only)
One line each: date | decision | why | by. Never delete or reword; strike through (~~...~~) and say what superseded
it. Loaded at every session start: keep lines short (tools/doc_check.py caps this file at 70 lines).

## Log
- 2026-10-19 | True HD-2D: 3D diorama world, 2D pixel-art billboard characters (not the blueprint's 2D layers) | iconic look; switching later would redo world art | Feras
- 2026-10-19 | Art budget $0: Gemini Pro, Google Flow, free tools, CC0/free packs; no paid artist or packs | Feras: "does not require spending money" | Feras
- 2026-10-19 | Goal: the 30-minute Chapter 1 vertical slice first; decide on a full game after it | Feras | Feras
- 2026-10-19 | Claude Pro ($20/month): Sonnet builds, Opus designs and reviews, Haiku for mechanical work | Feras's plan; Pro limits | Feras/Claude
- 2026-10-19 | Godot 4.7.2 stable pinned in .godot-version; typed GDScript (untyped = error); Forward+ renderer; Windows first | free, text scenes, headless tests | Claude (owner may veto)
- 2026-10-19 | No WSL2: Claude works in cloud sessions (Linux); the owner runs Godot natively on Windows from C:\dev\game | cloud is Linux already; editor on a WSL drive is slow | Claude
- 2026-10-19 | Content as JSON read into read-only Def classes; runtime state in separate objects; saves = GameState dict with a version | one format, small diffs, tests; no shared-.tres HP bug | Claude
- 2026-10-19 | Combat timeline on integers with fixed 60 ticks/s, deterministic, returns events | testable, replayable, frame-rate independent | Claude
- 2026-10-19 | Folders by feature (defs/logic/view/tests); logic/ pure; small EventBus | one task reads one folder | Claude
- 2026-10-19 | Blueprint kept as design input only; its WSL2 rule, one-file commits, 120-line cap and statistics rejected (ARCHITECTURE 16) | no source; costs tokens | Claude
- 2026-10-19 | Always-loaded notes <= 24 KB; one task, one model and effort per chat; /handoff every session | Pro limits | Claude (from reem-bot, feras-career)
