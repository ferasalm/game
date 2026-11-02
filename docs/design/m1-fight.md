# M1 fight spec: real-time Rydan vs 2 guards on the prison roof (row 3, 2026-11-02; Feras: Hades feel + Sekiro parry)
Pillar 1 (combat feel wins ties). Decisions: Feras 11-02 (moves = move, dash, 3-hit combo, parry with posture and a
dash-counter; special and cast later; soft aim; floating stick + buttons; baton + rifle guards). Every number below is a
[PLACEHOLDER] in content/fight/*.json, tuned by the bot harness and Feras's play, never in code. Ticks = 1/60 s.

## 1. Shape
- One pure, deterministic sim (`features/fight/logic/`, integers, 60 ticks/s, returns events) owns the hero and both
  guards from the moment the roof opening has landed to the end: no scene swap, no "battle start". Patrol, sight, ambush,
  fighting and walking after the win all run in it. RoofScene keeps the plate, opening, fuse box, dialogue, exit.
- View (`features/fight/view/`) feeds one `FightInput` per tick, steps the sim at a fixed 60 Hz accumulator in
  `_physics_process`, and plays the returned events (anims, VFX, SFX, shake, flash, HUD). The view never computes a rule.
- Ground space: logic positions are `Vector2i` in milli-pixels (1000 = 1 px) of ground space (screen y / 0.55); `Ground`
  converts to and from plate pixels; walkability reuses `IsoWalk.can_stand`/`step` through that conversion.
- Dialogue or any pause calls `FightView.set_active(false)`: the sim does not step, nothing is skipped.

## 2. Hero (content/fight/hero.json)
- Move: 8 directions, stick strength scales speed, 330 px/s (the roof rule); face = aim, else move, else last facing.
- Soft aim (`AimAssist`): the attack/parry facing snaps to the best foe inside a 70 degree half-cone within 280 px
  (score = angle + distance); the lunge ends 60 px short of it. Aim source: right stick or mouse if given, else move.
- Light combo, 3 steps (startup/active/recovery ticks; damage; lunge px; hit-stop ticks; posture dealt):
  1: 6/4/10, 12, 36, 4, 10. 2: 5/4/10, 12, 40, 4, 10. 3: 9/5/18, 22, 64, 7, 25 (knockback 90 px). A press in the last 10
  recovery ticks (or the 8-tick input buffer) chains the next step; a miss on step 3 returns to idle. Dash may cancel
  recovery (not startup/active). No other cancel. The hit lands on the first active tick, the clip's impact frame matches.
- Dash: 12 ticks, 170 px, i-frames ticks 1-9, 24-tick cooldown, through foes (no collision), stops at walls, direction =
  move input else facing. A hit absorbed by i-frames = EVADE (see 4).
- Parry (button hold): ticks 0-2 startup; DEFLECT window 12 ticks, the first 6 are PERFECT; still held after = GUARD
  (damage x0.25, posture to Rydan); released or window over without a hit = 10-tick recovery (no move, no dash).
- Rydan: HP 100, posture max 100 (guarded hit adds posture, perfect deflect/evade removes it, recovers 1/tick when not
  guarding); posture full = BROKEN 60 ticks (stunned, takes x1.5). Hit unguarded: HP loss, 6 hit-stop, flinch 18, then 30
  ticks mercy invulnerability. 0 HP = defeat, panel with Retry (restarts the fight, CANON 10-21).
- Counter window: after an EVADE or a PERFECT deflect, the next attack within 40 ticks deals x1.5 (RIPOSTE, a gold slash).

## 3. Guards (content/fight/enemies.json; both reuse the one guard sprite set, no new art)
- Shared: states patrol (follows its room path) -> alert (sees Rydan: 560 px, 110 degree cone; or is hit; or an ally
  alerts it within 600 px) -> role loop -> stagger/broken -> ko. HP, posture max, speeds in content. KO stays KO (test);
  KO = dissolve 60 ticks then despawn (playtest 24, 25). Windups carry ARMOR: a light hit does damage and posture but no
  flinch; only deflect, break or a finisher interrupts. Outside windup/strike a light hit flinches 10 ticks.
- Ambush (CANON 10-21): a hit on an unaware guard from behind deals x2 damage and breaks its posture. Rydan seen = no ambush.
- BATON guard: HP 60, posture 100; chases at 150 px/s to 90 px, WINDUP 18 ticks (telegraph, below), STRIKE active 5 ticks,
  100 px arc 100 degrees, 16 damage, 20 posture to a guarded Rydan; RECOVER 24 ticks (the punish window); cooldown 40;
  every third attack is a 2-hit string (windup 18, strike, 8 ticks, strike). Deflected strike: recover cut to 40 -> STAGGER.
- RIFLE guard: HP 40, posture 70; keeps 300-500 px, strafes; AIM 36 ticks (cast clip, a line from the muzzle to Rydan
  that tracks him until 12 ticks before the shot, then locks), SHOT hits everything on the locked 24 px wide line, 14
  damage, 15 posture; RECOVER 60. A perfect deflect REFLECTS: 25 posture and 8 damage to the shooter. Dashing across the
  line in the locked ticks = EVADE.
- Posture (guard): hits add (10/10/25), perfect deflect 50, evade 20, reflected shot 25; 1 tick regains from 90 ticks of
  no contact. Full = BROKEN 120 ticks (stagger, defenceless, x3 damage FINISHER on the next hit, then posture resets to 40).
- Telegraph: windup/aim shows (a) the guard's tint pulse, (b) a ground ring or the aim line that fills over the windup, (c)
  a short sound cue at windup start and one at the lock/strike. Readable at phone size with no text (acceptance M3).

## 4. Defence outcomes (one resolver, `DefenceRules`)
| hit meets | damage | posture | extra |
|---|---|---|---|
| nothing | full to Rydan | - | flinch, mercy ticks |
| GUARD | x0.25 | + to Rydan | no flinch, small slide |
| DEFLECT (not perfect) | 0 | + half to Rydan, + 15 to attacker | spark |
| PERFECT deflect | 0 | - to Rydan, + large to attacker | white flash, 8 hit-stop, counter window |
| dash i-frames (EVADE) | 0 | + 20 to attacker | afterimage, counter window; once per dash |

## 5. Feel (Hades pillar; acceptance H1-H4, M3, F2)
- Hit-stop ticks: combo 4/4/7, guarded 3, perfect 8, finisher 12 (numbers sourced in docs/research/m1-fight-github.md).
- Hit-stop is sim state (frozen ticks per unit), never Engine.time_scale (a lint test greps features/fight). The view
  mirrors it with IsoActor.freeze. Camera trauma (pure `Trauma`, decays 2/s, shake = trauma^2) on every landed hit,
  finisher, perfect deflect and getting hit. White flash 6 ticks on a hit target (shader). Slash arc, spark burst, perfect
  ring as procedural CPUParticles2D/Line2D, colours from content. SFX per swing (3), hit, guard, deflect, perfect, dash,
  windup cue, shot, ko, mapped in content/audio/sounds.json to files already in assets/audio/sfx (pitch +-6 per play).
- Clip speeds come from content so the clip's impact frame lands on the first active tick (test).

## 6. Input and touch (D17)
Actions attack, dash, parry (+ aim_x/aim_y optional) added to project.godot; keyboard J/K/L and mouse left/right,
gamepad X/A/B-or-shoulder. Touch: floating stick on the left half, attack (168 px), parry and dash (120 px) in an arc on
the right (layout in content/fight/touch.json, % of the viewport, safe-area aware); it calls `Input.action_press` so the
sim sees the same actions. Shown only on touch devices or with the `--touch` flag. Targets >= 96 px at 1080p.

## 7. Harness (deterministic bots, CI)
Seeded `FightBot` policies drive the sim headless: MASHER (attack only) must lose >= 60% in; DASHER (attack + dash, no parry)
wins 30-70%; PARRIER (reads telegraphs, perfect-deflects, finishes) wins >= 80% in 20-45 s. Bands are the F6 balance test.

## 8. Not in M1
Special, cast, SP, items, flee, XP/loot, Hard mode, a second room, new sprite clips (dash uses the run clip plus
afterimage; combo steps reuse the attack clip at three speeds), music changes, Android export itself (row 4 does it).
