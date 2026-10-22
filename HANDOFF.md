# HANDOFF (current state only; rewritten by /handoff; max 60 lines)
Last updated: 2026-10-22, session 7 (Opus 5.5, `claude-opus-5-5`, lead, high): v0.3 "Painted Rooftops", Phase 2.
Plan: docs/design/v03-plan.md; 3D spec: docs/design/characters-3d.md. New: identity.md (hook motif),
zayd-moves.md (new kit), hilt-stones.md (stones). Owner decisions 2026-10-22: DECISIONS.md.

## Status
- Merged to main: Quaternius files, Musnad font, Jambiyah rename, HUD v3, Musnad-only text, arc sound + ui_*
  sounds, identity spec, kit and stones designs, GEMINI.md (git log for details).
- Stopped mid-work at 83% of the 5-h window (WIP commits, not checked, NOT merged), worktree branches:
  - B4 3D characters: worktree-agent-ae63c322574a6f227 (3 commits; was on "trail and smear", spec section 4).
  - Workshop bench prop: worktree-agent-a4cf40c0e9518e744 (1 WIP commit; renders not made).
  - Balance pass: worktree-agent-a7a39e37292830460 (1 WIP commit; was waiting on a harness run).
  - Zayd kit and stones builders: stopped at once, nothing committed: restart them from the design docs.
- Polish: small Musnad line by "Paused", small "Target:" text, big target cone, loud `defeat` sound.
- Inbox: Abu Nabil 3/4 portrait (green) and Flow model pictures for image-to-3D (characters-3d.md 8).

## Efficiency
At most 2 agents at once (DECISIONS 2026-10-22). Resume a stopped builder with ONE fresh agent in its worktree.

## Next steps (one per chat)
0. Gemini builder (agy): rules in GEMINI.md (verified loading). Headless commands still blocked (LESSONS 6);
   first Gemini task = Zayd kit from a Claude brief, run by Feras in an agy terminal in its own worktree.
   Model: Opus lead writes the brief and reviews (Gemini 3.8 Flash high builds). Effort: medium.
1. Finish B4 in its worktree (fresh Technical Artist agent, Sonnet high, no isolation), review renders, merge.
   Model: Opus lead (medium). Effort: high for the builder.
2. Zayd kit (zayd-moves.md + hilt-stones.md PerkDef kinds), then stones (hilt-stones.md): one Sonnet high
   builder each, one after the other; then finish the balance pass (its worktree) on the new kit. Model: Sonnet. Effort: high.
3. Workshop bench: finish in its worktree (Sonnet medium). Hook motif build (identity.md; Godot Shader Developer,
   Sonnet high). Owner picks the logo's Musnad letter from renders. Model: Sonnet. Effort: medium.
4. Phase 3: title menu, frame_speaker wiring, smoke play-through, fps_probe (look B to 90), Code Reviewer (Opus,
   high), merge, Checkpoint 2: Feras plays v0.3. Model: Opus lead. Effort: high.

## Paste-ready prompt
```
Continue the game repo (ferasalm/game), v0.3. Read HANDOFF.md. Do Next step 1 only: start ONE fresh Technical
Artist agent (Sonnet, high) inside the B4 worktree (no isolation) to finish docs/design/characters-3d.md from
its WIP commits, then review renders, merge, run tools/check.sh, /handoff. At most 2 agents at once. Opus lead.
```
