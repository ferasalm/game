# Usage ledger

One row per session, so the estimates in docs/BRIEFING.md are recalibrated from real numbers after three build
sessions. "Window %" = the share of the Pro 5-hour window the session used (from `/usage` at start and end).

| Date | Model | Effort | Task | Window % | Result |
|---|---|---|---|---|---|
| 2026-10-19 | Opus 5.5 (`claude-opus-5-5`) | session default | Architecture, foundation, briefing | not measured (cloud session) | Foundation built, checks pass |
| 2026-10-19 | Sonnet 5.5 (`claude-sonnet-5-5`) | medium | Look v1 review from owner screenshot (81 FPS), log decision | not measured | Look v1 accepted; no code change |
| 2026-10-21 | Opus 5.5 (`claude-opus-5-5`) lead + 9 Sonnet 5.5 subagents (~1.6M subagent tokens) | high (lead), medium/high (agents) | Autonomous prototype run: spec, art spike, slice plan, combat logic, rooftop, dialogue, workshop, battle view, main loop | not measured | Prototype v0 playable in tests and renders; 121 tests; owner play-test pending |
| 2026-10-21 | Opus 5.5 (`claude-opus-5-5`) lead + 9 Sonnet 5.5 builders + 1 Haiku 5.5 helper (~2.8M subagent tokens) | owner's Ultracode (lead), medium/high (Sonnet), medium (Haiku) | v0.2: night old Sana'a, skyline, rooftop dressing, prosthetics + rarity + loot, UI, motion + VFX + battle camera, sound + Flow music, real portraits and sprites | started at ~80% of the 5-h window; hit the limit twice | All merged to main; 273 tests; ~110 FPS prototype, ~137 battle on the Latitude; owner play-test pending |
| 2026-10-21 | Opus 5.5 (`claude-opus-5-5`) lead + Sonnet/Opus/Haiku agents (3 Explore, Plan critic, 5 designers, look spike, 2 foundation builders) | xhigh (lead), low-high (agents) | v0.3 plan mode audit + plan; Phase 0 specs and contract stubs; Phase 1 + look spike started | hit ~94% of the 5-h window; 4 agents dropped on API errors once | Plan approved; specs + stubs pushed; builders stopped with WIP notes in their worktrees |
| 2026-10-21 | Opus 5.5 (`claude-opus-5-5`) lead + Sonnet builders (P1a, B1, B2, B3, B5, B6, B2 finisher), Opus (spike, 3D design), Haiku (rename, docs, prompts), Sonnet Explore | high (lead), low-high (agents) | v0.3 Phase 1 + spike merged, Checkpoint 1, 3D-character pivot (plan mode, spec, stubs), Phase 2 B1/B2/B3/B5/B6 merged | hit the 5-h limit once; one computer crash | 498 tests; B4 (3D characters) waits on the owner's Quaternius downloads |
