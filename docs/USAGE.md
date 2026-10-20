# Usage ledger

One row per session, so the estimates in docs/BRIEFING.md are recalibrated from real numbers after three build
sessions. "Window %" = the share of the Pro 5-hour window the session used (from `/usage` at start and end).

| Date | Model | Effort | Task | Window % | Result |
|---|---|---|---|---|---|
| 2026-10-19 | Opus 5.5 (`claude-opus-5-5`) | session default | Architecture, foundation, briefing | not measured (cloud session) | Foundation built, checks pass |
| 2026-10-19 | Sonnet 5.5 (`claude-sonnet-5-5`) | medium | Look v1 review from owner screenshot (81 FPS), log decision | not measured | Look v1 accepted; no code change |
| 2026-10-21 | Opus 5.5 (`claude-opus-5-5`) lead + 9 Sonnet 5.5 subagents (~1.6M subagent tokens) | high (lead), medium/high (agents) | Autonomous prototype run: spec, art spike, slice plan, combat logic, rooftop, dialogue, workshop, battle view, main loop | not measured | Prototype v0 playable in tests and renders; 121 tests; owner play-test pending |
