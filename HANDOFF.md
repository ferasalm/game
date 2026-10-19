# HANDOFF (current state only; rewritten by /handoff; max 60 lines)
Last updated: 2026-10-19, session 1 (Opus 5.5, `claude-opus-5-5`): architecture and foundation.
Plan and estimates: docs/BRIEFING.md. Architecture: docs/ARCHITECTURE.md. Token rules: docs/EFFICIENCY.md.

## Status
- Built and checked in the cloud container: Godot 4.7.2 project; core (EventBus, GameState, ContentDB, Def
  reader); combat timeline and formation logic with tests; sample content; HD-2D look-test scene with FPS label;
  tools (check.sh, run_godot.sh, godot.sh, lint, map, doc check); CI workflow; .claude settings, session hook,
  /handoff skill.
- `tools/check.sh`: docs, lint, import, tests all ok (11 tests).
- GitHub CI run 39335654359 (check #1) on 780e986: success, log read ("all checks passed", 7 s).
- Look test seen (owner: Dell Latitude 5520, i7-1185G7, 16 GB, Iris Xe, 60 FPS, likely vsync-capped). Look v1 applied
  (DECISIONS): closer camera, softer DoF, vsync off. Pixels not re-checked: owner to rerun F5 and send screenshot + FPS.
- Branch `claude/loving-galileo-g4170t`, pushed. Not merged into `main` (needs the owner's OK).

## Waiting on the owner
1. Pull, press F5 again: screenshot and FPS (vsync is now off, so the number is real headroom).
2. Answer BRIEFING section 9 (world and cast, combat core, Arabic, merge-to-main OK, title).

## Next steps
1. Review the look test from the owner's screenshot and FPS; set camera, depth of field and
   texel density; log the look decisions. Model: Sonnet. Effort: medium.
2. M1 art spike: `tools/art/pixelize.py` (downscale, palette lock, background key, sheet packing) and one
   Gemini-made character as a pixel sprite in the look test; draft docs/design/art-bible.md. Model: Opus (it judges
   the pictures). Effort: high.
3. Design docs from the blueprint, owner-approved parts only: docs/design/combat.md and slice.md (<= 60 lines each,
   with acceptance tests). Model: Opus. Effort: medium.

## Paste-ready prompt
```
Continue the game repo (ferasalm/game), next step 1 in HANDOFF.md. Laptop: Latitude 5520, i7-1185G7, 16 GB, Iris Xe.
Look v1 FPS: <n>. Screenshot attached. BRIEFING section 9: defaults.
Sonnet, medium effort. Finish with /handoff.
```
