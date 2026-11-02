# M1 build plan (row 3 output; row 4 runs it). Spec docs/design/m1-fight.md, types docs/design/m1-fight-api.md
Decided by Feras 11-02: M1 moves = move, dash, 3-hit combo, parry (Sekiro: posture + perfect deflect + dash-counter);
special and cast later; soft aim; floating stick + 3 buttons; baton + rifle guards. Flow per part: low-cost-pipeline skill.

## Parts, order, workers (disjoint May edit sets; parts_plan.py checks them)
| Wave | Part (brief) | Owns | Worker | Needs |
|---|---|---|---|---|
| 1 | m1-defs | data types, defs, content/fight, rooms kind/facing, 4 text keys | cf DeepSeek high | - |
| 2 | m1-hero | Ground, InputBuffer, AimAssist, Posture, DefenceRules, Trauma, HeroMachine | cf DeepSeek max | 1 |
| 2 | m1-guards | Sight, GuardMachine (baton, rifle) | cf DeepSeek max | 1 |
| 2 | m1-touch | project.godot actions, touch layout and controls | cf GLM-5.3 max | 1 |
| 3 | m1-sim | HitResolver, FightSim, determinism | cf DeepSeek max | 2 hero, guards |
| 4 | m1-juice | IsoActor flash/dissolve, FightFx, sounds.json | agy medium | 3 |
| 4 | m1-harness | bots, runner, balance bands | cf DeepSeek max | 3 |
| 5 | m1-view | FightView, FightHud, RoofScene and NeonGame wiring, shot scene | cf DeepSeek high | 3, touch, juice |
| 6 | m1-archive | delete the turn-based code (tag turn-based-archive first) | cf DeepSeek fast + high | 5 |
Wave n+1 starts when wave n is merged and the base is pushed; parts of one wave run in parallel (CAP_CF 3, agy 2).
Each part: critic read of the brief by another family, scope run for red tests, the head READS EVERY TEST, lock_tests.sh,
build, part_report, cross_review by the other family, merge_run.sh, check.sh to a file.

## Gates after the build
1. check.sh green (CI too). 2. m1-harness bands pass and the head reads the table; a failing band is fixed by a number in
content/fight/, never by loosening the band. 3. Opus plays the shot scene frames: players-eye-gate skill, eye_gate.sh
(colours > 256, fps >= 24, font >= 18 px at 720p), review-player on the frames, review-feras last. 4. Android export in CI (D17,
row 4) and a touch smoke on Feras's phone. 5. Then row 5: Feras plays PC and phone; notes become fix-pass rows.

## Open items the build must not decide
- Numbers are [PLACEHOLDER]: the head tunes them from the harness table, Feras from play. Any change of a rule (not a number)
  goes to Feras with a pick.
- New art asks (not M1): a real dash clip, 3 distinct combo clips, a guard stagger clip: row 7 list.
- Music for the fight: existing battle tracks stay mapped by screen_music.json; no new track in M1.
