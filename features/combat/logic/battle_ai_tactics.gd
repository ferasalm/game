class_name BattleAITactics
extends RefCounted
## Tactics evaluation for BattleAI (section 4): stance against incoming melee, shove near COMMAND, arc on spread/jammed.

static func stance_choice(sim: BattleSim, moves: Array[ActionDef], unit: UnitState) -> BattleAI.Choice:
	var incoming_melee: bool = false
	for foe: UnitState in sim.timeline.units:
		if foe.side != unit.side and foe.is_alive() and foe.phase == UnitState.Phase.CAST and foe.action != null:
			if foe.action.is_melee and (foe.targets.has(unit.unit_id) or foe.action.target == &"all_foes"):
				incoming_melee = true
				break
	if not incoming_melee:
		return null
	for move: ActionDef in moves:
		if is_stance(sim, move) and not unit.status_turns.has(move.applies_status):
			return BattleAI.Choice.new(move, &"")
	return null


static func shove_choice(sim: BattleSim, moves: Array[ActionDef], unit: UnitState) -> BattleAI.Choice:
	var shove_move: ActionDef = null
	for move: ActionDef in moves:
		if not move.cancels_cast and move.knockback >= 2000 and move.is_hostile():
			shove_move = move
			break
	if shove_move == null:
		return null
	var targets: Array[UnitState] = []
	for foe: UnitState in sim.timeline.units:
		if foe.side != unit.side and foe.is_alive() and foe.pos >= Timeline.COMMAND_POINT - 1500 and foe.pos <= Timeline.COMMAND_POINT:
			targets.append(foe)
	targets.sort_custom(func(a: UnitState, b: UnitState) -> bool: return a.pos > b.pos)
	for foe: UnitState in targets:
		if BattleTargets.valid_targets(sim.timeline, unit, shove_move).has(foe):
			return BattleAI.Choice.new(shove_move, foe.unit_id)
	return null


static func arc_choice(sim: BattleSim, moves: Array[ActionDef], unit: UnitState) -> BattleAI.Choice:
	var arc_move: ActionDef = null
	for move: ActionDef in moves:
		if move.bonus_vs_status != &"" or (move.target == &"all_foes" and not move.is_melee):
			arc_move = move
			break
	if arc_move == null:
		return null
	var living: Array[UnitState] = []
	var has_jammed: bool = false
	for foe: UnitState in sim.timeline.units:
		if foe.side != unit.side and foe.is_alive():
			living.append(foe)
			if foe.status_turns.has(&"jammed"):
				has_jammed = true
	if has_jammed or living.size() >= 2:
		return BattleAI.Choice.new(arc_move, &"")
	return null


static func is_stance(sim: BattleSim, move: ActionDef) -> bool:
	if move.applies_status == &"" or not sim.statuses.has(move.applies_status):
		return false
	return sim.statuses[move.applies_status].counter_action != &""
