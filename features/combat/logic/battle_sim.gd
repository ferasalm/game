class_name BattleSim
extends RefCounted
## One battle (docs/design/combat.md): builds the units, steps the Timeline one tick at a time, asks the
## player (heroes) or BattleAI (enemies) for choices, resolves acts and decides victory or defeat.
## Pure and deterministic for a given seed and the same choices. The view plays the events step() returns.

var timeline := Timeline.new()
var rules: BattleRulesDef
var rng := RandomNumberGenerator.new()
## &"" while running, then &"victory" or &"defeat".
var result: StringName = &""
var ticks: int = 0
var ambush: int = 0
var _opened: bool = false
var actions: Dictionary[StringName, ActionDef] = {}
var statuses: Dictionary[StringName, StatusDef] = {}
var _resolver: BattleResolver
var setup: BattleSetup
## The consumables the party carries; battle casts reserve and consume from it (Bag).
var bag: Bag
## The Items command: reservations, casts and effects of the herbs in the bag.
var items: BattleItems
## Tracks move uses and choice rules.
var action_rules := BattleActionRules.new()
## A second RNG for roll chances (hit, crit, resist, flee), separate from the battle RNG.
var roll_rng := RandomNumberGenerator.new()
## When false, roll calculations are skipped (tests pin exact damage with old rules).
var rolls_enabled: bool = true:
	set(value):
		rolls_enabled = value
		if _resolver != null:
			_resolver.rolls_enabled = value  # set after create_from: the resolver copied the old value
## Failed flee attempts this battle (used by the flee chance formula).
var flee_fails: int = 0
## Events produced outside tick (e.g. status applied at choose), flushed on step.
var pending_events: Array[TimelineEvent] = []


## Builds the battle from a BattleSetup. Party units use their def id; enemies use "<def id>_<n>" counting from
## 1. Slots pair with the units in order. Units start at seeded random timeline positions from the rules' ranges
## (ambush: 0 none, 1 the party was ambushed and the two ranges swap, 2 the party ambushed the enemy and the
## enemies start at 0). Heroes start with their carried HP/SP (Vitals; missing means full).
static func create_from(battle: BattleSetup) -> BattleSim:
	var sim := BattleSim.new()
	sim.setup = battle
	sim.rules = battle.rules
	sim.actions = battle.actions
	sim.statuses = battle.statuses
	sim.bag = Bag.from_counts(battle.bag)
	sim.rng.seed = battle.seed
	sim.roll_rng.seed = hash([battle.seed, "rolls"])
	sim.ambush = battle.ambush
	for i: int in battle.party.size():
		var hero: CombatantDef = battle.party[i]
		var unit := UnitState.create(hero, hero.id, 0, battle.party_slots[i], battle.rules)
		unit.hp = Vitals.hp_of(battle.vitals, hero.id, hero.max_hp)
		unit.sp = Vitals.sp_of(battle.vitals, hero.id, hero.max_sp)
		unit.pos = BattleActionRules.start_pos(sim.rules, sim.rng, 0, battle.ambush, hero)
		sim.timeline.units.append(unit)
	var counts: Dictionary[StringName, int] = {}
	for i: int in battle.enemies.size():
		var foe: CombatantDef = battle.enemies[i]
		counts[foe.id] = counts.get(foe.id, 0) + 1
		var unit := UnitState.create(
			foe, StringName("%s_%d" % [foe.id, counts[foe.id]]), 1, battle.enemy_slots[i], battle.rules)
		unit.pos = BattleActionRules.start_pos(sim.rules, sim.rng, 1, battle.ambush, foe)
		sim.timeline.units.append(unit)
	sim._resolver = BattleResolver.new(battle.rules, sim.rng, sim.timeline, battle.statuses, sim.roll_rng, sim.rolls_enabled, battle.actions)
	sim.items = BattleItems.new(sim.bag, sim.timeline, battle.consumables)
	return sim


## Predicted timeline position of target after being hit by actor's action (pure query; no state modified).
func knockback_preview(actor: UnitState, action: ActionDef, target: UnitState) -> int:
	if target == null or action == null:
		return 0
	if target.phase == UnitState.Phase.CAST and action.cancels_cast and not target.interrupt_immune():
		return Timeline.INTERRUPT_POS
	var bonus: int = actor.def.knockback_bonus if actor != null else 0
	var shift: int = roundi((action.knockback + bonus) * (1.0 - target.def.interrupt_resist))
	var lowest: int = Timeline.COMMAND_POINT if target.phase == UnitState.Phase.CAST else 0
	var current_pos: int = target.pos
	if target.phase == UnitState.Phase.COMMAND:
		current_pos = Timeline.COMMAND_POINT - 1
	return maxi(lowest, current_pos - shift)


