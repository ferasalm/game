class_name BattleResolver
extends RefCounted
## Resolves one landed act (docs/design/combat.md, "Resolving an action"): targets, damage or heal per target,
## timeline effect per hit, status, SP gain, regen, status turns. Returns the events after "act", in the
## order the view plays.

var rules: BattleRulesDef
var rng: RandomNumberGenerator
var timeline: Timeline
var statuses: Dictionary[StringName, StatusDef]
var roll_rng: RandomNumberGenerator
var rolls_enabled: bool = true
var actions: Dictionary[StringName, ActionDef] = {}


func _init(
		battle_rules: BattleRulesDef, battle_rng: RandomNumberGenerator, battle_timeline: Timeline,
		status_defs: Dictionary[StringName, StatusDef], roll_random: RandomNumberGenerator = null,
		enabled: bool = true, action_defs: Dictionary[StringName, ActionDef] = {}) -> void:
	rules = battle_rules
	rng = battle_rng
	timeline = battle_timeline
	statuses = status_defs
	roll_rng = roll_random if roll_random != null else battle_rng
	rolls_enabled = enabled
	actions = action_defs


## One free strike outside the timeline (the reverse stab): hits, knockback and a possible down, no SP or
## status turns. Returns the events after the strike's own announcement.
func damage(actor: UnitState, action: ActionDef, target: UnitState) -> int:
	return BattleActionRules.calculate_damage(actor, action, target, rules, rng)


func _bring_down(target: UnitState, events: Array[TimelineEvent]) -> void:
	BattleActionRules.bring_down(target, timeline, events)


func strike(actor: UnitState, action: ActionDef, target: UnitState) -> Array[TimelineEvent]:
	var events: Array[TimelineEvent] = []
	_hit_target(actor, action, target, events, false, false)
	if not target.is_alive():
		BattleActionRules.bring_down(target, timeline, events)
	return events


func resolve(actor: UnitState) -> Array[TimelineEvent]:
	var events: Array[TimelineEvent] = []
	var action: ActionDef = actor.acted
	var targets: Array[UnitState] = _targets(actor, action)
	if targets.is_empty():
		events.append(TimelineEvent.new(&"fizzled", actor.unit_id, 0))
	var fresh: Array[StringName] = []
	if BattleActionRules.rolls_miss(rng, actor, action):
		events.append(TimelineEvent.new(&"missed", actor.unit_id, 0, action.id))
		_finish_turn(actor, events, fresh, 0)
		return events
	var hits_landed: int = 0
	for target: UnitState in targets:
		hits_landed += _resolve_target(actor, action, target, events, fresh)
	_finish_turn(actor, events, fresh, hits_landed)
	for target: UnitState in targets:
		if not target.is_alive():
			BattleActionRules.bring_down(target, timeline, events)
	return events


## Who the act hits. Foe and ally moves keep the chosen target while it is valid, else retarget to the first
## valid one on that side; self and all-moves resolve against whoever qualifies now (once per living target).
func _resolve_target(actor: UnitState, action: ActionDef, target: UnitState, events: Array[TimelineEvent], fresh: Array[StringName]) -> int:
	var dodged: bool = false
	if rolls_enabled and action.is_hostile() and action.power > 0 and not action.sure_hit and action.id != &"reverse_stab" and target.is_alive():
		var hit_chance_val: float = BattleRolls.hit_chance(actor, target, rules)
		if roll_rng.randf() > hit_chance_val:
			dodged = true
			events.append(TimelineEvent.new(&"dodged", target.unit_id, 0, action.id))
	var landed: int = 0
	if not dodged:
		var is_crit: bool = false
		if rolls_enabled and action.is_hostile() and target.is_alive():
			var crit_chance_val: float = BattleRolls.crit_chance(actor, rules)
			if roll_rng.randf() < crit_chance_val:
				is_crit = true
		if is_crit:
			events.append(TimelineEvent.new(&"crit", target.unit_id, 0))
		if action.is_hostile():
			landed = _hit_target(actor, action, target, events, is_crit)
		else:
			_heal_target(actor, action, target, events)
			BattleActionRules.apply_cures(target, action.cures, events)
		if _apply_status(actor, action, target, events, is_crit):
			if target == actor:
				fresh.append(action.applies_status)
	return landed


func _targets(actor: UnitState, action: ActionDef) -> Array[UnitState]:
	var options: Array[UnitState] = BattleTargets.valid_targets(timeline, actor, action)
	if not action.needs_picker() or options.is_empty():
		return options
	var wanted: UnitState = timeline.find(actor.acted_targets[0]) if not actor.acted_targets.is_empty() else null
	var single: Array[UnitState] = [wanted if options.has(wanted) else options[0]]
	return single


