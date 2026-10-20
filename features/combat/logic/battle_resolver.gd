class_name BattleResolver
extends RefCounted
## Resolves one landed act (docs/design/combat.md, "Resolving an action"): retarget, damage per hit, timeline
## effect per hit, status, SP gain, status turns. Returns the events after "act", in the order the view plays.

var rules: BattleRulesDef
var rng: RandomNumberGenerator
var timeline: Timeline
var statuses: Dictionary[StringName, StatusDef]


func _init(
		battle_rules: BattleRulesDef, battle_rng: RandomNumberGenerator, battle_timeline: Timeline,
		status_defs: Dictionary[StringName, StatusDef]) -> void:
	rules = battle_rules
	rng = battle_rng
	timeline = battle_timeline
	statuses = status_defs


## One free strike outside the timeline (the reverse stab): hits, knockback and a possible down, no SP or
## status turns. Returns the events after the strike's own announcement.
func strike(actor: UnitState, action: ActionDef, target: UnitState) -> Array[TimelineEvent]:
	var events: Array[TimelineEvent] = []
	_hit_target(actor, action, target, events)
	if not target.is_alive():
		_bring_down(target, events)
	return events


func resolve(actor: UnitState) -> Array[TimelineEvent]:
	var events: Array[TimelineEvent] = []
	var action: ActionDef = actor.acted
	var target: UnitState = _pick_target(actor, action)
	if target == null:
		events.append(TimelineEvent.new(&"fizzled", actor.unit_id, 0))
	else:
		_hit_target(actor, action, target, events)
		_apply_status(action, target, events)
	_finish_turn(actor, events)
	if target != null and not target.is_alive():
		_bring_down(target, events)
	return events


## The chosen target while it lives, else the first living valid target on that side, else null.
func _pick_target(actor: UnitState, action: ActionDef) -> UnitState:
	var wanted: UnitState = timeline.find(actor.acted_targets[0]) if not actor.acted_targets.is_empty() else null
	if wanted != null and wanted.is_alive():
		return wanted
	var options: Array[UnitState] = BattleTargets.valid_targets(timeline, actor, action)
	return options[0] if not options.is_empty() else null


func _hit_target(actor: UnitState, action: ActionDef, target: UnitState, events: Array[TimelineEvent]) -> void:
	for i: int in action.hit_count:
		if not target.is_alive():
			break
		var amount: int = _damage(actor, action, target)
		target.hp = maxi(0, target.hp - amount)
		events.append(TimelineEvent.new(&"damage", target.unit_id, amount, action.id))
		if target.is_alive():
			var bonus: int = actor.def.knockback_bonus if i == 0 else 0
			events.append(timeline.hit(target.unit_id, action, bonus))


func _damage(actor: UnitState, action: ActionDef, target: UnitState) -> int:
	var raw: float = action.power + actor.def.attack - target.def.defense * rules.defense_factor
	var row: float = Formation.melee_multiplier(actor.slot, target.slot) if action.is_melee else 1.0
	var variance: float = rng.randf_range(1.0 - rules.damage_variance, 1.0 + rules.damage_variance)
	return maxi(1, roundi(raw * row * variance))


func _apply_status(action: ActionDef, target: UnitState, events: Array[TimelineEvent]) -> void:
	if action.applies_status == &"" or not target.is_alive() or not statuses.has(action.applies_status):
		return
	var status: StatusDef = statuses[action.applies_status]
	target.apply_status(status)
	events.append(TimelineEvent.new(&"status", target.unit_id, status.turns, status.id))


func _finish_turn(actor: UnitState, events: Array[TimelineEvent]) -> void:
	actor.sp = mini(actor.def.max_sp, actor.sp + rules.sp_per_act)
	for ended_id: StringName in actor.tick_statuses():
		events.append(TimelineEvent.new(&"status_ended", actor.unit_id, 0, ended_id))


func _bring_down(target: UnitState, events: Array[TimelineEvent]) -> void:
	target.phase = UnitState.Phase.WAIT
	target.action = null
	target.targets.clear()
	if timeline.waiting_for == target:
		timeline.waiting_for = null  # it reached COMMAND in the same tick it fell
	events.append(TimelineEvent.new(&"down", target.unit_id, 0))