## True when the actor's cast of this action (COMMAND to ACT at its cast speed, statuses included) finishes
## in fewer ticks than the target needs to reach ACT from where it is. False if the target is not casting.
func lands_before(actor: UnitState, action: ActionDef, target: UnitState) -> bool:
	if target.phase != UnitState.Phase.CAST:
		return false
	var mine: int = ceili(float(Timeline.ACT_POINT - Timeline.COMMAND_POINT) / actor.cast_speed_for(action))
	var theirs: int = ceili(float(Timeline.ACT_POINT - target.pos) / target.speed())
	return mine < theirs


## The reverse stab: when the party was ambushed (ambush 1), Zayd strikes the lowest-slot living enemy with
## the action "reverse_stab" before the battle starts. Returns its events once, [] on any later call or
## when there is no ambush, no Zayd or no such action. step() calls it first if the view did not.
func opening() -> Array[TimelineEvent]:
	var out: Array[TimelineEvent] = []
	var wielder: UnitState = timeline.find(Jambiyah.WIELDER)
	var stab: ActionDef = actions.get(&"reverse_stab") as ActionDef
	if _opened or ambush != 1 or wielder == null or stab == null:
		_opened = true
		return out
	_opened = true
	var target: UnitState = null
	for unit: UnitState in timeline.units:
		if unit.side == 1 and unit.is_alive() and (target == null or unit.slot < target.slot):
			target = unit
	if target == null:
		return out
	out.append(TimelineEvent.new(&"reverse_stab", wielder.unit_id, 0, stab.id))
	out.append_array(_resolver.strike(wielder, stab, target))
	if BattleTargets.side_is_down(timeline, 1):
		_end(&"victory", out)
	return out


## One tick. Returns what happened, in order; [] while a hero waits for a choice or once the battle is over.
func step() -> Array[TimelineEvent]:
	return BattleSimRunner.step(self)


## The party unit waiting at COMMAND, or null.
func waiting_hero() -> UnitState:
	var waiting: UnitState = timeline.waiting_for
	return waiting if waiting != null and waiting.side == 0 else null


## The unit's moves it can pay for and has uses left for.
func choices_for(unit: UnitState) -> Array[ActionDef]:
	return BattleTargets.affordable_moves(unit, actions).filter(
		func(m: ActionDef) -> bool: return action_rules.can_use(unit.unit_id, m))


## True when the unit has uses left for this action (or it is unlimited).
func can_use(unit: UnitState, action: ActionDef) -> bool:
	return action_rules.can_use(unit.unit_id, action)


func valid_targets(unit: UnitState, action: ActionDef) -> Array[UnitState]:
	return BattleTargets.valid_targets(timeline, unit, action)


## Commits the waiting unit to a move on a target, paying its SP. Self and all-moves ignore target_id (pass
## &""); foe and ally moves need a valid one. Returns "" or why it was refused.
func choose(unit_id: StringName, action: ActionDef, target_id: StringName) -> String:
	var refusal: String = action_rules.check_choice(timeline, unit_id, action, target_id)
	if not refusal.is_empty():
		return refusal
	# Flee is refused when the encounter does not allow it.
	if action != null and action.id == &"flee" and setup != null and not setup.can_flee:
		return "UI_CANT_FLEE"
	var unit: UnitState = timeline.waiting_for
	unit.sp -= action.sp_cost
	action_rules.spend_use(unit_id, action)
	if action != null and action.cast_status != &"" and statuses.has(action.cast_status):
		var st: StatusDef = statuses[action.cast_status]
		unit.apply_status(st)
		pending_events.append(TimelineEvent.new(&"status", unit_id, st.turns, st.id))
	return timeline.choose(unit_id, action, BattleTargets.chosen_ids(timeline, unit, action, target_id))


## Commits the waiting hero to a herb of the bag (target &"" for the party herb). Returns "" or why it was refused.
func choose_item(unit_id: StringName, item_id: StringName, target_id: StringName) -> String:
	var unit: UnitState = timeline.waiting_for
	if unit == null or unit.unit_id != unit_id or unit.side != 0 or items.consumable(item_id) == null:
		return "'%s' cannot use '%s' now" % [unit_id, item_id]
	return items.choose(unit, items.consumable(item_id), target_id)


## BattleAI chooses for this waiting unit (enemies always; the harness and the view's auto-play for heroes).
func auto_choose(unit: UnitState) -> void:
	var choice: BattleAI.Choice = BattleAI.pick(self, unit)
	if choice != null:
		choose(unit.unit_id, choice.action, choice.target_id)


func _end(outcome: StringName, out: Array[TimelineEvent]) -> void:
	result = outcome
	out.append(TimelineEvent.new(outcome, &"", ticks))
