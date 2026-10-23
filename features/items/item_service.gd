class_name ItemService
extends RefCounted
## Uses a consumable on the party outside battle against GameState: FieldUse does the rules on copies, this writes
## the bag and the carried vitals back only when the use worked. Also lists what the Items screen shows.


## {hero id: Vector2i(max hp, max sp)} for the party.
static func maxes() -> Dictionary:
	var out: Dictionary = {}
	for hero: StringName in GameState.party:
		var def := ContentDB.get_def("combatant", hero) as CombatantDef
		if def != null:
			out[hero] = Vector2i(def.max_hp, def.max_sp)
	return out


## The consumables the bag holds, in content order.
static func owned() -> Array[ConsumableDef]:
	var out: Array[ConsumableDef] = []
	for item_id: StringName in ContentDB.ids("consumable"):
		if GameState.bag.get(item_id, 0) > 0:
			out.append(ContentDB.get_def("consumable", item_id) as ConsumableDef)
	return out


## The ids of owned(), in content order.
static func owned_ids() -> Array[StringName]:
	var out: Array[StringName] = []
	for def: ConsumableDef in owned():
		out.append(def.id)
	return out


## Who an item reaches: the whole party for all_allies, else just `hero`.
static func targets_for(def: ConsumableDef, hero: StringName) -> Array[StringName]:
	if def.target == &"all_allies":
		var party: Array[StringName] = []
		party.assign(GameState.party)
		return party
	return [hero] as Array[StringName]


## Uses one `item_id` (on `hero`, or the party for all_allies). The FieldUse result dictionary.
static func use(item_id: StringName, hero: StringName) -> Dictionary:
	var def := ContentDB.get_def("consumable", item_id) as ConsumableDef
	if def == null:
		return {"ok": false, "reason": FieldUse.NONE_LEFT, "gains": {}}
	var held: Holdings = GameState.holdings()
	var vitals: Dictionary = Vitals.copy(GameState.vitals)
	var result: Dictionary = FieldUse.use(def, held, vitals, targets_for(def, hero), maxes())
	if result["ok"]:
		GameState.take(held)
		GameState.set_vitals(vitals)
	return result


## Adds amount of item_id to GameState.bag respecting max_stack. Emits EventBus.item_obtained.
static func add_to_bag(item_id: StringName, amount: int = 1) -> int:
	var def := ContentDB.get_def("consumable", item_id) as ConsumableDef
	if def == null or amount <= 0:
		return 0
	var held: Holdings = GameState.holdings()
	var leftover: int = held.bag.add(item_id, amount, def.max_stack)
	GameState.take(held)
	EventBus.item_obtained.emit(item_id)
	return amount - leftover

