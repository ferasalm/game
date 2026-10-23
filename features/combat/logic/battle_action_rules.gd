class_name BattleActionRules
extends RefCounted
## Move uses per battle, miss roll for confused units, and status cures for BattleSim and BattleResolver.

## Tracks use count per unit: {unit_id: {action_id: count}}.
var _uses: Dictionary[StringName, Dictionary] = {}


func uses_left(unit_id: StringName, action: ActionDef) -> int:
	if action == null or action.uses_per_battle <= 0:
		return 9999
	var unit_counts: Dictionary = _uses.get(unit_id, {})
	var spent: int = int(unit_counts.get(action.id, 0))
	return maxi(0, action.uses_per_battle - spent)


func can_use(unit_id: StringName, action: ActionDef) -> bool:
	return action == null or action.uses_per_battle <= 0 or uses_left(unit_id, action) > 0


func spend_use(unit_id: StringName, action: ActionDef) -> void:
	if action == null or action.uses_per_battle <= 0:
		return
	if not _uses.has(unit_id):
		_uses[unit_id] = {}
	_uses[unit_id][action.id] = int(_uses[unit_id].get(action.id, 0)) + 1


## Returns "" or why committing to this move and target is refused.
func check_choice(timeline: Timeline, unit_id: StringName, action: ActionDef, target_id: StringName) -> String:
	var unit: UnitState = timeline.waiting_for
	if unit == null or unit.unit_id != unit_id:
		return "not waiting for '%s'" % unit_id
	if action == null or not unit.def.actions.has(action.id):
		return "'%s' is not a move of '%s'" % [action.id if action != null else &"", unit_id]
	if not can_use(unit_id, action):
		return "'%s' has no uses left" % action.id
	if action.sp_cost > unit.sp:
		return "not enough SP for '%s'" % action.id
	var target_ids: Array[StringName] = BattleTargets.chosen_ids(timeline, unit, action, target_id)
	if target_ids.is_empty():
		return "'%s' is not a valid target for '%s'" % [target_id, action.id]
	return ""


static func highest_miss_chance(unit: UnitState) -> float:
	var chance: float = 0.0
	for status: StatusDef in unit.statuses:
		chance = maxf(chance, status.miss_chance)
	return chance


static func rolls_miss(rng: RandomNumberGenerator, unit: UnitState, action: ActionDef) -> bool:
	if not action.is_hostile():
		return false
	var chance: float = highest_miss_chance(unit)
	if chance <= 0.0:
		return false
	return rng.randf() < chance


static func cures_any(target: UnitState, cures: Array[StringName]) -> bool:
	for status_id: StringName in cures:
		if target.status_turns.has(status_id):
			return true
	return false


static func apply_cures(target: UnitState, cures: Array[StringName], events: Array[TimelineEvent]) -> void:
	for status_id: StringName in cures:
		if target.remove_status(status_id):
			events.append(TimelineEvent.new(&"status_ended", target.unit_id, 0, status_id))


static func calculate_damage(
		actor: UnitState, action: ActionDef, target: UnitState, rules: BattleRulesDef, rng: RandomNumberGenerator) -> int:
	var hits: float = float(maxi(1, action.hit_count))
	var net: float = (actor.def.attack - target.def.defense * rules.defense_factor) / hits
	var raw: float = action.power + net
	var row: float = Formation.melee_multiplier(actor.slot, target.slot, rules) if action.is_melee else 1.0
	var variance: float = rng.randf_range(1.0 - rules.damage_variance, 1.0 + rules.damage_variance)
	var bonus: float = action.bonus_mult if (action.bonus_vs_status != &"" and target.status_turns.has(action.bonus_vs_status)) else 1.0
	return maxi(1, roundi(raw * row * variance * bonus))


static func bring_down(target: UnitState, timeline: Timeline, events: Array[TimelineEvent]) -> void:
	if target.action != null and target.action.cast_status != &"":
		var cs: StringName = target.action.cast_status
		if target.remove_status(cs):
			events.append(TimelineEvent.new(&"status_ended", target.unit_id, 0, cs))
	target.phase = UnitState.Phase.WAIT
	target.action = null
	target.targets.clear()
	if timeline.waiting_for == target:
		timeline.waiting_for = null
	events.append(TimelineEvent.new(&"down", target.unit_id, 0))


static func start_pos(
		rules: BattleRulesDef, rng: RandomNumberGenerator, side: int, ambush: int,
		fighter: CombatantDef) -> int:
	if ambush == 2 and side == 1:
		return 0
	var party_range: bool = (side == 0) != (ambush == 1)
	var low: int = rules.party_start_min if party_range else rules.enemy_start_min
	var high: int = rules.party_start_max if party_range else rules.enemy_start_max
	return mini(Timeline.COMMAND_POINT - 1, rng.randi_range(low, high) + fighter.start_bonus)
