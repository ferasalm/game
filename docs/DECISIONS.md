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
- 2026-10-19 | Laptop (Dell Latitude 5520, i7-1185G7, 16 GB, Iris Xe, 60 FPS look test) is the minimum target: Forward+ stays, effects must hold 60 FPS here | measured by owner | Claude
- 2026-10-19 | Look v1: camera (0,6,8.5), FOV 30, DoF near 5 far 12 amount 0.1, 16 px = 1 m; character larger on screen, far blur softer; vsync off in look test to show real FPS | owner screenshot: hero small, back half too blurry | Claude
- 2026-10-19 | Look v1 accepted as is (camera, FOV 30, DoF 5/12/0.1): 81 FPS on the laptop with vsync off = ~35% headroom over 60; texel density decided at the M1 art spike with a real sprite | owner screenshot + FPS: hero clear, far blur readable | Claude (owner may veto)
- 2026-10-19 | World: cyberpunk futuristic Sana'a, Yemen (replaces pre-Islamic South Arabia and the Malik/Thurya/Dharib cast) | Feras BRIEFING q2 | Feras
- 2026-10-19 | Cast: Claude invents it (docs/design/world.md), owner reviews | Feras: "come up with them" | Feras
- 2026-10-19 | Combat core: Grandia-style timeline with interrupts (default), may change later | Feras BRIEFING q3 | Feras
- 2026-10-19 | Language: English first, Arabic later | Feras BRIEFING q4 | Feras
- 2026-10-19 | Standing OK: each session merges its checked work into main at the end | Feras BRIEFING q5 "ok to merge" | Feras
- 2026-10-19 | Title stays "Qarnaw" for now, may change later | Feras BRIEFING q6 | Feras
- 2026-10-19 | Hero's weapon is a djanbeyyah in two parts, hilt and blade, each upgraded or swapped separately (design: docs/design/world.md) | Feras: combos give varied combat styles | Feras
