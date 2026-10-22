# Zayd's moves: audit and redesigned kit (design v1, 2026-10-22; numbers are [PLACEHOLDER] until the harness)
Owner ask (2026-10-22): Zayd's moves overlap; each should have its own creative job so combat is unique and fun.
Fixed facts kept: timeline with interrupts, readable intent + "will interrupt" preview, knockback bonus on the
first hit only, reverse-stab ambush, prosthetics grant tech moves paid from SP, hilt + blade swapped separately.
Stones that change these moves: docs/design/hilt-stones.md.

## 1. Audit: every move Zayd can have today (content/combat/actions.json)
Damage below = one hit at Atk 26 (base 20 + rustwire 6) on an enforcer (Def 14 x 0.5 = 7), before row and variance.
| Move | Source | SP | Cast | Power x hits (dmg) | Knockback | Cancels | Job today |
|---|---|---|---|---|---|---|---|
| jambiyah_strike | base | 0 | 1.2 | 10 x 2 (29 x 2) | 800 | no | free damage |
| breaker | base | 8 | 0.9 | 18 (37) | 2000 | yes | interrupt |
| elder_cut | grandfather hilt | 4 | 1.4 | 12 (31) | 900 | yes | interrupt |
| quick_slash | swift hilt | 5 | 1.8 | 6 (25) | 600 | yes | interrupt |
| crushing_blow | anvil hilt | 6 | 0.7 | 58 (77) | 2500 | no | big damage |
| piston_jab | salvage_arm, arc_arm | 5 | 1.5 | 8 (27) | 700 | yes | interrupt |
| arc_discharge | arc_arm | 10 | 0.9 | 14 to all foes (ranged) | 600 | no | area damage |
| reactive_guard | cradle_spine (not obtainable) | 5 | 2.0 | 0 | 0 | no | self guard x0.6 |
| reverse_stab | ambush opening, not choosable | 0 | 1.0 | 24 (43) | 3000 | no | opening punish |
Overlaps and why:
- Four interrupts (breaker, elder_cut, quick_slash, piston_jab). The start loadout (grandfather + salvage_arm) holds
  three of them in four moves: the only question the player meets is "which cancel", and the answer is always the
  cheapest fast one.
- breaker is dominated: elder_cut costs half the SP and casts 55% faster; breaker only adds 6 power and 1100 knockback.
- crushing_blow out-damages breaker per SP by about 4x (77 for 6 vs 37 for 8) with no downside: once owned, it is
  the only attack worth SP. No move has a cost beyond SP, so there is no risk/reward choice.
- Nothing in Zayd's kit plays with Bilqis (static_net's jammed status), with formation (only arc_discharge reaches
  a covered rearguard), or with delay (pushing a foe back without cancelling it).

## 2. Design goals for the kit
One verb per move, on the timeline: build, interrupt, counter, tempo, commit, delay, spread. Exactly one base
interrupt (breaker), so the "will interrupt" read stays the hero moment. Any loadout shows 4-5 moves: base 2 +
hilt 1 + prosthetic 1-2. Ids stay (less churn in tests and saves); names, numbers and jobs change.

## 3. The redesigned kit (7 choosable moves + the reverse stab)
| # | Id (display, flavour name) | Source | SP | Cast | Target | Job |
|---|---|---|---|---|---|---|
| 1 | jambiyah_strike (Jambiyah Strike, "Darba") | base | 0 | 1.2 | foe | build: the SP engine |
| 2 | breaker (Breaker, "Kasr") | base | 7 | 0.9 | foe | interrupt: the only base cancel |
| 3 | elder_cut (Elder's Patience, "Sabr al-Jadd") | grandfather_hilt | 3 | 2.0 | self | counter window |
| 4 | quick_slash (Gazelle Step, "Khatfat al-Ghazal") | swift_hilt | 4 | 1.8 | foe | tempo: act again sooner |
| 5 | crushing_blow (Flash Flood, "Sayl") | anvil_hilt | 8 | 0.7 | foe | commit: big hit, exposed while casting |
| 6 | piston_jab (Piston Shove, "Daf'a") | salvage_arm, arc_arm | 4 | 1.5 | foe, ignores cover | delay without cancel |
| 7 | arc_discharge (Arc Discharge, "Barq") | arc_arm | 10 | 0.9 | all foes | spread + payoff on netted foes |
| - | reverse_stab (Reverse Stab, "Radd") | ambush opening; Sabr's counter | 0 | - | foe | punish |

Move details (effect in engine terms; "today" = supported now; "NEW" = needs code, see section 4)
1. Jambiyah Strike: power 10 x 2, kb 800 on the first hit (today). NEW `sp_gain: 2`: +2 SP on top of the rules'
   3 when at least one hit landed. Decision: bank SP now for a breaker later, or spend. Tell: two quick cuts, a
   bright SP pip flies from the target to Zayd's SP bar.
2. Breaker: power 18, kb 2000, cancels (all today); SP 8 -> 7. With no cheaper cancel beside it, the
   "will interrupt" preview (lands_before) decides every use: spend 7 of 24 SP to erase a cast, or let it land.
   Bilqis's static_net jams a caster (cast x0.6), which turns a "won't land" into "will interrupt" (today).
   Tell: overhead hook-blade swing; on interrupt a gypsum-white shatter ring and the foe's icon flies to 2500.
3. Elder's Patience: self, recovery 0, applies NEW status `poised` (1 turn = until Zayd's next act ends;
   damage_taken 0.5, today). NEW counter: the first hostile melee hit on a poised Zayd triggers reverse_stab at the
   attacker at once (BattleResolver.strike, today) and ends `poised`. Ranged hits are not countered (unless the Eye
   Bead stone). Decision: read the enemy intent (it shows its target): an enforcer winding up a baton_slam on Zayd
   = stance now; if the foe targets Bilqis, the stance is wasted. Tell: Zayd sinks low, hand on the hilt at his
   belt, a carnelian glint; the counter replays the ambush reverse-stab animation with a long hit_stop.
   Fiction: the grandfather's hilt is what made the hooked blade strike behind.
