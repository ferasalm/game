class_name BattleTargets
extends RefCounted
## Who can do what in a battle: a unit's moves, which of them it can pay for, and which foes a move may
## target (covered rearguard units are safe from moves without ignores_cover). Pure helpers, no state.


## The moves a unit knows, in its CombatantDef order.
static func moves_of(unit: UnitState, actions: Dictionary[StringName, ActionDef]) -> Array[ActionDef]:
	var out: Array[ActionDef] = []
	for action_id: StringName in unit.def.actions:
		if actions.has(action_id):
			out.append(actions[action_id])
	return out


## The moves a unit can pay for right now.
static func affordable_moves(unit: UnitState, actions: Dictionary[StringName, ActionDef]) -> Array[ActionDef]:
	var out: Array[ActionDef] = []
	for action: ActionDef in moves_of(unit, actions):
		if action.sp_cost <= unit.sp:
			out.append(action)
	return out


## Living units on the other side that this move may target, in timeline order.
static func valid_targets(timeline: Timeline, unit: UnitState, action: ActionDef) -> Array[UnitState]:
	var living_slots: Array[int] = []
	for other: UnitState in timeline.units:
		if other.side != unit.side and other.is_alive():
			living_slots.append(other.slot)
	var out: Array[UnitState] = []
	for other: UnitState in timeline.units:
		if other.side == unit.side or not other.is_alive():
			continue
		if action.ignores_cover or not Formation.is_covered(other.slot, living_slots):
			out.append(other)
	return out


static func side_is_down(timeline: Timeline, side: int) -> bool:
	for unit: UnitState in timeline.units:
		if unit.side == side and unit.is_alive():
			return false
	return true
