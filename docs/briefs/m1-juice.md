# Brief: m1-juice (agy medium for shaders and effects, GDScript; RUN_KIND=godot; review by DeepSeek)
You are in your own worktree on branch gemini/m1-juice (made from origin/m1-juice-base: m1-defs and m1-sim merged, plus the locked
tests; pushed). Follow GEMINI.md, including <review_misses>. Load the technical-artist skill.
Pattern: features/neon/roof/view/roof_burst.gd, features/neon/view/iso_actor.gd, features/neon/roof/view/roof_rain.gdshader
Timebox: 45 min. First commit within 15 min, then small WIP commits.

## Why
Feras 10-29: "game juice", combat feel first; playtest notes 23 (no SFX/VFX on attacks), 24 (corpses linger), 25. The hit has to
feel flashy and edgy: freeze, white flash, shake, sparks, a sound with pitch variation. Pillar served: 1 Hades-feel combat.

## Read first
The locked tests (read-only). docs/design/m1-fight.md section 5, docs/design/acceptance.md H1-H4 and M3. features/neon/view/
iso_actor.gd, content/audio/sounds.json and core/audio_director.gd (how a sound id plays), the file list of assets/audio/sfx.

## What to build
1. IsoActor additions (smallest edit): `flash(ticks)` white hit-flash through a canvas_item shader, `dissolve(ticks)` that fades
   and then emits `dissolved`, `speed_scale: float` for clips; `freeze(seconds)` stays. Shaders in features/fight/view/.
2. features/fight/view/fight_fx.gd (Node): `play(event: FightEvent, actors: Dictionary)` maps events to effects: swing arc and
   spark (CPUParticles2D/Line2D, colours from content, pooled, no per-frame allocation), freeze mirrors event hit-stop on both
   actors, flash 6 ticks on the hit target, Trauma shake applied to a Camera2D offset, perfect ring and white pulse, finisher
   slow zoom 4%, evade afterimages, telegraph tint pulse and a ground ring or aim line, ko dissolve then free.
3. Sounds: add content/audio/sounds.json ids swing_1..3, guard_block, deflect, perfect_deflect, dash, windup_cue, shot, mapped
   to existing files in assets/audio/sfx (no new assets); FightFx plays them with pitch +-6% via AudioDirector.
4. A render helper tools/ is NOT touched; frames come from the view part's shot scene.

## Do NOT edit
D6 defaults, protected by tools/build_gate.py without being listed. Keep this prose free of backticks outside May edit.
`features/fight/logic/`
`features/fight/defs/`

## May edit
`features/neon/view/iso_actor.gd`
`content/audio/sounds.json`

## Ripple
iso_actor.gd is used by the cold open, roof and (until archive) map battle: new members only, no behaviour change when unused;
python tools/ripple.py lists its tests. sounds.json ids: test_sounds checks every file exists; sound ids appear in sound tests.

## Pre-mortem
Player: effects stack into noise on a combo -> pooled, capped to 24 live particles, tested. Gate: effects need a window -> tests
run the nodes headless and assert state (flash timer, trauma value, particle count). Review: Engine.time_scale sneaks in -> lint test.

## Tests
- features/fight/tests/test_fight_fx.gd :: a hit event freezes both actors the event's ticks (IsoActor.freeze), flashes the
  target, adds trauma; a perfect adds more than a guard; a finisher zooms; a ko dissolves then frees; live particles <= 24.
- features/fight/tests/test_fight_sounds.gd :: every new id has a file that exists; three swing ids differ; pitch jitter in range.
- features/fight/tests/test_no_time_scale.gd :: no Engine.time_scale in features/fight (H3).
- features/neon/tests/test_iso_actor.gd stays green; flash/dissolve default off.
- player-visible: a frame grab 2 ticks after a hit shows the target sprite white (mean >= 0.8) and 30 ticks later normal.

## Checklist
- file: features/fight/view/fight_fx.gd
- has: features/neon/view/iso_actor.gd :: func flash
- test: features/fight/tests/test_fight_fx.gd :: test_hit_flash_and_freeze

## Proof
`bash tools/check.sh` raw last 15 lines; final message ends with `Built-by: Gemini 3.8 Flash (agy)`.
