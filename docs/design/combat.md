# Combat rules (v0, for the prototype; numbers are starting values in content/, tuned by the harness)
Timeline basics are built and tested (docs/ARCHITECTURE.md, "Combat"; features/combat/logic/timeline.gd).
Every number below lives in content JSON; code reads it from Defs. Each rule here has a test.

## Battle flow (BattleSim, pure, seeded RNG per battle)
- Units: party on side 0, enemies on side 1, each in a formation slot (0-1 vanguard, 2-3 rearguard).
- step(): one Timeline tick. When a unit reaches COMMAND: a party unit waits for the player; an enemy asks
  BattleAI at once. When a unit reaches ACT its action resolves (below), then victory/defeat is checked.
- Stall guard: battle_rules.max_ticks; reaching it ends the battle as a defeat (tests treat it as a bug).
- Start positions: every unit starts at a seeded random timeline position: party in [party_start_min,
  party_start_max] = [3000, 4500], enemies in [enemy_start_min, enemy_start_max] = [1000, 3000] (battle_rules).
  create(..., seed, ambush, ...): ambush 0 = none; 1 = the party was ambushed (the two ranges swap, and the
  reverse stab below happens); 2 = the party ambushed the enemy (party as normal, enemies start at 0).
- Reverse stab (ambush 1 only): before the first tick the djanbeyyah answers. Zayd (the party unit with def id
  zayd, if present) strikes the lowest-slot living enemy with the action reverse_stab (melee, power 24, one
  hit, knockback 3000, free; in no combatant's move list, so it can't be chosen). Normal damage formula (his
  attack incl. blade, row multiplier, variance) and normal knockback (incl. the blade bonus). BattleSim.opening()
  returns once [reverse_stab (unit_id zayd), damage, knocked_back, down if it dies] and [] afterwards or when
  there is no ambush; step() calls it first if the view did not.
- View query: lands_before(actor, action, target) is true when the actor's cast (COMMAND to ACT at its cast
  speed, statuses included) takes fewer ticks than the casting target needs to reach ACT; false if the target
  is not casting.

## Resolving an action
1. Pay: SP is paid at choose(); a move costing more SP than the unit has can't be chosen.
2. Targets: if the chosen target is down, retarget to the first living valid target on that side; none: the
   act fizzles (event "fizzled").
3. Each hit (hit_count times): damage = max(1, round((power + attack - defense * defense_factor)
   * row_mult * variance)); row_mult = Formation.melee_multiplier for melee moves, else 1.0; variance is a
   seeded random in [1 - damage_variance, 1 + damage_variance]. HP never goes below 0.
4. Timeline effect per hit: Timeline.hit(target, action, bonus). The attacker's knockback_bonus applies to
   the FIRST hit only (no multi-hit stunlock). Only the first hit can cancel a cast; later hits knock back.
   A target at 0 HP gets no timeline effect. A target that just reached COMMAND and is hit goes back to waiting.
5. Status: if the move applies one and the target lives, set it with the status's turns (re-applying refreshes).
6. The actor gains battle_rules.sp_per_act SP (capped at max SP). Each of the actor's statuses loses one turn;
   at 0 it is removed (event "status_ended").
7. A unit that goes down loses its pending cast (phase WAIT, no action or targets), is skipped by the timeline
   and never acts again.
- Valid targets: living units on the other side. A covered rearguard unit (Formation.is_covered) can't be the
  target of a move unless the move has ignores_cover.
- Events (TimelineEvent: kind, unit_id, value, detail), in order: reverse_stab (opening only), command, act (actor), damage (target, amount),
  interrupted / knocked_back (target, new position), status (target), status_ended, down (target),
  fizzled, victory, defeat. The view plays them in this order.

## BattleAI (the same policy plays enemies and, in the harness, the party)
1. If an opposing unit is casting and this unit has an affordable cancel move that can target it: use it on
   the casting unit nearest to ACT.
2. Else pick a random affordable move (seeded), target a random valid target.

## The djanbeyyah (Zayd only; docs/design/world.md)
- Hilt: agility add, cast_speed multiplier, weight, and exactly one ability (an action id) added to Zayd's moves.
- Blade: attack add, knockback bonus (added to the first hit of each of Zayd's actions), weight.
- Merge order: base CombatantDef -> hilt -> blade -> caps. Caps: agility 1-99, cast_speed 0.5-2.0.
  The result is a new CombatantDef (never the shared one from ContentDB).
- CombatantDef gains cast_speed (default 1.0; multiplies every move's cast speed) and knockback_bonus (default 0).

## Starting content (final numbers, tuned by the harness)
| Who | HP | SP | Atk | Def | Agi | Wt | Moves |
|---|---|---|---|---|---|---|---|
| Zayd | 400 | 24 | 20 | 14 | 40 | 3 | djanbeyyah_strike, breaker (+ hilt ability) |
| Bilqis | 280 | 36 | 16 | 9 | 44 | 1 | spark_shot, static_net |
| Concession enforcer (x2) | 420 | 0 | 28 | 14 | 30 | 6 | baton_slam (interrupt resist 0.2) |
| Survey drone | 180 | 12 | 20 | 6 | 48 | 0 | laser_ping, overcharge_beam |

| Move | SP | Power x hits | Melee | Cast | Recovery | Knockback | Notes |
|---|---|---|---|---|---|---|---|
| djanbeyyah_strike | 0 | 10 x 2 | yes | 1.2 | 500 | 800 | |
| breaker | 8 | 18 | yes | 0.9 | 1000 | 2000 | cancels |
| spark_shot | 0 | 14 | no | 1.5 | 300 | 400 | ignores cover |
| static_net | 6 | 4 | no | 1.3 | 400 | 300 | ignores cover; cancels; applies jammed |
| baton_slam | 0 | 20 | yes | 0.8 | 700 | 1200 | an interrupt window |
| laser_ping | 0 | 10 | no | 1.6 | 300 | 500 | ignores cover |
| overcharge_beam | 6 | 30 | no | 0.65 | 1200 | 1500 | slow; ignores cover |
| reverse_stab (ambush) | 0 | 24 | yes | 1.0 | 0 | 3000 | opening only, not choosable |
| quick_slash (swift hilt) | 5 | 6 | yes | 1.8 | 200 | 600 | cancels |
| crushing_blow (anvil hilt) | 6 | 58 | yes | 0.7 | 900 | 2500 | |
Status jammed: 2 turns, wait_speed 0.6, cast_speed 0.6.
Hilts: swift (agility +2, cast x1.03, weight 0.5, quick_slash); anvil (agility -1, cast x0.95, weight 1.5,
crushing_blow). Blades: keen (attack +8, knockback +0, weight 1); broad (attack +5, knockback +1500, weight 2).
Battle rules: defense_factor 0.5, damage_variance 0.1, sp_per_act 3, max_ticks 20000, start ranges as above.
Balance target (harness, auto-play): each pairing wins 60-95%, max gap 25 points, battles 40-90 s of game time.

## Balance (harness, 2026-10-21)
1,000 seeded battles per pairing, BattleAI playing both sides, ambush 0 (tools/run_godot.sh -s
res://features/combat/harness/balance.gd).
```
pairing                     win %   mean secs   interrupts/battle
swift_hilt + keen_blade     83.4        57.3               10.69
swift_hilt + broad_blade    84.5        60.3               10.69
anvil_hilt + keen_blade     73.8        56.8                8.95
anvil_hilt + broad_blade    69.3        60.2                9.30
```
Target met: all pairings 60-95%, widest gap 15.2 points, battles 57-60 s.
