# Neon Glitch: vision (Feras owns this file; it changes only by a logged decision)
Feras's P0 interview (2026-10-27), drafted by Opus 5.5 from the bible, DECISIONS and retro C. review-canon flags drift.

## Vision and mission
- **Vision**: Hades-feel action in a cyberpunk Old Sana'a: a short, dense, linear story of corrupted trust, told in a
  living, full-colour ink-comic world.
- **Mission**: one person and a team of AI tools make a small, polished action RPG that earns its price: a free demo
  first, then a premium game. $0 art budget; free routes first (Flow before any paid API); every session leaves the system better.

## Pillars (every spec and brief names the one it serves; when time or budget forces a cut, combat feel wins: Feras 10-27)
1. **Hades-feel combat**: real-time, fast, readable, flashy. Move, dash (i-frames), attack, special, cast; enemy
   telegraphs; hit-stop, white flash, camera shake, VFX and SFX on every hit.
2. **Living Old Sana'a**: cyberpunk Yemen as the world itself: tower-houses, qamariya light, jambiya, qishr, umbrellas
   against acid rain, Musnad signs. Full colour, smooth 24-30 fps sprites; lights that move, flicker and cast shadows.
3. **Corrupted-trust story**: linear and character-driven (the bible: Rydan, the playable hero; Zayd, Bilqis, Roya), shown through play
   in short, sharp lines. No supernatural: technology explains everything.
4. **Small, dense, replayable**: short chapters, every minute polished. Replay comes from Hard mode and challenges,
   not procedural runs. Cheap enough for one person to make.
Not this game: a roguelite (runs, death-return, seeded maps), turn-based battles (archived), a live service.

## Players, platforms, money
- Players: Hades-like action fans on PC; players from Yemen and the region who rarely see their culture in games.
- PC (Steam) leads. The Android build stays green in CI and is tested on Feras's phone at every milestone. iOS comes
  later, its cost Feras's decision.
- Premium full game plus a free demo. The price comes from comparables research (market-player skill), with Feras's OK.

## Objectives (measured; ops-review and market-player check them)
| Id | Objective | Measure | When |
|---|---|---|---|
| O1 | Public free demo, 20-30 min | Out on itch.io or a Steam page: the bible's 6 demo beats (cold open to endpoint) | ~2027-04 |
| O2 | Fun | 5+ outside players: fun >= 4/5; core action used unprompted within ~30 s | demo |
| O3 | The look bar | Eye gate before Feras plays: every acceptance.md line passes (colours > 256, >= 24 fps, font >= 18 px at 720p) | every build |
| O4 | Fewer notes from Feras | Notes per build fall from 25 (10-27) to <= 10; none repeats (docs/feras-notes.md) | every milestone |
| O5 | Cheaper builds | Claude window % per merged feature falls against the P1 baseline (docs/USAGE.md) | every ops-review |
| O6 | Phone | The current milestone plays with touch on Feras's Android phone | every milestone |

## Roadmap (after M0, the process audit P1-P4; Feras plays gated builds twice a week; each milestone ends on his OK)
- **M1 Look-and-feel spike, prison roof.** Contents: real-time Rydan vs 2 guards (move, dash, attack, special, cast,
  hit feedback); full-colour 24-30 fps bakes; 2D lights with normal maps and shadows (qamariya glow, flicker); a living
  plate (wind, moving objects, particles); walk mask and occluders from object masks; portrait cut-outs checked in
  dialogue and menus; the UI style guide (docs/design/ui.md); Mobile renderer, touch, Android export in CI. Done: eye
  gate passes, Feras OKs it on PC and phone, the M1 notes in docs/playtest/2026-10-27.md are closed.
- **M2 Prologue.** Contents: the start flow (one seamless title), the Roya cold open, the prison-escape tutorial,
  "Earlier": Zayd's first shift, arrest and prison arrival, then back to the escape; a narrative pass on every
  line; music and SFX. Done when Feras OKs it and a persona walkthrough has run.
- **M3 Demo** (O1, O2). Contents: the bible's demo endpoint, Hard mode, an outside playtest (5 players, survey plus
  telemetry), a store page draft, and a Steam page once Feras OKs the fee.
- **M4 Full game**: chapters to Numan's fall, then Bilal's return (a boss) and Kanan's exposure; planned from M3's data.
- **Art clock**: the ~50 Hyper3D credits expire around 2026-11-17. The art chat right after P4 spends them (cast,
  props, title video) and proves the free 3D route before access ends.

## Market brief (draft; research by others; numbers unverified until sourced)
- Hook: Hades-feel fights in a cyberpunk Old Sana'a. The image: Rydan under a qamariya window on an acid-wet roof.
  The 15 s clip: a dash-strike combo with hit-stop and neon VFX.
- Comparables to research, with sources: Hades, Transistor, Pyre, Katana ZERO, cyberpunk and Middle-East-set indies.
- Budget: $0 art; store fees (Steam ~$100 per game, Google Play ~$25; verify) only with Feras's OK; no ads before M3.

## Risks (advisor)
- Touch: real-time combat on a phone is the hardest control problem; M1 must play well there before more combat.
- Scope: the demo is the only target until O1; anything that serves no pillar waits. Hyper3D: prove the free route first.
