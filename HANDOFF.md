# HANDOFF (current state only; rewritten by /handoff; max 60 lines)
Last updated: 2026-10-21, session 3 (Opus 5.5, `claude-opus-5-5`, lead; 9 Sonnet 5.5 builder agents): prototype v0.
Plan and estimates: docs/BRIEFING.md. Architecture: docs/ARCHITECTURE.md. Token rules: docs/EFFICIENCY.md.

## Status
- Prototype v0 "Rooftop patrol" (docs/design/prototype.md) is built and wired: F5 boots
  features/prototype/prototype_main.tscn. Walk Zayd (Bilqis follows) on the souq rooftops; the workshop bench
  plays the first-visit dialogue (stand-in portraits), then the hilt/blade menu; touching the patrol starts a
  timeline battle in place (reverse stab when caught from behind); win/lose/retry, then back to walking.
- Built from: combat logic (BattleSim, BattleAI, djanbeyyah merge, balance harness: 69-85% wins per pairing,
  ~60 s battles), battle stage + HUD (timeline bar, intent labels, "will interrupt", tips, banners), rooftop
  (area/tile/look/explore data), pixel art as palette-letter JSON + CharacterVisual, dialogue box, workshop
  menu, saved equipment (GameState v2), TextDB (localization CSVs, "keep" importer).
- Design docs: prototype.md, combat.md (final numbers + harness table), slice.md (owner answers in),
  art-bible.md, portrait-prompts.md, dialogue-notes.md (culture checks).
- `tools/check.sh`: docs, lint, import, art_tools, tests all ok (121 tests). CI on GitHub: green after the MAP fix
  (check `gh run list` once more at the start).
- Seen only by Claude through rendered frames, not played by a person yet. Not verified by eye: Zayd's turn
  before the reverse stab, the end panel after its last resize, FPS of the rooftop and battle on the Latitude.
- Branch `claude/prototype-run`, pushed and merged into `main` (48f4907).

## Waiting on the owner
1. Play the prototype (open the project in Godot 4.7.2, press F5). Tell Claude: FPS on the Latitude, what
   confused you, whether the 4 hilt + blade pairings feel different, and anything that isn't fun.
2. Portraits: paste the prompts in docs/design/portrait-prompts.md into Gemini (Zayd and Bilqis: base + 3
   expressions each), save the PNGs, then a chat runs tools/art/portrait.py on them.
3. A Gemini picture of Zayd (full body, plain background) for the first real 64 px sprite (pixelize.py, then
   your touch-up in Pixelorama: art-bible.md).
4. Read docs/design/dialogue-notes.md and slice.md; correct any culture detail marked (check).

## Next steps
1. Play-test fixes from the owner's notes (tuning in content JSON, small view fixes). Model: Sonnet. Effort: medium.
2. Import the owner's portraits and Zayd sprite through the tools; check them in the game. Model: Sonnet.
   Effort: low.
3. After the prototype verdict: plan M2/M3 from slice.md (talk to NPCs, save/load, Hamoud and taunt, enemy
   cancels, stealth walk, sluice puzzle). Model: Opus. Effort: high. Build with Sonnet agents in worktrees
   (LESSONS 4).

## Paste-ready prompt
```
Continue the game repo (ferasalm/game). Read HANDOFF.md. I played prototype v0; my notes: <FPS, what confused
me, which pairings felt different, what wasn't fun>. Fix what my notes point to (tuning in content JSON first),
ask me 2-4 multiple-choice questions where a choice is mine, run tools/check.sh, render a frame to check
visual fixes, commit, push, merge to main, then /handoff. Sonnet, medium effort.
```
