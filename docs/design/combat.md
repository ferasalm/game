# Combat rules (v0, for the prototype; numbers are starting values in content/, tuned by the harness)
Timeline basics are built and tested (docs/ARCHITECTURE.md, "Combat"; features/combat/logic/timeline.gd).
Every number below lives in content JSON; code reads it from Defs. Each rule here has a test.

## Battle flow (BattleSim, pure, seeded RNG per battle)
- Units: party on side 0, enemies on side 1, each in a formation slot (0-1 vanguard, 2-3 rearguard).
- step(): one Timeline tick. When a unit reaches COMMAND: a party unit waits for the player; an enemy asks
  BattleAI at once. When a unit reaches ACT its action resolves (below), then victory/defeat is checked.
- Stall guard: battle_rules.max_ticks; reaching it ends the battle as a defeat (tests treat it as a bug).

## Resolving an action
1. Pay: SP is paid at choose(); a move costing more SP than the unit has can't be chosen.
2. Targets: if the chosen target is down, retarget to the first living valid target on that side; none: the
   act fizzles (event "fizzled").
3. Each hit (hit_count times): damage = max(1, round((power + attack - defense * defense_factor)
   * row_mult * variance)); row_mult = Formation.melee_multiplier for melee moves, else 1.0; variance is a
   seeded random in [1 - damage_variance, 1 + damage_variance]. HP never goes below 0.
4. Timeline effect per hit: Timeline.hit(target, action, attacker knockback_bonus). Only the first hit can
   cancel a cast; later hits knock back. A target at 0 HP gets no timeline effect.
5. Status: if the move applies one and the target lives, set it with the status's turns (re-applying refreshes).
6. The actor gains battle_rules.sp_per_act SP (capped at max SP). Each of the actor's statuses loses one turn;
   at 0 it is removed (event "status_ended").
- Valid targets: living units on the other side. A covered rearguard unit (Formation.is_covered) can't be the
  target of a move unless the move has ignores_cover.
- Events (TimelineEvent: kind, unit_id, value), in order: command, act (actor), damage (target, amount),
  interrupted / knocked_back (target, new position), status (target), status_ended, down (target),
  fizzled, victory, defeat. The view plays them in this order.

## BattleAI (the same policy plays enemies and, in the harness, the party)
1. If an opposing unit is casting and this unit has an affordable cancel move that can target it: use it on
   the casting unit nearest to ACT.
2. Else pick a random affordable move (seeded), target a random valid target.

## The djanbeyyah (Zayd only; docs/design/world.md)
- Hilt: agility add, cast_speed multiplier, weight, and exactly one ability (an action id) added to Zayd's moves.
- Blade: attack add, knockback bonus (added to every hit Zayd lands), weight.
- Merge order: base CombatantDef -> hilt -> blade -> caps. Caps: agility 1-99, cast_speed 0.5-2.0.
  The result is a new CombatantDef (never the shared one from ContentDB).
- CombatantDef gains cast_speed (default 1.0; multiplies every move's cast speed) and knockback_bonus (default 0).

## Starting content
| Who | HP | SP | Atk | Def | Agi | Wt | Moves |
|---|---|---|---|---|---|---|---|
| Zayd | 160 | 24 | 20 | 14 | 40 | 3 | djanbeyyah_strike, breaker (+ hilt ability) |
| Bilqis | 110 | 36 | 16 | 9 | 44 | 1 | spark_shot, static_net |
| Concession enforcer (x2) | 150 | 0 | 18 | 14 | 30 | 6 | baton_slam (interrupt resist 0.2) |
| Survey drone | 70 | 12 | 12 | 6 | 48 | 0 | laser_ping, overcharge_beam |

| Move | SP | Power x hits | Melee | Cast | Recovery | Knockback | Notes |
|---|---|---|---|---|---|---|---|
| djanbeyyah_strike | 0 | 10 x 2 | yes | 1.2 | 500 | 800 | |
| breaker | 8 | 18 | yes | 0.9 | 1000 | 2000 | cancels |
| spark_shot | 0 | 14 | no | 1.5 | 300 | 400 | ignores cover |
| static_net | 6 | 4 | no | 1.3 | 400 | 300 | ignores cover; applies jammed |
| baton_slam | 0 | 20 | yes | 0.6 | 700 | 1200 | slow: an interrupt window |
| laser_ping | 0 | 10 | no | 1.6 | 300 | 500 | ignores cover |
| overcharge_beam | 6 | 30 | no | 0.5 | 1200 | 1500 | very slow; ignores cover |
| quick_slash (swift hilt) | 4 | 8 | yes | 1.8 | 200 | 600 | cancels |
| crushing_blow (anvil hilt) | 6 | 30 | yes | 0.6 | 900 | 2500 | |
Status jammed: 2 turns, wait_speed 0.6, cast_speed 0.6.
Hilts: swift (agility +6, cast x1.25, weight 0.5, quick_slash); anvil (agility -4, cast x0.85, weight 3,
crushing_blow). Blades: keen (attack +8, knockback +0, weight 1); broad (attack +3, knockback +1500, weight 3).
Battle rules: defense_factor 0.5, damage_variance 0.1, sp_per_act 3, max_ticks 20000.
