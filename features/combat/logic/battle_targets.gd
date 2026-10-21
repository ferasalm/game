class_name BattleTargets
extends RefCounted
## Who can do what in a battle: a unit's moves, which of them it can pay for, and who a move may target.
## Foe moves skip covered rearguard units unless the move ignores cover; ally moves reach the actor's side
## (downed allies only for a revive); self and all-moves need no pick. Pure helpers, no state.


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


## Units this move may target, in timeline order. For all_foes / all_allies it is everyone the move hits.
static func valid_targets(timeline: Timeline, unit: UnitState, action: ActionDef) -> Array[UnitState]:
	match action.target:
		&"self":
			var only: Array[UnitState] = [unit]
			return only
		&"ally":
			return _allies(timeline, unit, action.revive)
		&"all_allies":
			return _allies(timeline, unit, false)
		&"all_foes":
			return _foes(timeline, unit, true)
	return _foes(timeline, unit, action.ignores_cover)


## The unit ids a freshly chosen move will hit: the picked one for foe / ally moves ([] if it is not valid),
## everyone concerned for self and all-moves (picked is ignored).
static func chosen_ids(
		timeline: Timeline, unit: UnitState, action: ActionDef, picked: StringName) -> Array[StringName]:
	var out: Array[StringName] = []
	for target: UnitState in valid_targets(timeline, unit, action):
		if not action.needs_picker() or target.unit_id == picked:
			out.append(target.unit_id)
	return out


static func side_is_down(timeline: Timeline, side: int) -> bool:
	for unit: UnitState in timeline.units:
		if unit.side == side and unit.is_alive():
			return false
	return true


static func _allies(timeline: Timeline, unit: UnitState, include_downed: bool) -> Array[UnitState]:
	var out: Array[UnitState] = []
	for other: UnitState in timeline.units:
		if other.side == unit.side and (other.is_alive() or include_downed):
			out.append(other)
	return out


static func _foes(timeline: Timeline, unit: UnitState, ignore_cover: bool) -> Array[UnitState]:
	var living_slots: Array[int] = []
	for other: UnitState in timeline.units:
		if other.side != unit.side and other.is_alive():
			living_slots.append(other.slot)
	var out: Array[UnitState] = []
	for other: UnitState in timeline.units:
		if other.side == unit.side or not other.is_alive():
			continue
		if ignore_cover or not Formation.is_covered(other.slot, living_slots):
			out.append(other)
	return out
