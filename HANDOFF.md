# HANDOFF (current state only; rewritten by /handoff; max 60 lines)
Last updated: 2026-10-19, session 2 (Sonnet 5.5, `claude-sonnet-5-5`): look v1 reviewed, accepted.
Plan and estimates: docs/BRIEFING.md. Architecture: docs/ARCHITECTURE.md. Token rules: docs/EFFICIENCY.md.

## Status
- Built and checked in the cloud container: Godot 4.7.2 project; core (EventBus, GameState, ContentDB, Def
  reader); combat timeline and formation logic with tests; sample content; HD-2D look-test scene with FPS label;
  tools (check.sh, run_godot.sh, godot.sh, lint, map, doc check); CI workflow; .claude settings, session hook,
  /handoff skill.
- `tools/check.sh`: docs, lint, import, tests all ok (11 tests).
- GitHub CI run 39335654359 (check #1) on 780e986: success, log read ("all checks passed", 7 s).
- Look v1 seen (owner screenshot, vsync off): 81 FPS on the Latitude (~35% over 60), hero clear, far blur readable.
  Accepted as is (DECISIONS). Texel density waits for a real sprite (step 1 below).
- Branch `claude/new-session-0mxnqs`, pushed. Not merged into `main` (needs the owner's OK).

## Waiting on the owner
1. Answer BRIEFING section 9 (world and cast, combat core, Arabic, merge-to-main OK, title).

## Next steps
1. M1 art spike: `tools/art/pixelize.py` (downscale, palette lock, background key, sheet packing) and one
   Gemini-made character as a pixel sprite in the look test (this sets texel density); draft
   docs/design/art-bible.md. Model: Opus (it judges the pictures). Effort: high.
2. Design docs from the blueprint, owner-approved parts only: docs/design/combat.md and slice.md (<= 60 lines each,
   with acceptance tests). Model: Opus. Effort: medium.

## Paste-ready prompt
```
Continue the game repo (ferasalm/game), next step 1 in HANDOFF.md (M1 art spike). A Gemini character picture is attached.
BRIEFING section 9: defaults. Opus, high effort. Finish with /handoff.
```
