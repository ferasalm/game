# HANDOFF (current state only; rewritten by /handoff; max 60 lines)
Last updated: 2026-10-22, session 7 (Opus 5.5, `claude-opus-5-5`, lead, high): v0.3 "Painted Rooftops", Phase 2.
Plan: docs/design/v03-plan.md; 3D spec: docs/design/characters-3d.md. New: identity.md (hook motif),
zayd-moves.md (new kit), hilt-stones.md (stones). Owner decisions 2026-10-22: DECISIONS.md.

## Status
- Branch claude/night-sanaa, merged into main at this handoff. Merged this session: Quaternius files staged in
  assets/characters/ (CC0, manifest), Musnad font, djanbeyyah -> Jambiyah rename, battle HUD v3 (thin bars,
  hover cards, "Target: X A" on the top bar), Musnad-only signs and Musnad menu lines (no Arabic script; test),
  own arc_discharge sound + ui_* ids + loudness fixes, identity spec, Zayd kit and hilt stone designs.
- Stopped mid-work at 83% of the 5-h window (WIP commits, not checked, NOT merged), worktree branches:
  - B4 3D characters: worktree-agent-ae63c322574a6f227 (3 commits; was on "trail and smear", spec section 4).
  - Workshop bench prop: worktree-agent-a4cf40c0e9518e744 (1 WIP commit; renders not made).
  - Balance pass: worktree-agent-a7a39e37292830460 (1 WIP commit; was waiting on a harness run).
  - Zayd kit and stones builders: stopped at once, nothing committed: restart them from the design docs.
- Polish noted: Musnad line beside "Paused" too small; battle "Target:" text small; target cone large;
  `defeat` sound loud, vfx_stab and vfx_overclock quiet. Owner has not played v0.3 yet.
- Inbox: Abu Nabil 3/4 on green (dialogue portrait later), Flow model pictures (Zayd, Bilqis, Abu Nabil, jambiyah,
  sabil concept) for image-to-3D later (characters-3d.md section 8).

## Efficiency rules for the next sessions (owner asked 2026-10-22)
- At most 2 agents at a time on Pro; one wave per 5-h window. Small jobs inline (rename and staging were cheap).
- Resume a stopped builder with ONE fresh agent in its worktree (no isolation, brief: "git log, finish, check"),
  never by resuming the old transcript (LESSONS 4).
- Sonnet medium by default; high only for big builds; Opus only for lead, design and review.

## Next steps (one per chat)
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
