class_name BattleAI
extends RefCounted
## The one battle policy (enemies in play, both sides in the balance harness): cancel the casting foe nearest
## to ACT when a cancel move is affordable, else a random affordable move on a random valid target.


class Choice extends RefCounted:
	var action: ActionDef
	var target_id: StringName

	func _init(chosen: ActionDef, target: StringName) -> void:
		action = chosen
		target_id = target


## Returns the unit's choice, or null when it has no affordable move with a valid target.
static func pick(
		timeline: Timeline, actions: Dictionary[StringName, ActionDef], unit: UnitState,
		rng: RandomNumberGenerator) -> Choice:
	var moves: Array[ActionDef] = BattleTargets.affordable_moves(unit, actions)
	var cancel: Choice = _cancel_choice(timeline, moves, unit)
	if cancel != null:
		return cancel
	var usable: Array[ActionDef] = moves.filter(
		func(m: ActionDef) -> bool: return not BattleTargets.valid_targets(timeline, unit, m).is_empty())
	if usable.is_empty():
		return null
	var action: ActionDef = usable[rng.randi_range(0, usable.size() - 1)]
	var targets: Array[UnitState] = BattleTargets.valid_targets(timeline, unit, action)
	return Choice.new(action, targets[rng.randi_range(0, targets.size() - 1)].unit_id)


static func _cancel_choice(timeline: Timeline, moves: Array[ActionDef], unit: UnitState) -> Choice:
	var casters: Array[UnitState] = []
	for other: UnitState in timeline.units:
		if other.side != unit.side and other.is_alive() and other.phase == UnitState.Phase.CAST:
			casters.append(other)
	casters.sort_custom(func(a: UnitState, b: UnitState) -> bool: return a.pos > b.pos)
	for caster: UnitState in casters:
		for move: ActionDef in moves:
			if move.cancels_cast and BattleTargets.valid_targets(timeline, unit, move).has(caster):
				return Choice.new(move, caster.unit_id)
	return null