func _hit_target(actor: UnitState, action: ActionDef, target: UnitState, events: Array[TimelineEvent], is_crit: bool = false, is_counter: bool = false) -> int:
	var mult: float = rules.crit_mult if is_crit else 1.0
	var landed: int = 0
	if action.bonus_vs_status != &"" and target.status_turns.has(action.bonus_vs_status):
		events.append(TimelineEvent.new(&"conducted", target.unit_id, 0))
	for i: int in action.hit_count:
		if not target.is_alive() or not actor.is_alive():
			break
		var amount: int = damage(actor, action, target)
		if is_crit:
			amount = maxi(1, roundi(amount * mult))
		amount = maxi(1, roundi(amount * target.damage_taken_mult()))
		target.hp = maxi(0, target.hp - amount)
		events.append(TimelineEvent.new(&"damage", target.unit_id, amount, action.id))
		landed += 1
		if target.is_alive():
			var base_bonus: int = actor.def.knockback_bonus if i == 0 else 0
			var bonus: int = roundi(base_bonus * (rules.crit_knockback if (is_crit and i == 0) else 1.0))
			var prev_cs: StringName = target.action.cast_status if (target.phase == UnitState.Phase.CAST and target.action != null) else &""
			var hit_event: TimelineEvent = timeline.hit(target.unit_id, action, bonus)
			events.append(hit_event)
			if hit_event.kind == &"interrupted" and prev_cs != &"":
				events.append(TimelineEvent.new(&"status_ended", target.unit_id, 0, prev_cs))
			if not is_counter and action.is_hostile() and action.id != &"reverse_stab" and actor.is_alive():
				_check_counter(target, actor, action, events)
	return landed


func _check_counter(target: UnitState, attacker: UnitState, action: ActionDef, events: Array[TimelineEvent]) -> void:
	var poised: StatusDef = null
	for status: StatusDef in target.statuses:
		if status.counter_action != &"" and (action.is_melee or status.counter_ranged):
			poised = status
			break
	if poised == null:
		return
	events.append(TimelineEvent.new(&"countered", target.unit_id, 0, attacker.unit_id))
	var counter_act: ActionDef = actions.get(poised.counter_action)
	if counter_act != null:
		_hit_target(target, counter_act, attacker, events, false, true)
		if not attacker.is_alive():
			BattleActionRules.bring_down(attacker, timeline, events)
	target.remove_status(poised.id)
	events.append(TimelineEvent.new(&"status_ended", target.unit_id, 0, poised.id))


## Restores HP (never above max). A downed target stands up only for a revive move: it comes back on the
## track at AFTER_ACT_POS with no cast. Events: "revived" (when it stood up) then "healed" (amount restored).
func _heal_target(actor: UnitState, action: ActionDef, target: UnitState, events: Array[TimelineEvent]) -> void:
	if action.heal <= 0 or (not target.is_alive() and not action.revive):
		return
	var amount: int = roundi(action.heal + actor.def.attack * rules.heal_attack_factor)
	var restored: int = mini(target.def.max_hp, target.hp + amount) - target.hp
	if not target.is_alive():
		target.phase = UnitState.Phase.WAIT
		target.pos = Timeline.AFTER_ACT_POS
		events.append(TimelineEvent.new(&"revived", target.unit_id, 0))
	target.hp += restored
	events.append(TimelineEvent.new(&"healed", target.unit_id, restored, action.id))


## True when the status was set on the target.
func _apply_status(actor: UnitState, action: ActionDef, target: UnitState, events: Array[TimelineEvent], is_crit: bool = false) -> bool:
	if action.applies_status == &"" or not target.is_alive() or not statuses.has(action.applies_status):
		return false
	var status: StatusDef = statuses[action.applies_status]
	# Resist roll for hostile status applications on a living target.
	if rolls_enabled and action.is_hostile() and target.is_alive() and target.side != actor.side:
		var resist_chance_val: float = BattleRolls.resist_chance(actor, target, rules)
		if roll_rng.randf() < resist_chance_val:
			events.append(TimelineEvent.new(&"resisted", target.unit_id, 0, status.id))
			return false
	target.apply_status(status)
	events.append(TimelineEvent.new(&"status", target.unit_id, status.turns, status.id))
	return true


## SP gain (rules plus perk plus action), HP regen (perk), then the actor's statuses lose a turn, except ones it just gave
## itself (fresh).
func _finish_turn(actor: UnitState, events: Array[TimelineEvent], fresh: Array[StringName], hits_landed: int = 0) -> void:
	var sp_gain: int = rules.sp_per_act + actor.def.sp_per_act_bonus
	if actor.acted != null and hits_landed >= 1:
		sp_gain += actor.acted.sp_gain
	actor.sp = mini(actor.def.max_sp, actor.sp + sp_gain)
	if actor.is_alive() and actor.def.hp_regen > 0 and actor.hp < actor.def.max_hp:
		var regained: int = mini(actor.def.max_hp - actor.hp, actor.def.hp_regen)
		actor.hp += regained
		events.append(TimelineEvent.new(&"healed", actor.unit_id, regained, &"regen"))
	for ended_id: StringName in actor.tick_statuses(fresh):
		events.append(TimelineEvent.new(&"status_ended", actor.unit_id, 0, ended_id))
