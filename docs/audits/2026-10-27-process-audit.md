# Process audit 2026-10-27: what it found, what changed, what it measured (P3.12)
Plan: 2026-10-27-process-audit-plan.md (approved by Feras 10-27, D1-D22). Checklist: 2026-10-27-plan-checklist.md.
Order run: P1 tools -> P2a calibration -> P2b art routes + eye gate -> P0 VISION -> P3 docs -> P4 close.

## Findings (plan top 10) -> outcome
1. Start cost ~89k tokens per chat, repo notes only ~9k of it -> notes trimmed (below); connectors (20.3k) untouched:
   Feras's list below is the remaining lever.
2. Builder roster said four ways -> one line (DECISIONS D1): <= 2 Godot runs + 1 free text run; slots.sh enforces it.
3. slots.sh read 0 runs from a worktree; no memory check (PC froze) -> fixed with test_slots.py; memory floor (P1).
4. BREACH did not fail a run; deleted asserts invisible; assets protected in 15/74 briefs -> gate D6 (protected tests,
   tools/, .github/, assets/; removed checks FAIL; new tests must fail on base), test_gate_d6.py, TEMPLATE D6 (P1, P3).
5. Unsafe launches (unpushed base, agy idle 55 min, stdin hangs) -> base check, 25-min idle watchdog, `< /dev/null`,
   outer timeouts, kill_tree (P1, P2b).
6. Tool bugs (map.py untracked files, check.sh stopping at the first failure, spend log "?", hook read C:\dev\game) ->
   each fixed with a test (P1).
7. Skills routed to retired models; emergency-efficiency let builders push -> one builders skill (D2), builders never
   push (D3) (P2a).
8. Routes written nowhere usable -> flow-media, 3d-model, sprite-bake, players-eye-gate skills + acceptance.md (P2b).
9. Stale lines (Qarnaw, 2.5D, Rydan/Zayd, BRIEFING, a missing TEMPLATE base) -> DECISIONS process-only, CANON for
   content, VISION as north star, design index + 3D archive (P0, P3).
10. Docs at their caps -> LESSONS 100 -> 52 lines, DECISIONS process-only, WORKFLOW.md one home for protocols (P3).
Added beyond the top 10: systems-map + Ripple in every brief (D21), review-* panel (P2a), pre_spend hook (P3).

## Measured against the P1 baseline (docs/USAGE.md)
| measure | before | after | note |
|---|---|---|---|
| always-loaded notes | 25.6 KB | 20.7 KB (-19%) | doc_check 2026-10-27 |
| memory files at start | 9.0k tokens | <= 7.1k | after = this side session mid-chat with rules/code.md loaded: an upper bound |
| skills listing | 7.5k | 6.8k | 4 art skills are path-scoped now |
| system tools / MCP / prompt | 35.0k / 20.3k / 11.0k | 35.7k / 20.3k / 11.0k | not in the repo's hands |
| start cost besides Messages | 82.8k | 80.8k (-2k) | sum of the categories above (USAGE's P3 row misadds them as 88.2k) |
The plan's estimate (89k -> ~60k) is NOT met: the cut needs the connector list below. Builder PASS rate, issues per
build and fix loops get their first real numbers at ops-review (every 5 sessions), against the baseline: 39 of 56
builder runs passed the gate, and Feras's first overnight build drew 25 playtest notes (docs/feras-notes.md).

## Open findings
- skillOverrides "name-only" does not take effect: the 8 persona skills, handoff and emergency-efficiency still list
  full descriptions though settings key both name forms. DECISIONS 10-21 "listed by name only" is unverified; ops-review
  checks the setting's real key format before trusting it.
- Closed in P4: paid MCP tools slipped past tools/pre_spend.py (ElevenLabs creative_generate_*, vidIQ vidiq_generate_*,
  and the Runware connector, whose tool names lack "runware"); the hook now blocks them (test_pre_spend.py).

## Connectors for Feras to switch off (claude.ai connectors are account-wide; Claude never toggles them)
Each connector's tool names load into every chat (~40 tokens a tool; 517 tools = 20.3k).
- Off for game work, recommended: ElevenLabs (157 tools, paid generation), vidIQ (68, paid), Notion (64), Zoom (24),
  Crypto.com (9), Indeed (4), GoDaddy (2), Runware (12, paid; the Runware mistake), OpenRouter MCP connector (25,
  duplicates the user-level openrouter server the builders use). About 365 tools, ~14k tokens a chat.
- Your call (they serve applications and other work): Gmail (30), Google Calendar (9), Drive (11), Sheets (9), Slides
  (4), Docs (2): ~65 tools, ~2.5k tokens.
- Keep: hyper3d (until the credits end ~11-17), blender, cf-agents, openrouter (user), Claude Docs, Cloudflare (23;
  off is fine if no Workers work is planned), scheduled-tasks.

## Sources
code.claude.com/docs/en/best-practices, /features-overview, /memory; anthropic.com/engineering/equipping-agents-for-
the-real-world-with-agent-skills; EvilGenie (futuretech.mit.edu); ImpossibleBench; Godot command-line docs; GUT and
gdUnit4; third-party posts are marked unverified in docs/research/practices.md. Gemini docs: design input only.

## Notes for the other HANDOFF track owners (their sections untouched)
- Neon Glitch / 2D redesign: the Neon map fight has no SFX or VFX (feras-notes 22); flee does nothing and corpses or
  revive are unspecified (notes 23-24): none has a CANON line or test yet. Note 13 (jambiyah on screen) has no check.
- Code id "zayd" is still Rydan in content, saves and assets: the rename row in docs/design/systems-map.md lists
  everything it touches (SaveCodec step included).
- core/event_bus.gd has 7 signals with no emitter or listener outside tests (systems-map EventBus section).
- RPG + menus, Level 1: briefs from now on use the new TEMPLATE (May edit, Ripple, a player-visible test).
- For Feras's word: DECISIONS "combat logic 60 ticks/s" and "min target 60 FPS" predate real-time combat (D15) and
  Android (D17).
