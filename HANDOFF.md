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
1. Review docs/design/world.md (cast, djanbeyyah). Send a Gemini or Flow character picture (or let Opus make one).

## Next steps
1. Autonomous prototype run (ultracode), one chat. Model: Opus. Effort: high. Milestones, milestones committed and pushed:
   (a) ask the owner to define "prototype" with multiple-choice questions (DECISIONS 2026-10-21), write
   docs/design/prototype.md (<= 60 lines, acceptance tests); (b) M1 art spike: `tools/art/pixelize.py` and one
   pixel sprite in the look test, docs/design/art-bible.md; (c) combat.md and slice.md; (d) playable
   prototype scene wired to the timeline logic. Use subagents only for work that reads far more than its brief
   (Image Prompt Engineer, Technical Artist, Godot Gameplay Scripter), each with the cheapest fitting model.
2. Local checks on Windows pass (11 tests, 2026-10-21); rerun `tools/check.sh` after each milestone. Model: Haiku. Effort: low.

## Paste-ready prompt
```
Continue the game repo (ferasalm/game). Read HANDOFF.md, then run next step 1: work autonomously toward a playable
prototype. I am a beginner: ask me questions as 2-4 multiple choices, your recommendation first with the why.
Pause for my questions, logins (Google Flow in the built-in browser), CAPTCHAs, downloads and anything costing money.
Commit and push each milestone; /handoff when done or near 150k tokens. Opus, high effort.
```
