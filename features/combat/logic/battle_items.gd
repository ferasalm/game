class_name BattleItems
extends RefCounted
## The Items command of a battle (docs/design/economy.md section 5). Choosing a herb RESERVES one in the Bag
## (available = count - reserved, so two heroes never claim the last one) and casts it on the timeline at its cast
## speed. At ACT it is CONSUMED if it would change something (events: item_used, then revived / healed / sp_restored
## with the real amounts) and REFUNDED (the claim is released, the bag is unchanged, event: fizzled) when the target
## is no longer valid or the effect would be nothing. A cast that never reaches ACT (the user was knocked out, the
## cast was cut) is refunded by sync(). Items give no SP and no perk regen, but the user's statuses lose a turn.
## Pure: no nodes, no autoloads.

var _bag: Bag
var _timeline: Timeline
var _consumables: Dictionary[StringName, ConsumableDef]
var _actions: Dictionary[StringName, ItemAction] = {}
## The herb each casting unit holds a claim on: {unit id: consumable id}.
var _pending: Dictionary[StringName, StringName] = {}


func _init(bag: Bag, timeline: Timeline, consumables: Dictionary[StringName, ConsumableDef]) -> void:
	_bag = bag
	_timeline = timeline
	_consumables = consumables


## The consumables usable in battle that the bag holds (even when every one is claimed), in id order.
func listed() -> Array[ConsumableDef]:
	var out: Array[ConsumableDef] = []
	var ids: Array = _consumables.keys()
	ids.sort()
	for item_id: StringName in ids:
		var def: ConsumableDef = _consumables[item_id]
		if def.usable_in_battle() and _bag.count(item_id) > 0:
			out.append(def)
	return out


## True when something is listed and at least one herb is unclaimed.
func any_available() -> bool:
	return listed().any(func(def: ConsumableDef) -> bool: return _bag.available(def.id) > 0)


## The consumable with this id, or null.
func consumable(item_id: StringName) -> ConsumableDef:
	return _consumables.get(item_id)


## Herbs of every listed kind that are not claimed.
func free_count() -> int:
	var total: int = 0
	for def: ConsumableDef in listed():
		total += _bag.available(def.id)
	return total


func available(item_id: StringName) -> int:
	return _bag.available(item_id)


## Units the herb may be used on: the user's living side (a revive herb: its downed side), in timeline order.
func valid_targets(user: UnitState, def: ConsumableDef) -> Array[UnitState]:
	var out: Array[UnitState] = []
	for unit: UnitState in _timeline.units:
		if unit.side == user.side and unit.is_alive() != def.revive:
			out.append(unit)
	return out


## The ids a fresh cast would hit: the picked one for a single-target herb ([] if invalid), everyone for the party herb.
func target_ids(user: UnitState, def: ConsumableDef, picked: StringName) -> Array[StringName]:
	var out: Array[StringName] = []
	for unit: UnitState in valid_targets(user, def):
		if def.target == &"all_allies" or unit.unit_id == picked:
			out.append(unit.unit_id)
	return out


## Commits the waiting unit to the herb: reserves one and casts it. Returns "" or why it was refused.
func choose(user: UnitState, def: ConsumableDef, picked: StringName) -> String:
	if def == null or not def.usable_in_battle():
		return "that cannot be used in battle"
	var ids: Array[StringName] = target_ids(user, def, picked)
	if ids.is_empty():
		return "'%s' is not a valid target for '%s'" % [picked, def.id]
	if not _bag.reserve(def.id):
		return "none of '%s' left" % def.id
	var reason: String = _timeline.choose(user.unit_id, action_for(def), ids)
	if reason.is_empty():
		_pending[user.unit_id] = def.id
	else:
		_bag.release(def.id)
	return reason


func action_for(def: ConsumableDef) -> ItemAction:
	if not _actions.has(def.id):
		_actions[def.id] = ItemAction.from_consumable(def)
	return _actions[def.id]


## The act of an item cast landed: consume and apply, or fizzle and refund. Returns the events after "act".
func resolve(actor: UnitState) -> Array[TimelineEvent]:
	var events: Array[TimelineEvent] = []
	var action := actor.acted as ItemAction
	_pending.erase(actor.unit_id)
	var def: ConsumableDef = _consumables.get(action.item_id)
	var hits: Array[UnitState] = _still_valid(actor, def)
	if def == null or hits.is_empty():
		_bag.release(action.item_id)
		events.append(TimelineEvent.new(&"fizzled", actor.unit_id, 0, action.item_id))
	else:
		_bag.consume(action.item_id)
		events.append(TimelineEvent.new(&"item_used", actor.unit_id, 0, action.item_id))
		for target: UnitState in hits:
			_apply(def, target, events)
	for ended_id: StringName in actor.tick_statuses():
		events.append(TimelineEvent.new(&"status_ended", actor.unit_id, 0, ended_id))
	return events


## Gives back the claim of every cast that no longer exists (its user was knocked out or the cast was cut).
func sync() -> void:
	for unit_id: StringName in _pending.keys():
		var unit: UnitState = _timeline.find(unit_id)
		if unit == null or not (unit.action is ItemAction) or not unit.is_alive():
			_bag.release(_pending[unit_id])
			_pending.erase(unit_id)


## How many claims are open (a test reads it).
func claims() -> int:
	return _pending.size()


## The chosen targets that can still gain something (a herb never changes a unit it cannot help).
func _still_valid(actor: UnitState, def: ConsumableDef) -> Array[UnitState]:
	var out: Array[UnitState] = []
	if def == null:
		return out
	for target: UnitState in valid_targets(actor, def):
		if def.target != &"all_allies" and not actor.acted_targets.has(target.unit_id):
			continue
		var gain: Dictionary = ItemEffect.gains(def, target.hp, target.sp, target.def.max_hp, target.def.max_sp)
		if ItemEffect.changes(gain):
			out.append(target)
	return out


func _apply(def: ConsumableDef, target: UnitState, events: Array[TimelineEvent]) -> void:
	var gain: Dictionary = ItemEffect.gains(def, target.hp, target.sp, target.def.max_hp, target.def.max_sp)
	if bool(gain["revive"]):
		target.phase = UnitState.Phase.WAIT
		target.pos = Timeline.AFTER_ACT_POS
		events.append(TimelineEvent.new(&"revived", target.unit_id, 0))
	target.hp += int(gain["hp"])
	target.sp += int(gain["sp"])
	if int(gain["hp"]) > 0:
		events.append(TimelineEvent.new(&"healed", target.unit_id, int(gain["hp"]), def.id))
	if int(gain["sp"]) > 0:
		events.append(TimelineEvent.new(&"sp_restored", target.unit_id, int(gain["sp"]), def.id))
