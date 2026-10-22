class_name BattleAI
extends RefCounted
## The one battle policy (enemies in play, both sides in the balance harness), in this order:
## 1. cancel the casting foe nearest to ACT when a cancel move is affordable;
## 2. stand up a downed ally (revive move), else heal the weakest ally under rules.ai_heal_below;
## 3. guard (a damage-reducing status move) when a foe is casting a move of power x hits >= rules.ai_big_cast_power;
## 4. else a random useful move on a random valid target (heals only when someone is hurt, buffs only when
##    missing; guard moves are kept for step 3).


class Choice extends RefCounted:
	var action: ActionDef
	var target_id: StringName

	func _init(chosen: ActionDef, target: StringName) -> void:
		action = chosen
		target_id = target


## Returns the unit's choice, or null when it has no affordable move with a valid target.
static func pick(sim: BattleSim, unit: UnitState) -> Choice:
	var moves: Array[ActionDef] = BattleTargets.affordable_moves(unit, sim.actions).filter(
		func(m: ActionDef) -> bool: return sim.can_use(unit, m))
	var choice: Choice = _cancel_choice(sim.timeline, moves, unit)
	if choice == null:
		choice = _heal_choice(sim, moves, unit)
	if choice == null:
		choice = _guard_choice(sim, moves, unit)
	if choice == null:
		choice = _random_choice(sim, moves, unit)
	return choice


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


static func _heal_choice(sim: BattleSim, moves: Array[ActionDef], unit: UnitState) -> Choice:
	var fallen: UnitState = null
	var weakest: UnitState = null
	for ally: UnitState in sim.timeline.units:
		if ally.side != unit.side:
			continue
		if not ally.is_alive():
			fallen = fallen if fallen != null else ally
		elif _hp_share(ally) < sim.rules.ai_heal_below and (weakest == null or _hp_share(ally) < _hp_share(weakest)):
			weakest = ally
	for move: ActionDef in moves:
		var options: Array[UnitState] = BattleTargets.valid_targets(sim.timeline, unit, move)
		if move.heal <= 0:
			continue
		if move.target == &"self" and _hp_share(unit) < sim.rules.ai_heal_below:
			return Choice.new(move, &"")
		if move.target != &"ally":
			continue
		if move.revive and fallen != null and options.has(fallen):
			return Choice.new(move, fallen.unit_id)
		if not move.revive and weakest != null and options.has(weakest):
			return Choice.new(move, weakest.unit_id)
	return null


static func _guard_choice(sim: BattleSim, moves: Array[ActionDef], unit: UnitState) -> Choice:
	if not _big_cast_incoming(sim, unit):
		return null
	for move: ActionDef in moves:
		if not _is_guard(sim, move):
			continue
		var options: Array[UnitState] = BattleTargets.valid_targets(sim.timeline, unit, move)
		if options.has(unit):
			options.erase(unit)
			options.push_front(unit)  # guard yourself first
		for target: UnitState in options:
			if not target.status_turns.has(move.applies_status):
				return Choice.new(move, target.unit_id if move.needs_picker() else &"")
	return null


static func _random_choice(sim: BattleSim, moves: Array[ActionDef], unit: UnitState) -> Choice:
	var usable: Array[ActionDef] = moves.filter(func(m: ActionDef) -> bool: return _is_useful(sim, unit, m))
	if usable.is_empty():
		return null
	var action: ActionDef = usable[sim.rng.randi_range(0, usable.size() - 1)]
	var targets: Array[UnitState] = BattleTargets.valid_targets(sim.timeline, unit, action)
	if action.is_hostile():
		return Choice.new(action, targets[sim.rng.randi_range(0, targets.size() - 1)].unit_id)
	if not action.needs_picker():
		return Choice.new(action, &"")
	var best: UnitState = targets[0]
	for target: UnitState in targets:
		if _needs_more(action, target, best):
			best = target
	return Choice.new(action, best.unit_id)


## True when the target is a better pick than best: more hurt for a heal, else lacking the status.
static func _needs_more(action: ActionDef, target: UnitState, best: UnitState) -> bool:
	if action.heal > 0:
		return _hp_share(target) < _hp_share(best)
	return best.status_turns.has(action.applies_status) and not target.status_turns.has(action.applies_status)


static func _is_useful(sim: BattleSim, unit: UnitState, move: ActionDef) -> bool:
	var options: Array[UnitState] = BattleTargets.valid_targets(sim.timeline, unit, move)
	if options.is_empty():
		return false
	if move.is_hostile():
		if move.power <= 4 and move.applies_status != &"":
			var all_have_status: bool = options.all(
				func(t: UnitState) -> bool: return t.status_turns.has(move.applies_status))
			if all_have_status:
				return false
		return true
	if _is_guard(sim, move):
		return false  # guards wait for a big enemy cast (step 3)
	if move.heal > 0:
		return options.any(func(t: UnitState) -> bool: return t.hp < t.def.max_hp)
	if move.applies_status != &"":
		return options.any(func(t: UnitState) -> bool: return not t.status_turns.has(move.applies_status))
	return true


## A move on the actor's side whose status makes the target take less damage.
static func _is_guard(sim: BattleSim, move: ActionDef) -> bool:
	if move.is_hostile() or move.applies_status == &"" or not sim.statuses.has(move.applies_status):
		return false
	return sim.statuses[move.applies_status].damage_taken < 1.0


static func _big_cast_incoming(sim: BattleSim, unit: UnitState) -> bool:
	for foe: UnitState in sim.timeline.units:
		if foe.side != unit.side and foe.is_alive() and foe.phase == UnitState.Phase.CAST and foe.action != null:
			if foe.action.is_hostile() and foe.action.power * foe.action.hit_count >= sim.rules.ai_big_cast_power:
				return true
	return false


static func _hp_share(unit: UnitState) -> float:
	return float(unit.hp) / float(maxi(1, unit.def.max_hp))
