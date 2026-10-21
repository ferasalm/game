class_name BattleProbe
extends RefCounted
## Test helper (not a test): hand-made fighters, moves and battles with exact numbers, and loops that play a
## BattleSim until an event kind appears. A "picker" Callable is called as picker.call(sim, hero) and must
## call sim.choose for the waiting hero.


static func fighter(id: StringName, props: Dictionary = {}) -> CombatantDef:
	var def := CombatantDef.new()
	def.id = id
	def.name_key = "X"
	def.max_hp = 100
	def.max_sp = 20
	def.attack = 10
	def.defense = 10
	def.agility = 50
	def.actions = [&"hit"] as Array[StringName]
	for key: Variant in props:
		def.set(key as String, props[key])
	return def


static func move(id: StringName, props: Dictionary = {}) -> ActionDef:
	var action := ActionDef.new()
	action.id = id
	action.name_key = "X"
	action.power = 10
	action.cast_speed = 1.0
	action.recovery = 500
	action.knockback = 500
	for key: Variant in props:
		action.set(key as String, props[key])
	return action


## rule_props override the BattleRulesDef (default: no variance, defense_factor 0.5, sp_per_act 3).
static func sim(
		heroes: Array[CombatantDef], hero_slots: Array[int], foes: Array[CombatantDef], foe_slots: Array[int],
		moves: Array[ActionDef], rule_props: Dictionary = {}, status_list: Array[StatusDef] = [],
		ambush: int = 0) -> BattleSim:
	var rules := BattleRulesDef.new()
	rules.id = &"probe"
	rules.defense_factor = 0.5
	rules.damage_variance = 0.0
	rules.sp_per_act = 3
	rules.max_ticks = 20000
	for key: Variant in rule_props:
		rules.set(key as String, rule_props[key])
	var actions: Dictionary[StringName, ActionDef] = {}
	for action: ActionDef in moves:
		actions[action.id] = action
	var statuses: Dictionary[StringName, StatusDef] = {}
	for status: StatusDef in status_list:
		statuses[status.id] = status
	var setup := BattleSetup.new()
	setup.rules = rules
	setup.party = heroes
	setup.party_slots = hero_slots
	setup.enemies = foes
	setup.enemy_slots = foe_slots
	setup.actions = actions
	setup.statuses = statuses
	setup.seed = 1
	setup.ambush = ambush
	return BattleSim.create_from(setup)


## Steps until an event of this kind is returned (that step's events are included), the battle ends, or
## max_steps run out.
static func play_until(sim: BattleSim, kind: StringName, picker: Callable, max_steps: int = 30000) -> Array[TimelineEvent]:
	var trace: Array[TimelineEvent] = []
	for i: int in max_steps:
		var hero: UnitState = sim.waiting_hero()
		if hero != null:
			picker.call(sim, hero)
		var events: Array[TimelineEvent] = sim.step()
		trace.append_array(events)
		if sim.result != &"" or events.any(func(e: TimelineEvent) -> bool: return e.kind == kind):
			break
	return trace


static func count(trace: Array[TimelineEvent], kind: StringName) -> int:
	return trace.filter(func(e: TimelineEvent) -> bool: return e.kind == kind).size()


static func first(trace: Array[TimelineEvent], kind: StringName) -> TimelineEvent:
	for event: TimelineEvent in trace:
		if event.kind == kind:
			return event
	return null


static func text(trace: Array[TimelineEvent]) -> String:
	return ",".join(trace.map(func(e: TimelineEvent) -> String: return str(e)))


## Picker: the first affordable move on the first valid target.
static func pick_first(sim: BattleSim, hero: UnitState) -> void:
	var action: ActionDef = sim.choices_for(hero)[0]
	sim.choose(hero.unit_id, action, sim.valid_targets(hero, action)[0].unit_id)
