class_name BattleFleeLogic
extends RefCounted
## Flee resolution logic, extracted to keep battle_sim.gd under 200 lines.

static func resolve_flee(sim: BattleSim, unit: UnitState, out: Array[TimelineEvent]) -> Array[TimelineEvent]:
	var party: Array[UnitState] = []
	var foes: Array[UnitState] = []
	for u: UnitState in sim.timeline.units:
		if u.side == 0 and u.is_alive():
			party.append(u)
		elif u.side == 1 and u.is_alive():
			foes.append(u)
	if sim.rolls_enabled:
		var chance: float = BattleRolls.flee_chance(party, foes, sim.flee_fails, sim.ambush, sim.rules)
		if sim.roll_rng.randf() < chance:
			out.append(TimelineEvent.new(&"fled", unit.unit_id, 0))
			sim.result = &"fled"
			return out
	sim.flee_fails += 1
	out.append(TimelineEvent.new(&"flee_failed", unit.unit_id, sim.flee_fails))
	var fresh: Array[StringName] = []
	sim._resolver._finish_turn(unit, out, fresh)
	return out