4. Gazelle Step: power 8, kb 600, no cancel. NEW `after_act_pos: 4500` (normal landing is 2000 - recovery):
   Zayd's next command comes ~1.2 s sooner. Decision: trade damage for tempo, e.g. step, then breaker a cast that
   was out of reach; or two acts before the drone's overcharge_beam. Tell: afterimage blur; Zayd's timeline icon
   lands visibly ahead of the others with a short whoosh.
5. Flash Flood: power 58, kb 2500, recovery 900 (today). NEW `cast_status: exposed` (damage_taken 1.5) from choose
   until the act resolves, is interrupted, or Zayd goes down. A baton_slam (44) becomes 66. Decision: commit when
   foes are far from ACT (safe), or gamble while one is about to strike. Jammed foes move slower, so a net first
   makes the window safer (team play, no extra code). Tell: Zayd lifts the blade overhead, a red rim light and an
   "exposed" icon on his card; the impact uses the longest hit_stop of the kit.
6. Piston Shove: power 6, kb 2600, ignores_cover, no cancel (all today; SP 5 -> 4, kb 700 -> 2600). On a waiting
   foe it pushes it far back; on a casting foe the push stops at COMMAND_POINT, so the cast restarts its progress
   but is not erased (today's Timeline.hit). Decision: delay (cheap, keeps the foe's action) vs erase (breaker,
   dear); the only melee-side reach into a covered rearguard. Tell: piston hiss, the foe slides; NEW view: a ghost
   marker on the timeline shows where the target will land before confirming.
7. Arc Discharge: power 14 to every foe, ranged (today). NEW `bonus_vs_status: jammed`, `bonus_mult: 1.5`: a foe
   wearing Bilqis's net takes 1.5x. Decision: arc now, or wait one Bilqis turn for the net. Tell: arcs jump between
   foes; on netted foes they flare white with a "conducted" popup.
Later (not in v0.3): cradle_spine's reactive_guard becomes an ally-target guard ("Dira'", shield Bilqis) so it does
not overlap Elder's Patience; its numbers come with that item.

## 4. New engine work (pure logic in features/combat/logic, content in JSON, one test per rule)
| New | Where | Rule |
|---|---|---|
| ActionDef `sp_gain` (int, 0) | BattleResolver._finish_turn | added to the SP gain when >= 1 hit landed; capped at max SP |
| ActionDef `after_act_pos` (int, -1 = off) | Timeline._advance at ACT | lands at this position instead of AFTER_ACT_POS - recovery; must be < COMMAND_POINT |
| ActionDef `cast_status` (id, "") | BattleSim at choose, Timeline at ACT/interrupt, resolver at down | status lives only during the cast; events "status" and "status_ended" |
| ActionDef `bonus_vs_status` + `bonus_mult` | BattleResolver._damage | multiplies damage when the target has that status |
| StatusDef `counter_action` (id), `counter_ranged` (bool, false) | BattleResolver._hit_target | after the first hit that leaves the poised unit alive: event "countered", then strike(); the status ends; at most one counter per act |
| statuses `poised`, `exposed` | content/combat/statuses.json | poised: 1 turn, damage_taken 0.5, counter_action reverse_stab; exposed: damage_taken 1.5 |
| BattleAI rules | battle_ai.gd | stance when a foe casts a melee move at this unit; shove a foe within 1500 of COMMAND when no cancel is affordable; arc when a foe is jammed or >= 2 foes live; no Flash Flood when a foe is within 1500 of ACT |
| View | battle view, popups | "countered", "exposed" icon, shove ghost marker (pure query: knockback_preview(actor, action, target) -> int) |
Edge cases: counter only if the attacker still lives; a counter can down the attacker (normal down event); Zayd
downed by the hit gets no counter; exposed and guarded multiply (1.5 x 0.6); a fizzled Gazelle Step still lands
ahead (it is footwork); sp_gain is not paid on a fizzle; a counter never triggers another counter.

## 5. Tests the builder writes
sp_gain paid only on a landed hit; after_act_pos lands at 4500; cast_status added at choose and gone at act, at
interrupt and at down; bonus vs jammed x1.5 and none without jammed; poised halves a melee hit and fires exactly one
reverse_stab; no counter on ranged, on a downed Zayd, or when the attacker died; shove on a caster stops at
COMMAND_POINT and keeps its action; content check: Zayd's start loadout has exactly one cancel move; harness rows
for every hilt x prosthetic stay 65-90% and 40-90 s.

## 6. Owner decisions (2026-10-22)
- The heirloom trades elder_cut for the counter stance (Elder's Patience).
- No enemy interrupts Zayd in v0.3: "exposed" is Flash Flood's only risk.
- Buttons show the English name; the description line adds the Yemeni name in Latin letters (no Arabic script).
