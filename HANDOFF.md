# HANDOFF (current state only; rewritten by /handoff; max 60 lines)
Last updated: 2026-10-19, session 1 (Opus 5.5, `claude-opus-5-5`): architecture and foundation.
Plan and estimates: docs/BRIEFING.md. Architecture: docs/ARCHITECTURE.md. Token rules: docs/EFFICIENCY.md.

## Status
- Built and checked in the cloud container: Godot 4.7.2 project; core (EventBus, GameState, ContentDB, Def
  reader); combat timeline and formation logic with tests; sample content; HD-2D look-test scene with FPS label;
  tools (check.sh, run_godot.sh, godot.sh, lint, map, doc check); CI workflow; .claude settings, session hook,
  /handoff skill.
- `tools/check.sh`: docs, lint, import, tests all ok (11 tests).
- Not seen yet: the first CI run on GitHub; the look test on the owner's laptop.
- Branch `claude/loving-galileo-g4170t`, pushed. Not merged into `main` (needs the owner's OK).

## Waiting on the owner
1. Install the must-haves (BRIEFING section 6), open the project, press F5: screenshot, FPS, laptop specs.
2. Answer BRIEFING section 9 (world and cast, combat core, Arabic, merge-to-main OK, title).

## Next steps
1. Read the first CI run; review the look test from the owner's screenshot; set camera, depth of field and
   texel density; log the look decisions. Model: Sonnet. Effort: medium.
2. M1 art spike: `tools/art/pixelize.py` (downscale, palette lock, background key, sheet packing) and one
   Gemini-made character as a pixel sprite in the look test; draft docs/design/art-bible.md. Model: Opus (it judges
   the pictures). Effort: high.
3. Design docs from the blueprint, owner-approved parts only: docs/design/combat.md and slice.md (<= 60 lines each,
   with acceptance tests). Model: Opus. Effort: medium.

## Paste-ready prompt
```
Continue the game repo (ferasalm/game), next step 1 in HANDOFF.md. My laptop: <CPU, RAM, GPU>.
Look test FPS: <n>. Screenshot attached. Answers to BRIEFING section 9: <1..6 or "defaults">.
Sonnet, medium effort. Finish with /handoff.
```
